LOCAL_PATH := $(call my-dir)

# Build Station: M6 camera bring-up LD_PRELOAD shims.
#
# Two narrow shims are preloaded into the camera HAL host processes
# (mediaserver and the camera provider service) so the stock MTK MT6750
# camera blobs run on the LineageOS 15.1 platform:
#
#   libm6_camera_glconsumer_compat.so
#     Bridges the old no-argument android::GLConsumer::getCurrentBuffer()
#     symbol the stock blobs expect. Built from source (needs libgui/libui).
#     Ported verbatim from the working cm-14.1 tree.
#
#   libm6_camera_tsf_bypass.so
#     Stubs TsfCore::TsfCoreProcess() / Shading_TSF_int_gain() / isEnableTSF()
#     in libcamalgo.so, which NULL-deref because this port has no TSF/LSC
#     calibration NVRAM. Shipped as a prebuilt aarch64 .so (no NEEDED deps);
#     source kept alongside as libm6_camera_tsf_bypass.cpp for reference.
#     sha256(libm6_camera_tsf_bypass.so) =
#       aa7647695c9999565422b39675d9488ee4be22f551573d878a76ef4eeaf9adb4
#
# The colon-joined LD_PRELOAD that wires both shims is patched directly into
# the two init rc sources that get packaged into the image:
#   - frameworks/av/media/mediaserver/mediaserver.rc
#   - hardware/interfaces/camera/provider/2.4/default/
#         android.hardware.camera.provider@2.4-service.rc
# (Editing those sources in place avoids the soong init_rc vs. make ETC
# install-path collision on this Oreo tree; both rc's are installed via
# LOCAL_INIT_RC, so a competing BUILD_PREBUILT ETC to the same path would
# double-define the install rule.)
#
# Both shims install to /system/vendor/lib64 (== /vendor/lib64 on this
# non-Treble device) and inherit the default u:object_r:system_file:s0 label
# (no /vendor/lib64/*.so rule exists in the device file_contexts).

include $(CLEAR_VARS)
LOCAL_MODULE := libm6_camera_glconsumer_compat
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MULTILIB := 64
LOCAL_PROPRIETARY_MODULE := true
LOCAL_SRC_FILES := libm6_camera_glconsumer_compat.cpp
LOCAL_SHARED_LIBRARIES := libgui libui libutils liblog
LOCAL_ALLOW_UNDEFINED_SYMBOLS := true
LOCAL_C_INCLUDES := \
    frameworks/native/include \
    system/core/include
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libm6_camera_tsf_bypass
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := 64
LOCAL_PROPRIETARY_MODULE := true
LOCAL_SRC_FILES_64 := libm6_camera_tsf_bypass.so
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := m6_nvram_camera_seed
LOCAL_MODULE_TAGS := optional
LOCAL_PROPRIETARY_MODULE := true
LOCAL_SRC_FILES := nvram_camera_seed.c
LOCAL_CFLAGS := -std=gnu99 -Wall -Wextra
LOCAL_SHARED_LIBRARIES := libdl
include $(BUILD_EXECUTABLE)
