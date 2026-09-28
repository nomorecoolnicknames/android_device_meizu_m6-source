#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define CAM_CAL_MAGIC 'i'

typedef struct {
    uint32_t u4Offset;
    uint32_t u4Length;
    uint32_t sensorID;
    uint32_t deviceID;
    uint8_t *pu1Params;
} stCAM_CAL_INFO_STRUCT;

#define CAM_CALIOC_G_READ _IOWR(CAM_CAL_MAGIC, 5, stCAM_CAL_INFO_STRUCT)

static void dump_hex(uint32_t offset, const uint8_t *buf, uint32_t len) {
    for (uint32_t i = 0; i < len; i += 16) {
        printf("%04x:", offset + i);
        uint32_t row = len - i;
        if (row > 16) {
            row = 16;
        }
        for (uint32_t j = 0; j < row; ++j) {
            printf(" %02x", buf[i + j]);
        }
        printf("\n");
    }
}

int main(int argc, char **argv) {
    const char *node = argc > 1 ? argv[1] : "/dev/CAM_CAL_DRV";
    uint32_t sensor = argc > 2 ? (uint32_t)strtoul(argv[2], NULL, 0) : 0x279;
    uint32_t device = argc > 3 ? (uint32_t)strtoul(argv[3], NULL, 0) : 1;
    uint32_t offset = argc > 4 ? (uint32_t)strtoul(argv[4], NULL, 0) : 0;
    uint32_t length = argc > 5 ? (uint32_t)strtoul(argv[5], NULL, 0) : 64;

    if (length == 0 || length > 4096) {
        fprintf(stderr, "bad length %u\n", length);
        return 2;
    }

    uint8_t *buf = calloc(1, length);
    if (buf == NULL) {
        perror("calloc");
        return 2;
    }

    int fd = open(node, O_RDWR);
    if (fd < 0) {
        perror("open");
        free(buf);
        return 1;
    }

    stCAM_CAL_INFO_STRUCT info;
    memset(&info, 0, sizeof(info));
    info.u4Offset = offset;
    info.u4Length = length;
    info.sensorID = sensor;
    info.deviceID = device;
    info.pu1Params = buf;

    errno = 0;
    int ret = ioctl(fd, CAM_CALIOC_G_READ, &info);
    int saved_errno = errno;
    printf("node=%s sensor=0x%x device=%u offset=0x%x length=%u ioctl_ret=%d errno=%d:%s\n",
           node, sensor, device, offset, length, ret, saved_errno, strerror(saved_errno));
    dump_hex(offset, buf, length);

    close(fd);
    free(buf);
    return ret < 0 ? 1 : 0;
}
