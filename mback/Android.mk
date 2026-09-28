LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := mbackd
LOCAL_SRC_FILES := mbackd.c
LOCAL_CFLAGS := -Wall
LOCAL_SHARED_LIBRARIES := liblog libcutils
LOCAL_INIT_RC := mbackd.rc
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
