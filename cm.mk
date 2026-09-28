## Specify phone tech before including full_phone
#$(call inherit-product, vendor/cm/config/gsm.mk)

# Release name
PRODUCT_RELEASE_NAME := meizu_m6

# Inherit some common CM stuff.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

# Inherit device configuration
# Build Station: full Lineage common product config required for OTA install tools
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

$(call inherit-product, device/meizu/meizu_m6/device_meizu_m6.mk)

# Configure dalvik heap
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

# Configure hwui memory
$(call inherit-product, frameworks/native/build/phone-xxhdpi-2048-hwui-memory.mk)

TARGET_SCREEN_HEIGHT := 1280
TARGET_SCREEN_WIDTH := 720

## Device identifier. This must come after all inclusions
PRODUCT_DEVICE := meizu_m6
PRODUCT_NAME := cm_meizu_m6
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := meizu_m6
PRODUCT_MANUFACTURER := Meizu

# Build Station: target device identity override
PRODUCT_NAME := cm_meizu_m6
PRODUCT_DEVICE := meizu_m6
PRODUCT_BRAND := meizu
PRODUCT_MANUFACTURER := Meizu
PRODUCT_MODEL := meizu_m6
PRODUCT_RELEASE_NAME := meizu_m6
TARGET_OTA_ASSERT_DEVICE := meizu_m6
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=cm_meizu_m6 \
    PRODUCT_DEVICE=meizu_m6 \
    TARGET_DEVICE=meizu_m6
# Build Station: bootdiag cache capture
PRODUCT_COPY_FILES += \
    device/meizu/meizu_m6/forge-bootdiag.sh:system/bin/forge-bootdiag.sh \
    device/meizu/meizu_m6/forge-bootdiag.rc:system/etc/init/forge-bootdiag.rc

# Build Station: final real-device hardware HAL cleanup after all product inheritance.
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
    %android.hardware.sensor.%:% \
    device/generic/goldfish/% \
    device/generic/mini-emulator-% \
    device/google/atv/init.goldfish.rc:% \
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
    %:system/vendor/lib/hw/camera.goldfish.so \
    %:system/vendor/lib64/hw/camera.goldfish.so \
    %:system/lib/hw/camera.goldfish.jpeg.so \
    %:system/lib64/hw/camera.goldfish.jpeg.so \
    %:system/vendor/lib/hw/camera.goldfish.jpeg.so \
    %:system/vendor/lib64/hw/camera.goldfish.jpeg.so \
    %:system/lib/hw/camera.ranchu.so \
    %:system/lib64/hw/camera.ranchu.so \
    %:system/vendor/lib/hw/camera.ranchu.so \
    %:system/vendor/lib64/hw/camera.ranchu.so \
    %:system/lib/hw/camera.ranchu.jpeg.so \
    %:system/lib64/hw/camera.ranchu.jpeg.so \
    %:system/vendor/lib/hw/camera.ranchu.jpeg.so \
    %:system/vendor/lib64/hw/camera.ranchu.jpeg.so \
    %:system/lib/hw/fingerprint.goldfish.so \
    %:system/lib64/hw/fingerprint.goldfish.so \
    %:system/vendor/lib/hw/fingerprint.goldfish.so \
    %:system/vendor/lib64/hw/fingerprint.goldfish.so \
    %:system/lib/hw/fingerprint.ranchu.so \
    %:system/lib64/hw/fingerprint.ranchu.so \
    %:system/vendor/lib/hw/fingerprint.ranchu.so \
    %:system/vendor/lib64/hw/fingerprint.ranchu.so \
    %:system/lib/hw/gps.goldfish.so \
    %:system/lib64/hw/gps.goldfish.so \
    %:system/vendor/lib/hw/gps.goldfish.so \
    %:system/vendor/lib64/hw/gps.goldfish.so \
    %:system/lib/hw/gps.ranchu.so \
    %:system/lib64/hw/gps.ranchu.so \
    %:system/vendor/lib/hw/gps.ranchu.so \
    %:system/vendor/lib64/hw/gps.ranchu.so \
    %:system/lib/hw/lights.goldfish.so \
    %:system/lib64/hw/lights.goldfish.so \
    %:system/vendor/lib/hw/lights.goldfish.so \
    %:system/vendor/lib64/hw/lights.goldfish.so \
    %:system/lib/hw/power.goldfish.so \
    %:system/lib64/hw/power.goldfish.so \
    %:system/vendor/lib/hw/power.goldfish.so \
    %:system/vendor/lib64/hw/power.goldfish.so \
    %:system/lib/hw/sensors.goldfish.so \
    %:system/lib64/hw/sensors.goldfish.so \
    %:system/vendor/lib/hw/sensors.goldfish.so \
    %:system/vendor/lib64/hw/sensors.goldfish.so \
    %:system/lib/hw/sensors.ranchu.so \
    %:system/lib64/hw/sensors.ranchu.so \
    %:system/vendor/lib/hw/sensors.ranchu.so \
    %:system/vendor/lib64/hw/sensors.ranchu.so \
    %:system/lib/hw/vibrator.goldfish.so \
    %:system/lib64/hw/vibrator.goldfish.so \
    %:system/vendor/lib/hw/vibrator.goldfish.so \
    %:system/vendor/lib64/hw/vibrator.goldfish.so \
    %:root/ueventd.goldfish.rc \
    %:root/ueventd.ranchu.rc, \
    $(PRODUCT_COPY_FILES))

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
    %:system/vendor/lib64/hw/gralloc.mt6755.so \
    %:system/vendor/lib/hw/hwcomposer.mt6755.so \
    %:system/vendor/lib64/hw/hwcomposer.mt6755.so, \
    $(PRODUCT_COPY_FILES))
PRODUCT_CHARACTERISTICS := phone
# Build Station: M6 boot-unblock, do not publish broken sensors/soundtrigger HALs.
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.sensors@1.0-impl.mtk \
    android.hardware.sensors@1.0-service.mtk \
    android.hardware.soundtrigger@2.0-impl \
    ,$(PRODUCT_PACKAGES))
PRODUCT_COPY_FILES := $(filter-out \
    %android.hardware.sensor.accelerometer.xml:% \
    %android.hardware.sensor.compass.xml:% \
    %android.hardware.sensor.gyroscope.xml:% \
    %android.hardware.sensor.light.xml:% \
    %android.hardware.sensor.proximity.xml:% \
    %android.hardware.sensor.stepcounter.xml:% \
    %android.hardware.sensor.stepdetector.xml:% \
    %sensors.mt6750.so:% \
    %android.hardware.sensors@1.0-impl.mtk.so:% \
    %android.hardware.sensors@1.0-service.mtk:% \
    %android.hardware.soundtrigger@2.0-impl.so:% \
    ,$(PRODUCT_COPY_FILES))
