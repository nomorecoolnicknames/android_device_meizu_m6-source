/*
 * mbackd — Meizu M6 mBack button daemon (LineageOS 16.0).
 *
 * The single capacitive button is mtk-kpd (/dev/input/event1) and emits a
 * plain KEY_HOME (102) down/up with no duration encoding (kpd.c). Native
 * Android can only do press=Home / long-press=policy on that; the stock
 * Flyme tap=Back behaviour needs userspace duration splitting:
 *
 *   tap   (release <= tap_ms,  default 250)  -> KEY_BACK (158)
 *   click (release  > tap_ms)                -> KEY_HOMEPAGE (172 -> HOME)
 *   hold  (down    >= hold_ms, default 500)  -> KEY_APPSELECT (580 -> APP_SWITCH),
 *                                               fired at the threshold, release swallowed
 *
 * The daemon EVIOCGRABs the source device so the raw KEY_HOME never reaches
 * Android, and injects mapped keys through a uinput device "mbackd-keys"
 * (bus VIRTUAL, vendor 0x4642 product 0x0001 -> Vendor_4642_Product_0001.kl).
 * Every other key on the grabbed device (volume, power, vendor codes) is
 * forwarded unchanged so nothing is lost while the grab is held.
 *
 * Tunables (re-read on every button press, no restart needed):
 *   persist.sys.mback.tap_ms   (50..2000, default 250)
 *   persist.sys.mback.hold_ms  (50..5000, default 500)
 *
 * Failure mode: if mbackd is not running, the button falls back to the
 * native mapping (vendor Generic.kl key 102 -> HOME, overlay long-press ->
 * APP_SWITCH), so the device is never left without a working button.
 */

#define LOG_TAG "mbackd"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/uinput.h>

#include <cutils/properties.h>
#include <log/log.h>

#ifndef KEY_APPSELECT
#define KEY_APPSELECT 0x244 /* 580 */
#endif
#ifndef KEY_HOMEPAGE
#define KEY_HOMEPAGE 172
#endif

#define SRC_DEV_DEFAULT "/dev/input/event1"
#define KEY_MBACK KEY_HOME /* 102, the physical capacitive button */

static int g_verbose = 0;
static int g_nograb = 0; /* -n: observe/classify only, no grab, no injection */

static int tap_ms = 250;
static int hold_ms = 500;

static void logi(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    __android_log_vprint(ANDROID_LOG_INFO, LOG_TAG, fmt, ap);
    va_end(ap);
    if (g_verbose) {
        va_start(ap, fmt);
        vfprintf(stdout, fmt, ap);
        fputc('\n', stdout);
        fflush(stdout);
        va_end(ap);
    }
}

static void load_props(void)
{
    char v[PROP_VALUE_MAX];
    int n;

    if (property_get("persist.sys.mback.tap_ms", v, "250") > 0) {
        n = atoi(v);
        if (n >= 50 && n <= 2000)
            tap_ms = n;
    }
    if (property_get("persist.sys.mback.hold_ms", v, "500") > 0) {
        n = atoi(v);
        if (n >= 50 && n <= 5000)
            hold_ms = n;
    }
    if (hold_ms <= tap_ms)
        hold_ms = tap_ms + 100;
}

static long elapsed_ms(const struct timespec *t0)
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (now.tv_sec - t0->tv_sec) * 1000L +
           (now.tv_nsec - t0->tv_nsec) / 1000000L;
}

static void emit(int ufd, uint16_t type, uint16_t code, int32_t value)
{
    struct input_event ev;

    if (ufd < 0)
        return;
    memset(&ev, 0, sizeof(ev));
    ev.type = type;
    ev.code = code;
    ev.value = value;
    if (write(ufd, &ev, sizeof(ev)) != (ssize_t)sizeof(ev))
        ALOGE("uinput write failed: %s", strerror(errno));
}

static void inject_tap(int ufd, uint16_t code)
{
    emit(ufd, EV_KEY, code, 1);
    emit(ufd, EV_SYN, SYN_REPORT, 0);
    emit(ufd, EV_KEY, code, 0);
    emit(ufd, EV_SYN, SYN_REPORT, 0);
}

static int uinput_create(void)
{
    static const int codes[] = {
        KEY_BACK, KEY_HOMEPAGE, KEY_APPSELECT, KEY_HOME,
        KEY_VOLUMEUP, KEY_VOLUMEDOWN, KEY_POWER,
        129, 193, 408 /* vendor codes mtk-kpd declares */
    };
    struct uinput_user_dev ud;
    size_t i;
    int fd;

    fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        ALOGE("open /dev/uinput: %s", strerror(errno));
        return -1;
    }
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    for (i = 0; i < sizeof(codes) / sizeof(codes[0]); i++)
        ioctl(fd, UI_SET_KEYBIT, codes[i]);

    memset(&ud, 0, sizeof(ud));
    snprintf(ud.name, UINPUT_MAX_NAME_SIZE, "mbackd-keys");
    ud.id.bustype = BUS_VIRTUAL;
    ud.id.vendor = 0x4642;
    ud.id.product = 0x0001;
    ud.id.version = 1;
    if (write(fd, &ud, sizeof(ud)) != (ssize_t)sizeof(ud)) {
        ALOGE("uinput_user_dev write: %s", strerror(errno));
        close(fd);
        return -1;
    }
    if (ioctl(fd, UI_DEV_CREATE) < 0) {
        ALOGE("UI_DEV_CREATE: %s", strerror(errno));
        close(fd);
        return -1;
    }
    return fd;
}

int main(int argc, char **argv)
{
    const char *src = SRC_DEV_DEFAULT;
    struct timespec t0 = { 0, 0 };
    int down = 0, hold_fired = 0;
    int sfd = -1, ufd = -1;
    struct pollfd pfd;
    int i, tries;

    for (i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-v"))
            g_verbose = 1;
        else if (!strcmp(argv[i], "-n"))
            g_nograb = 1;
        else
            src = argv[i];
    }

    load_props();
    logi("start src=%s tap_ms=%d hold_ms=%d%s", src, tap_ms, hold_ms,
         g_nograb ? " (observe mode: no grab, no inject)" : "");

    /* the input node can appear after us on early boots */
    for (tries = 0; tries < 30 && sfd < 0; tries++) {
        sfd = open(src, O_RDONLY);
        if (sfd < 0)
            sleep(1);
    }
    if (sfd < 0) {
        ALOGE("open %s: %s", src, strerror(errno));
        return 1;
    }

    if (!g_nograb) {
        for (tries = 0; tries < 5; tries++) {
            if (ioctl(sfd, EVIOCGRAB, 1) == 0)
                break;
            ALOGE("EVIOCGRAB %s: %s (try %d)", src, strerror(errno), tries);
            sleep(1);
        }
        if (tries == 5) {
            ALOGE("could not grab %s, exiting", src);
            return 1;
        }
        ufd = uinput_create();
        if (ufd < 0) {
            ioctl(sfd, EVIOCGRAB, 0);
            return 1;
        }
    }

    pfd.fd = sfd;
    pfd.events = POLLIN;

    for (;;) {
        struct input_event ev;
        int timeout = -1;
        ssize_t r;
        int n;

        if (down && !hold_fired) {
            long e = elapsed_ms(&t0);
            timeout = hold_ms - (int)e;
            if (timeout < 0)
                timeout = 0;
        }

        n = poll(&pfd, 1, timeout);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            ALOGE("poll: %s", strerror(errno));
            break;
        }
        if (n == 0) {
            /* hold threshold crossed while the button is still down */
            if (down && !hold_fired) {
                hold_fired = 1;
                inject_tap(ufd, KEY_APPSELECT);
                logi("hold >= %dms -> APP_SWITCH", hold_ms);
            }
            continue;
        }

        r = read(sfd, &ev, sizeof(ev));
        if (r != (ssize_t)sizeof(ev)) {
            if (r < 0 && (errno == EAGAIN || errno == EINTR))
                continue;
            ALOGE("read %s: %s", src, r < 0 ? strerror(errno) : "short");
            break;
        }

        if (ev.type == EV_KEY && ev.code == KEY_MBACK) {
            if (ev.value == 1) {
                down = 1;
                hold_fired = 0;
                clock_gettime(CLOCK_MONOTONIC, &t0);
                load_props();
            } else if (ev.value == 0 && down) {
                long dt = elapsed_ms(&t0);
                down = 0;
                if (hold_fired) {
                    /* APP_SWITCH already sent at the threshold */
                } else if (dt <= tap_ms) {
                    inject_tap(ufd, KEY_BACK);
                    logi("tap %ldms -> BACK", dt);
                } else {
                    inject_tap(ufd, KEY_HOMEPAGE);
                    logi("click %ldms -> HOME", dt);
                }
            }
            /* value==2 autorepeat swallowed */
        } else if (ev.type == EV_KEY) {
            /* pass every non-mBack key through unchanged */
            emit(ufd, EV_KEY, ev.code, ev.value);
            emit(ufd, EV_SYN, SYN_REPORT, 0);
            if (g_verbose)
                logi("fwd code=%u value=%d", ev.code, ev.value);
        }
        /* EV_SYN / EV_MSC from the source are dropped; we emit our own SYNs */
    }

    if (ufd >= 0) {
        ioctl(ufd, UI_DEV_DESTROY);
        close(ufd);
    }
    if (!g_nograb)
        ioctl(sfd, EVIOCGRAB, 0);
    close(sfd);
    return 0;
}
