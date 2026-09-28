LOCAL_PATH:= $(call my-dir)

ifneq ($(filter meizu_m6, $(TARGET_DEVICE)),)

include $(call first-makefiles-under,$(LOCAL_PATH))
include vendor/mediatek/ril/Android.mk

endif
