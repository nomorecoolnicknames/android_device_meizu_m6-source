# Device-local blob shims for the Meizu M6 (meizu_m6). See shims/skia.cpp for
# the measured evidence. Pattern copied from device/meizu/m95/shims/Android.mk
# (same problem, same resolution — read its header for why the module cannot
# simply be named `libskia`: the name is ambiguous with Soong's static module
# and `mka libskia` starts compiling all of external/skia).
#
# Kept device-local and deliberately NOT added to vendor/mediatek/symbols:
# that module is shared with the m681 / m95 / M6T ports, and a libskia.so
# would silently apply to them too.
#
# The link targets are spelled out per arch rather than derived from $@ —
# inside PRIVATE_POST_INSTALL_CMD $@ does not expand to the installed module
# the way it reads (m95 hit a bogus 'pluginlibskia.so' path that way).

LOCAL_PATH := $(call my-dir)

# libskia.so — DT_NEEDED satisfier, exports nothing.
include $(CLEAR_VARS)
LOCAL_MODULE := libskia_m6_stub
LOCAL_SRC_FILES := skia.cpp
LOCAL_POST_INSTALL_CMD := mkdir -p $(TARGET_OUT_VENDOR)/lib $(TARGET_OUT_VENDOR)/lib64 \
    && ln -sf libskia_m6_stub.so $(TARGET_OUT_VENDOR)/lib/libskia.so \
    && ln -sf libskia_m6_stub.so $(TARGET_OUT_VENDOR)/lib64/libskia.so
LOCAL_MULTILIB := both
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)
