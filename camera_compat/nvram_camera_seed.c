#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

typedef struct {
    int iFileDesc;
    int ifile_lid;
    bool bIsRead;
} F_ID;

typedef int (*NvmInitFn)(void);
typedef int (*NvmGetLidByNameFn)(char *filename);
typedef bool (*NvmResetFileToDefaultFn)(int file_lid);
typedef F_ID (*NvmGetFileDescFn)(int file_lid, int *pRecSize, int *pRecNum, bool isRead);
typedef bool (*NvmCloseFileDescFn)(F_ID file_id);

static const char *kCameraNvramNames[] = {
    "CAMERA_VERSION",
    "CAMERA_Para",
    "CAMERA_3A",
    "CAMERA_SHADING",
    "CAMERA_DEFECT",
    "CAMERA_SENSOR",
    "CAMERA_LENS",
    "CAMERA_FEATURE",
    "CAMERA_GEOMETRY",
    "CAMERA_SHADING2",
    "CAMERA_SHADING3",
    "CAMERA_SHADING4",
    "CAMERA_SHADING5",
    "CAMERA_SHADING6",
    "CAMERA_SHADING7",
    "CAMERA_SHADING8",
    "CAMERA_SHADING9",
    "CAMERA_SHADING10",
    "CAMERA_SHADING11",
    "CAMERA_SHADING12",
    "CAMERA_PLINE",
    "CAMERA_PLINE2",
    "CAMERA_PLINE3",
    "CAMERA_PLINE4",
    "CAMERA_PLINE5",
    "CAMERA_PLINE6",
    "CAMERA_PLINE7",
    "CAMERA_PLINE8",
    "CAMERA_PLINE9",
    "CAMERA_PLINE10",
    "CAMERA_PLINE11",
    "CAMERA_PLINE12",
};

static void print_usage(const char *argv0) {
    fprintf(stderr,
            "usage: %s [--ids|--open-read|--reset-missing|--reset-all]\n"
            "  --ids            resolve NVRAM LIDs only, no file opens\n"
            "  --open-read      open each camera NVRAM file read-only via libnvram (default)\n"
            "  --reset-missing  reset only missing/empty camera files before read-open\n"
            "  --reset-all      reset every camera file before read-open\n",
            argv0);
}

static void *load_libnvram(void) {
    const char *paths[] = {
        "/vendor/lib64/libnvram.so",
        "/system/vendor/lib64/libnvram.so",
        "libnvram.so",
    };

    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
        void *handle = dlopen(paths[i], RTLD_NOW);
        if (handle != NULL) {
            printf("libnvram=%s\n", paths[i]);
            return handle;
        }
        printf("dlopen_fail path=%s error=%s\n", paths[i], dlerror());
    }
    return NULL;
}

static bool path_stat(const char *name, off_t *size_out) {
    char path[128];
    snprintf(path, sizeof(path), "/data/nvram/media/%s", name);
    struct stat st;
    if (stat(path, &st) != 0) {
        *size_out = -1;
        return false;
    }
    *size_out = st.st_size;
    return true;
}

static int count_nonzero(const uint8_t *buf, ssize_t len) {
    int nonzero = 0;
    for (ssize_t i = 0; i < len; ++i) {
        if (buf[i] != 0) {
            ++nonzero;
        }
    }
    return nonzero;
}

static void print_sample(int fd) {
    uint8_t buf[64];
    memset(buf, 0, sizeof(buf));
    errno = 0;
    ssize_t n = pread(fd, buf, sizeof(buf), 0);
    int saved_errno = errno;
    printf(" sample_read=%zd errno=%d nonzero=%d first16=", n, saved_errno,
           n > 0 ? count_nonzero(buf, n) : 0);
    ssize_t shown = n > 16 ? 16 : n;
    for (ssize_t i = 0; i < shown; ++i) {
        printf("%02x", buf[i]);
    }
    if (shown <= 0) {
        printf("-");
    }
    printf("\n");
}

int main(int argc, char **argv) {
    enum {
        MODE_OPEN_READ,
        MODE_IDS,
        MODE_RESET_MISSING,
        MODE_RESET_ALL,
    } mode = MODE_OPEN_READ;

    if (argc > 2) {
        print_usage(argv[0]);
        return 2;
    }
    if (argc == 2) {
        if (strcmp(argv[1], "--ids") == 0) {
            mode = MODE_IDS;
        } else if (strcmp(argv[1], "--open-read") == 0) {
            mode = MODE_OPEN_READ;
        } else if (strcmp(argv[1], "--reset-missing") == 0) {
            mode = MODE_RESET_MISSING;
        } else if (strcmp(argv[1], "--reset-all") == 0) {
            mode = MODE_RESET_ALL;
        } else {
            print_usage(argv[0]);
            return 2;
        }
    }

    void *lib = load_libnvram();
    if (lib == NULL) {
        fprintf(stderr, "cannot load libnvram\n");
        return 1;
    }

    NvmInitFn nvm_init = (NvmInitFn)dlsym(lib, "NVM_Init");
    NvmGetLidByNameFn nvm_get_lid = (NvmGetLidByNameFn)dlsym(lib, "NVM_GetLIDByName");
    NvmResetFileToDefaultFn nvm_reset =
            (NvmResetFileToDefaultFn)dlsym(lib, "NVM_ResetFileToDefault");
    NvmGetFileDescFn nvm_get_file =
            (NvmGetFileDescFn)dlsym(lib, "NVM_GetFileDesc");
    NvmCloseFileDescFn nvm_close =
            (NvmCloseFileDescFn)dlsym(lib, "NVM_CloseFileDesc");

    if (nvm_init == NULL || nvm_get_lid == NULL || nvm_reset == NULL ||
            nvm_get_file == NULL || nvm_close == NULL) {
        fprintf(stderr, "missing libnvram symbols: init=%p lid=%p reset=%p get=%p close=%p\n",
                nvm_init, nvm_get_lid, nvm_reset, nvm_get_file, nvm_close);
        return 1;
    }

    int max_lid = nvm_init();
    printf("NVM_Init max_lid=%d mode=%d\n", max_lid, mode);

    int failures = 0;
    for (size_t i = 0; i < sizeof(kCameraNvramNames) / sizeof(kCameraNvramNames[0]); ++i) {
        const char *name = kCameraNvramNames[i];
        char mutable_name[64];
        snprintf(mutable_name, sizeof(mutable_name), "%s", name);

        off_t before_size = -1;
        bool before_exists = path_stat(name, &before_size);
        int lid = nvm_get_lid(mutable_name);
        printf("name=%s lid=%d before_exists=%d before_size=%lld\n",
               name, lid, before_exists ? 1 : 0, (long long)before_size);
        if (lid < 0) {
            ++failures;
            continue;
        }
        if (mode == MODE_IDS) {
            continue;
        }

        bool should_reset = mode == MODE_RESET_ALL ||
                (mode == MODE_RESET_MISSING && (!before_exists || before_size <= 0));
        if (should_reset) {
            bool reset_ok = nvm_reset(lid);
            printf(" reset=%d\n", reset_ok ? 1 : 0);
            if (!reset_ok) {
                ++failures;
            }
        }

        int rec_size = -1;
        int rec_num = -1;
        F_ID file_id = nvm_get_file(lid, &rec_size, &rec_num, true);
        off_t after_size = -1;
        bool after_exists = path_stat(name, &after_size);
        printf(" open fd=%d lid_return=%d is_read=%d rec_size=%d rec_num=%d "
               "after_exists=%d after_size=%lld\n",
               file_id.iFileDesc, file_id.ifile_lid, file_id.bIsRead ? 1 : 0,
               rec_size, rec_num, after_exists ? 1 : 0, (long long)after_size);
        if (file_id.iFileDesc >= 0) {
            print_sample(file_id.iFileDesc);
            bool close_ok = nvm_close(file_id);
            printf(" close=%d\n", close_ok ? 1 : 0);
        } else {
            ++failures;
        }
    }

    return failures == 0 ? 0 : 1;
}
