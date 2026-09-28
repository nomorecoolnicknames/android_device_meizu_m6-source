#include <algorithm>
#include <cinttypes>
#include <cstdio>
#include <cstring>
#include <dlfcn.h>
#include <errno.h>
#include <stdint.h>

#include <android/native_window.h>
#include <cutils/properties.h>
#include <log/log.h>
#include <ui/GraphicBuffer.h>
#include <utils/StrongPointer.h>

namespace android {

class GLConsumer {
public:
    sp<GraphicBuffer> getCurrentBuffer() const;
    sp<GraphicBuffer> getCurrentBuffer(int* outSlot) const;
};

sp<GraphicBuffer> GLConsumer::getCurrentBuffer() const {
    int slot = -1;
    return getCurrentBuffer(&slot);
}

static bool m6CameraSurfaceDiagnosticsEnabled() {
    char device[PROPERTY_VALUE_MAX] = {};
    if (property_get("ro.product.device", device, "") <= 0 ||
            std::strcmp(device, "meizu_m6") != 0) {
        return false;
    }

    char cmdline[64] = {};
    FILE* fp = fopen("/proc/self/cmdline", "re");
    if (fp == nullptr) {
        return false;
    }
    size_t n = fread(cmdline, 1, sizeof(cmdline) - 1, fp);
    fclose(fp);
    if (n == 0) {
        return false;
    }

    return std::strstr(cmdline, "mediaserver") != nullptr;
}

}  // namespace android

__attribute__((constructor)) static void m6_camera_glconsumer_compat_loaded() {
    __android_log_print(ANDROID_LOG_INFO, "M6CameraCompat",
                        "loaded GLConsumer getCurrentBuffer() compat shim with CAM_CAL isolation");
}

static bool m6CameraCompatDevice() {
    char device[PROPERTY_VALUE_MAX] = {};
    return property_get("ro.product.device", device, "") > 0 &&
            std::strcmp(device, "meizu_m6") == 0;
}

static const char* m6CamCalNodeForSensor(unsigned int sensorId) {
    switch (sensorId) {
        case 0x278:
        case 0x279:
            return "/dev/CAM_CAL_DRV";
        case 0x2108:
        case 0x885a:
        case 0x885b:
            return "/dev/CAM_CAL_DRV1";
        case 0x8858:
            return "/dev/CAM_CAL_DRV2";
        default:
            return "/dev/CAM_CAL_DRV";
    }
}

static void* m6FindCameraCustomSymbol(const char* symbol) {
    void* value = dlsym(RTLD_NEXT, symbol);
    if (value != nullptr) {
        return value;
    }

    const char* paths[] = {
        "libcameracustom.so",
        "/vendor/lib64/libcameracustom.so",
        "/system/vendor/lib64/libcameracustom.so",
    };
    for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); ++i) {
        void* handle = dlopen(paths[i], RTLD_NOW | RTLD_NOLOAD);
        if (handle == nullptr) {
            continue;
        }
        value = dlsym(handle, symbol);
        if (value != nullptr) {
            return value;
        }
    }

    return nullptr;
}

static void m6ResetCamCalLayoutCache(const char* reason, uint32_t sensorId) {
    if (!m6CameraCompatDevice()) {
        return;
    }

    static uint8_t* gIsInited = reinterpret_cast<uint8_t*>(
            m6FindCameraCustomSymbol("gIsInited"));
    if (gIsInited == nullptr) {
        static uint32_t missLogCount = 0;
        if (missLogCount++ < 4) {
            __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                    "DIAGNOSTIC CAM_CAL layout cache symbol missing reason=%s sensor=0x%x",
                    reason, sensorId);
        }
        return;
    }

    uint32_t* cachedSensor = reinterpret_cast<uint32_t*>(gIsInited - sizeof(uint32_t));
    uint32_t oldSensor = *cachedSensor;
    uint8_t oldInited = *gIsInited;
    if (oldSensor == sensorId || oldInited != 0) {
        *cachedSensor = 0xffffffffu;
        *gIsInited = 0;
        static uint32_t resetLogCount = 0;
        if (resetLogCount++ < 24) {
            __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                    "ISOLATION CAM_CAL layout cache reset reason=%s sensor=0x%x oldSensor=0x%x oldInited=%u",
                    reason, sensorId, oldSensor, oldInited);
        }
    }
}

static void m6LogCamCalRequest(const char* name, const uint32_t* data, int ret) {
    if (!m6CameraCompatDevice() || data == nullptr) {
        return;
    }

    static uint32_t logCount = 0;
    if (logCount++ < 48) {
        __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                "DIAGNOSTIC %s ret=0x%x cmd=0x%x sub=0x%x sensor=0x%x device=0x%x data4=0x%x data5=0x%x",
                name, ret, data[0], data[1], data[8], data[9], data[4], data[5]);
    }
}

static bool m6CamCalForceSuccessEnabled() {
    if (!m6CameraCompatDevice()) {
        return false;
    }

    char value[PROPERTY_VALUE_MAX] = {};
    return property_get("persist.forge.m6.camcal.force_success", value, "0") > 0 &&
            std::strcmp(value, "1") == 0;
}

extern "C" int CAM_CALInit() {
    typedef int (*CamCalInitFn)();
    static CamCalInitFn realCamCalInit = reinterpret_cast<CamCalInitFn>(
            dlsym(RTLD_NEXT, "CAM_CALInit"));
    int realResult = realCamCalInit != nullptr ? realCamCalInit() : 1;
    if (!m6CameraCompatDevice()) {
        return realResult;
    }

    static uint32_t logCount = 0;
    if (logCount++ < 8) {
        __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                "DIAGNOSTIC CAM_CALInit passthrough real=%d -> %d",
                realResult, realResult != 0 ? realResult : 1);
    }
    return realResult != 0 ? realResult : 1;
}

extern "C" int CAM_CALDeviceName(char* devName, unsigned int sensorId) {
    typedef int (*CamCalDeviceNameFn)(char*, unsigned int);
    static CamCalDeviceNameFn realCamCalDeviceName = reinterpret_cast<CamCalDeviceNameFn>(
            dlsym(RTLD_NEXT, "CAM_CALDeviceName"));

    if (devName == nullptr) {
        return realCamCalDeviceName != nullptr ? realCamCalDeviceName(devName, sensorId) : -1;
    }

    int realResult = -1;
    if (realCamCalDeviceName != nullptr) {
        realResult = realCamCalDeviceName(devName, sensorId);
    }

    if (m6CameraCompatDevice() &&
            (devName[0] == '\0' || std::strcmp(devName, "/dev/") == 0)) {
        std::snprintf(devName, 64, "%s", m6CamCalNodeForSensor(sensorId));
        static uint32_t logCount = 0;
        if (logCount++ < 16) {
            __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                    "ISOLATION CAM_CALDeviceName override sensorId=0x%x real=%d -> %s",
                    sensorId, realResult, devName);
        }
        return 0;
    } else if (m6CameraCompatDevice()) {
        static uint32_t logCount = 0;
        if (logCount++ < 16) {
            __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                    "DIAGNOSTIC CAM_CALDeviceName sensorId=0x%x real=%d name=%s",
                    sensorId, realResult, devName);
        }
    }

    return realResult == 0 ? 0 : realResult;
}

extern "C" int _Z19DoCamCalLayoutCheckPj(uint32_t* data) {
    typedef int (*DoCamCalLayoutCheckFn)(uint32_t*);
    static DoCamCalLayoutCheckFn realDoCamCalLayoutCheck =
            reinterpret_cast<DoCamCalLayoutCheckFn>(
                    dlsym(RTLD_NEXT, "_Z19DoCamCalLayoutCheckPj"));
    if (data != nullptr) {
        m6ResetCamCalLayoutCache("DoCamCalLayoutCheck", data[8]);
    }
    int ret = realDoCamCalLayoutCheck != nullptr ? realDoCamCalLayoutCheck(data) : 0x8fffffff;
    m6LogCamCalRequest("DoCamCalLayoutCheck", data, ret);
    return ret;
}

extern "C" int _Z17CAM_CALGetCalDataPj(uint32_t* data) {
    typedef int (*CamCalGetCalDataFn)(uint32_t*);
    static CamCalGetCalDataFn realCamCalGetCalData =
            reinterpret_cast<CamCalGetCalDataFn>(
                    dlsym(RTLD_NEXT, "_Z17CAM_CALGetCalDataPj"));
    if (data != nullptr) {
        m6ResetCamCalLayoutCache("CAM_CALGetCalData", data[8]);
    }
    int ret = realCamCalGetCalData != nullptr ? realCamCalGetCalData(data) : 0x8fffffff;
    m6LogCamCalRequest("CAM_CALGetCalData", data, ret);
    if (ret != 0 && data != nullptr && m6CamCalForceSuccessEnabled()) {
        static uint32_t forceLogCount = 0;
        if (forceLogCount++ < 24) {
            __android_log_print(ANDROID_LOG_WARN, "M6CameraCompat",
                    "ISOLATION CAM_CALGetCalData force success ret=0x%x cmd=0x%x sensor=0x%x device=0x%x",
                    ret, data[0], data[8], data[9]);
        }
        return 0;
    }
    return ret;
}
