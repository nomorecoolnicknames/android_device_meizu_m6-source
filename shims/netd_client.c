/* libnetd_client.so (vendor, lib + lib64) for the MediaTek Nougat RIL of this set.
 *
 * FACT (treble-m6-m6t wiring model, 2026-09-25, with librilutils/libril of the
 * image provided): mtk-ril.so and mtk-rilmd2.so (lib and lib64) close their
 * vendor-namespace closure except for one library and one symbol -
 * libnetd_client.so / protectFromVpn. libnetd_client is system-only
 * (system/netd/client/Android.bp: no vendor_available), and a Treble vendor
 * process cannot reach /system/lib*, so rild cannot dlopen mtk-ril.so at all.
 * The other importers in this set (volte_stack, wfca, libcharon...) want
 * setNetworkForSocket / protectFromVpn too; IMS is not ported, but the same
 * file serves them.
 *
 * protectFromVpn is NOT a stub: it is the same fwmarkd round trip the system
 * copy does (system/netd/client/NetdClient.cpp:490-494 and
 * FwmarkClient.cpp:71-122) - a FwmarkCommand{PROTECT_FROM_VPN} over the
 * /dev/socket/fwmarkd stream socket with the socket fd as SCM_RIGHTS, and the
 * int status netd sends back. netd decides (FwmarkServer.cpp:266-269,
 * NetworkController::canProtect); this file adds no policy. Like upstream, if
 * fwmarkd cannot be reached the call reports success (FwmarkClient.cpp:79-83).
 * The command layout is A13's system/netd/include/FwmarkCommand.h; netd is in
 * the same system image, so both sides agree.
 *
 * setNetworkForSocket forwards to the LLNDK android_setsocknetwork(), as m95's
 * shim does (device/meizu/m95 lineage-20-volte3 shims/netd_client.c):
 * android_setsocknetwork is setNetworkForSocket with the netId packed into a
 * net_handle_t (frameworks/base/native/android/net.c:45-65).
 */
#include <android/multinetwork.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define NETID_UNSET 0u /* system/netd/include/netid_client.h:24 */

/* Must match kHandleMagic in frameworks/base/native/android/net.c. */
static const uint32_t kHandleMagic = 0xcafed00d;

/* system/netd/include/FwmarkCommand.h (A13): enum CmdId + three words. */
enum { FWMARK_PROTECT_FROM_VPN = 3 };
struct fwmark_command {
    int cmd_id;
    unsigned net_id;
    uid_t uid;
    uint32_t traffic_ctrl_info;
};

int setNetworkForSocket(unsigned netId, int socketFd) {
    net_handle_t handle = netId == NETID_UNSET
            ? NETWORK_UNSPECIFIED
            : ((net_handle_t)netId << 32) | kHandleMagic;

    if (android_setsocknetwork(handle, socketFd) == 0)
        return 0;
    return -errno;
}

int protectFromVpn(int socketFd) {
    /* NetdClient.cpp checkSocket(): only inet sockets carry a fwmark. */
    int family;
    socklen_t len = sizeof(family);
    if (socketFd < 0)
        return -EBADF;
    if (getsockopt(socketFd, SOL_SOCKET, SO_DOMAIN, &family, &len) == -1)
        return -errno;
    if (family != AF_INET && family != AF_INET6)
        return -EAFNOSUPPORT;

    int ch = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (ch == -1)
        return -errno;
    struct sockaddr_un addr = {.sun_family = AF_UNIX, .sun_path = "/dev/socket/fwmarkd"};
    if (TEMP_FAILURE_RETRY(connect(ch, (const struct sockaddr*)&addr, sizeof(addr))) == -1) {
        close(ch);
        return 0; /* upstream: "assume there's no error" */
    }

    struct fwmark_command cmd = {FWMARK_PROTECT_FROM_VPN, 0, 0, 0};
    struct iovec iov = {&cmd, sizeof(cmd)};
    union {
        struct cmsghdr cmh;
        char buf[CMSG_SPACE(sizeof(int))];
    } cmsgu;
    memset(&cmsgu, 0, sizeof(cmsgu));
    struct msghdr msg = {.msg_iov = &iov, .msg_iovlen = 1,
                         .msg_control = cmsgu.buf, .msg_controllen = sizeof(cmsgu.buf)};
    struct cmsghdr* c = CMSG_FIRSTHDR(&msg);
    c->cmsg_len = CMSG_LEN(sizeof(int));
    c->cmsg_level = SOL_SOCKET;
    c->cmsg_type = SCM_RIGHTS;
    memcpy(CMSG_DATA(c), &socketFd, sizeof(int));

    int ret = 0;
    if (TEMP_FAILURE_RETRY(sendmsg(ch, &msg, 0)) == -1 ||
        TEMP_FAILURE_RETRY(recv(ch, &ret, sizeof(ret), 0)) == -1)
        ret = -errno;
    close(ch);
    return ret;
}
