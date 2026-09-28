# Build Station: LineageOS 16.0 (Pie) product wrapper for Meizu M6 stock-kernel lane.
$(call inherit-product, $(LOCAL_PATH)/device_meizu_m6.mk)

# Build Station: Lineage SDK resources required by services.jar.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Build Station: Lineage OTA install tools from source.
PRODUCT_COPY_FILES += \
    vendor/lineage/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/lineage/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions

PRODUCT_VERSION_MAJOR := 16
PRODUCT_VERSION_MINOR := 0
PRODUCT_VERSION_MAINTENANCE := 0
LINEAGE_BUILDTYPE := UNOFFICIAL
LINEAGE_BUILD := meizu_m6
LINEAGE_VERSION := 16.0-UNOFFICIAL-meizu_m6
LINEAGE_DISPLAY_VERSION := $(LINEAGE_VERSION)
LINEAGE_PLATFORM_SDK_VERSION := 9
LINEAGE_PLATFORM_REV := 0

PRODUCT_NAME := lineage_meizu_m6
PRODUCT_DEVICE := meizu_m6
PRODUCT_BRAND := meizu
PRODUCT_MANUFACTURER := Meizu
PRODUCT_MODEL := meizu_m6
PRODUCT_RELEASE_NAME := meizu_m6
TARGET_OTA_ASSERT_DEVICE := meizu_m6
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=lineage_meizu_m6 \
    PRODUCT_DEVICE=meizu_m6 \
    TARGET_DEVICE=meizu_m6

# Build Station: bootdiag cache capture.
PRODUCT_COPY_FILES += \
    device/meizu/meizu_m6/forge-bootdiag.sh:system/bin/forge-bootdiag.sh

# Build Station: Oreo needs these Lineage userland pieces in this reused base.
PRODUCT_PACKAGES += \
    LineageSettingsProvider \
    Trebuchet

# Build Station: keep AOSP sample/legacy app payload out of Oreo test builds.
PRODUCT_PACKAGES := $(filter-out Home Recorder,$(PRODUCT_PACKAGES))

# Build Station: target device identity override
PRODUCT_NAME := lineage_meizu_m6
PRODUCT_DEVICE := meizu_m6
PRODUCT_BRAND := meizu
PRODUCT_MANUFACTURER := Meizu
PRODUCT_MODEL := meizu_m6
PRODUCT_RELEASE_NAME := meizu_m6
TARGET_OTA_ASSERT_DEVICE := meizu_m6
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=lineage_meizu_m6 \
    PRODUCT_DEVICE=meizu_m6 \
    TARGET_DEVICE=meizu_m6
# Build Station: final M6 hardware HAL cleanup after all product inheritance.
PRODUCT_PACKAGES := $(filter-out \
    audio.primary.default \
    audio.primary.goldfish \
    audio_policy.default \
    audio_policy.goldfish \
    gralloc.default \
    gralloc.goldfish \
    gralloc.ranchu \
    camera.goldfish \
    camera.goldfish.jpeg \
    camera.ranchu \
    camera.ranchu.jpeg \
    fingerprint.goldfish \
    fingerprint.ranchu \
    gps.goldfish \
    gps.ranchu \
    lights.goldfish \
    power.goldfish \
    sensors.goldfish \
    sensors.ranchu \
    vibrator.goldfish, \
    $(PRODUCT_PACKAGES))
PRODUCT_COPY_FILES := $(filter-out \
    device/generic/goldfish/% \
    device/generic/mini-emulator-% \
    device/google/atv/init.goldfish.rc:% \
    %:root/fstab.goldfish \
    %:root/fstab.ranchu \
    %:root/init.goldfish.rc \
    %:root/init.ranchu.rc \
    %:root/ueventd.goldfish.rc \
    %:root/ueventd.ranchu.rc \
    %:system/etc/init.goldfish.sh \
    %:system/usr/idc/goldfish_rotary.idc \
    %:system/etc/permissions/com.meizu.camera.xml \
    %:system/lib/hw/audio.primary.default.so \
    %:system/lib64/hw/audio.primary.default.so \
    %:system/vendor/lib/hw/audio.primary.default.so \
    %:system/vendor/lib64/hw/audio.primary.default.so \
    %:system/lib/hw/audio.primary.goldfish.so \
    %:system/lib64/hw/audio.primary.goldfish.so \
    %:system/vendor/lib/hw/audio.primary.goldfish.so \
    %:system/vendor/lib64/hw/audio.primary.goldfish.so \
    %:system/lib/hw/audio_policy.default.so \
    %:system/lib64/hw/audio_policy.default.so \
    %:system/vendor/lib/hw/audio_policy.default.so \
    %:system/vendor/lib64/hw/audio_policy.default.so \
    %:system/lib/hw/audio_policy.goldfish.so \
    %:system/lib64/hw/audio_policy.goldfish.so \
    %:system/vendor/lib/hw/audio_policy.goldfish.so \
    %:system/vendor/lib64/hw/audio_policy.goldfish.so \
    %:system/lib/hw/gralloc.default.so \
    %:system/lib64/hw/gralloc.default.so \
    %:system/vendor/lib/hw/gralloc.default.so \
    %:system/vendor/lib64/hw/gralloc.default.so \
    %:system/lib/hw/gralloc.goldfish.so \
    %:system/lib64/hw/gralloc.goldfish.so \
    %:system/vendor/lib/hw/gralloc.goldfish.so \
    %:system/vendor/lib64/hw/gralloc.goldfish.so \
    %:system/lib/hw/gralloc.ranchu.so \
    %:system/lib64/hw/gralloc.ranchu.so \
    %:system/vendor/lib/hw/gralloc.ranchu.so \
    %:system/vendor/lib64/hw/gralloc.ranchu.so \
    %:system/lib/hw/camera.goldfish.so \
    %:system/lib64/hw/camera.goldfish.so \
    %:system/lib/hw/camera.goldfish.jpeg.so \
    %:system/lib64/hw/camera.goldfish.jpeg.so \
    %:system/lib/hw/camera.ranchu.so \
    %:system/lib64/hw/camera.ranchu.so \
    %:system/lib/hw/camera.ranchu.jpeg.so \
    %:system/lib64/hw/camera.ranchu.jpeg.so \
    %:system/lib/hw/fingerprint.goldfish.so \
    %:system/lib64/hw/fingerprint.goldfish.so \
    %:system/lib/hw/fingerprint.ranchu.so \
    %:system/lib64/hw/fingerprint.ranchu.so \
    %:system/lib/hw/gps.goldfish.so \
    %:system/lib64/hw/gps.goldfish.so \
    %:system/lib/hw/gps.ranchu.so \
    %:system/lib64/hw/gps.ranchu.so \
    %:system/lib/hw/lights.goldfish.so \
    %:system/lib64/hw/lights.goldfish.so \
    %:system/lib/hw/power.goldfish.so \
    %:system/lib64/hw/power.goldfish.so \
    %:system/lib/hw/sensors.goldfish.so \
    %:system/lib64/hw/sensors.goldfish.so \
    %:system/lib/hw/sensors.ranchu.so \
    %:system/lib64/hw/sensors.ranchu.so \
    %:system/lib/hw/vibrator.goldfish.so \
    %:system/lib64/hw/vibrator.goldfish.so \
    %:system/vendor/lib/hw/gralloc.mt6755.so \
    %:system/vendor/lib64/hw/gralloc.mt6755.so, \
    $(PRODUCT_COPY_FILES))
# M6/LOS16 hwc lane 2026-08-03: hwcomposer.mt6755.so filter-out removed here
# (and in device_meizu_m6.mk) — it named the ONLY HWC module on the image.
# Rationale in device_meizu_m6.mk next to its filter block.
PRODUCT_CHARACTERISTICS := phone
# Build Station: keep soundtrigger isolated; sensors are enabled in
# device_meizu_m6.mk so sensorservice can reach the MTK HAL.
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.soundtrigger@2.0-impl \
    ,$(PRODUCT_PACKAGES))
PRODUCT_COPY_FILES := $(filter-out \
    %android.hardware.soundtrigger@2.0-impl.so:% \
    ,$(PRODUCT_COPY_FILES))

# Build Station: M6 pure64 app runtime until zygote_secondary/app_process32 is fixed.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.zygote=zygote64
PRODUCT_DEFAULT_PROPERTY_OVERRIDES := $(filter-out ro.zygote=%,$(PRODUCT_DEFAULT_PROPERTY_OVERRIDES))
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += ro.zygote=zygote64

# Build Station: current M6 runtime logs prove radio is blocked before modem
# bring-up because no HIDL radio service is published. Keep BOARD_PROVIDES_RILD
# set so the generic AOSP module stays out, then publish the MTK wrapper rild.
PRODUCT_COPY_FILES := $(filter-out \
    %:system/vendor/etc/init/rild.rc, \
    $(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    device/meizu/meizu_m6/rild-mtk-hidl.rc:system/vendor/etc/init/rild.rc
