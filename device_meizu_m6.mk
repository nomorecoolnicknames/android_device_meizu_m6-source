# Build Station: Meizu M6 target device product fragment.
LOCAL_PATH := device/meizu/meizu_m6
COMMON_PATH := device/meizu/m3_meizu_m6-common

# Screen density
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xhdpi
PRODUCT_AAPT_PREBUILT_DPI := xhdpi xxhdpi hdpi tvdpi mdpi ldpi

# Product common configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Root default.prop de-duplicates by first key; M6 currently boots as pure
# arm64 app runtime because app_process32 aborts and restarts zygote64.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += ro.zygote=zygote64
PRODUCT_DEFAULT_PROPERTY_OVERRIDES := $(filter-out ro.zygote=%,$(PRODUCT_DEFAULT_PROPERTY_OVERRIDES))
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.adb.secure=0 \
    ro.zygote=zygote64 \
    persist.service.acm.enable=0 \
    persist.sys.root_access=3 \
    persist.sys.usb.config=adb \
    ro.allow.mock.location=0 \
    ro.debuggable=1 \
    ro.dalvik.vm.native.bridge=0 \
    ro.mount.fs=EXT4 \
    ro.kernel.android.checkjni=0 \
    ro.telephony.ril.config=fakeiccid \
    ro.com.android.mobiledata=false

# Hardware-specific permissions. Sensors and microphone are withheld until the MTK HAL/input path is stable.
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/handheld_core_hardware_no_mic.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:system/etc/permissions/android.hardware.faketouch.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    $(COMMON_PATH)/configs/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:system/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:system/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml

# HIDL manifest
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/manifest.xml:$(TARGET_COPY_OUT_VENDOR)/manifest.xml

# Device launched with M
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.first_api_level=23

# Runtime identity and debug defaults
# M6/LOS16 hwc lane 2026-08-03: ro.hardware.hwcomposer=mt6755 because the only
# HWC module on the image is hwcomposer.mt6755.so (vendor blob; there is no
# hwcomposer.mt6750.so anywhere). The old =mt6750 value pointed at a
# nonexistent file; loading only worked because hw_get_module falls through to
# ro.hardware, which LK's cmdline (androidboot.hardware=mt6755) sets to mt6755
# regardless of the =mt6750 override below (ro.* is first-wins, init sets it
# from androidboot before build.prop loads). Same fix in system.prop:144.
# debug.sf.disable_hwc / debug.composition.type were REMOVED here: neither Pie
# SurfaceFlinger (no such prop in frameworks/native) nor the mt6755 blob
# (strings: only debug.hwc.*) reads them, and =1/gpu contradicted the
# 2026-06-21 lag fix documented in system.prop:166-173.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.mediatek.platform=MT6750 \
    ro.hardware=mt6750 \
    ro.hardware.audio=mt6750 \
    ro.hardware.gralloc=mt6750 \
    ro.hardware.hwcomposer=mt6755 \
    ro.hardware.camera=mt6750 \
    ro.hardware.gps=mt6750 \
    ro.opengles.version=196610 \
    media.settings.xml=/vendor/etc/media_profiles.xml \
    persist.media.treble_omx=false \
    debug.stagefright.softenc.ignore_fence_timeout=true \
    debug.sf.hw=1 \
    debug.egl.hw=1 \
    persist.sys.usb.config=adb

# Dalvik/HWUI
$(call inherit-product-if-exists, frameworks/native/build/phone-xxhdpi-3072-dalvik-heap.mk)
$(call inherit-product-if-exists, frameworks/native/build/phone-xxhdpi-3072-hwui-memory.mk)

# RIL / modem
# Build Station RIL bring-up: use the MTK Oreo HIDL rild/libril wrapper, not
# the generic AOSP rild path, so framework telephony can resolve radio slot HALs.
ENABLE_VENDOR_RIL_SERVICE := true
PRODUCT_PACKAGES += \
    rild \
    libccci_util \
    muxreport \
    terservice

# Wi-Fi / BT / connectivity
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0 \
    android.hardware.wifi@1.0-impl \
    android.hardware.wifi@1.0-service \
    lib_driver_cmd_mt66xx \
    libwifi-hal-mt66xx \
    hostapd \
    wificond \
    wifilogd \
    wpa_supplicant \
    wpa_supplicant.conf \
    wmt_loader \
    android.hardware.bluetooth@1.0-service.mtk

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/hostapd_default.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/hostapd_default.conf \
    $(COMMON_PATH)/configs/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf \
    $(COMMON_PATH)/configs/p2p_supplicant_overlay.conf:system/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/wifi/init.m6.wifi.rc:system/etc/init/init.m6.wifi.rc \
    $(COMMON_PATH)/configs/agps_profiles_conf2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/agps_profiles_conf2.xml \
    $(COMMON_PATH)/keylayout/ACCDET.kl:system/usr/keylayout/ACCDET.kl \
    $(COMMON_PATH)/keylayout/AVRCP.kl:system/usr/keylayout/AVRCP.kl \
    $(COMMON_PATH)/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(COMMON_PATH)/keylayout/mtk-tpd.kl:system/usr/keylayout/mtk-tpd.kl \
    $(COMMON_PATH)/keylayout/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Generic.kl

# mBack button fix (2026-06-21): EventHub does not load the (correct, installed)
# mtk-kpd.kl for the physical button — it falls back to Generic.kl, whose stock
# `key 102 MOVE_HOME` makes the button do a cursor/selection jump instead of Home.
# This ships a Generic.kl override (key 102 -> HOME) to /vendor/usr/keylayout, which
# EventHub searches BEFORE /system, so the fallback now yields HOME. Combined with the
# overlay config_longPressOnHomeBehavior=2, the button gives press=Home, hold=Recents.

# Fingerprint TEE init (2026-06-22): install microtrust.rc so init starts teei_daemon
# (post-fs-data) + goodixfp on soter.teei.init=INIT_OK. FACT: the file existed in-tree but
# had NO copy rule, so the bacon build OMITTED it -> teei never initialized -> goodixfp
# never started -> fingerprint disappeared. Restoring the copy rule fixes the regression.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/microtrust.rc:system/vendor/etc/init/microtrust.rc

# Core HAL/service plumbing
PRODUCT_PACKAGES += \
    hwservicemanager \
    vndservicemanager \
    servicemanager \
    mediaserver \
    libstlport

# Graphics/display
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.memtrack@1.0-impl \
    android.hardware.renderscript@1.0-impl \
    libRSDriver_mtk \
    libion \
    libui_ext \
    libgralloc_extra \
    libgui_ext \
    WallpaperPicker

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/egl.cfg:system/lib/egl/egl.cfg

# Thermal / power / lights / vibrator
PRODUCT_PACKAGES += \
    android.hardware.health@1.0-impl \
    android.hardware.health@1.0-service \
    android.hardware.thermal@1.0-impl \
    android.hardware.thermal@1.0-service \
    thermal_manager \
    android.hardware.power@1.0-impl \
    power.default

# 2026-08-03 (LOS 16.0, M6): android.hardware.light@2.0-service.mtk is a PHANTOM
# package. vendor/mediatek/hidl/light/Android.bp is a comment-only file pointing
# at device/meizu/m2note/light, which is not checked out, so the module was never
# built and never installed -- while sepolicy/manifest.xml declares
# android.hardware.light@2.0::ILight/default as hwbinder.
# FACT (device REDACTED_UNIT, boot 2026-08-03 08:48): system_server blocks
# forever on "ServiceManagement: Waited one second for
# android.hardware.light@2.0::ILight/default. Waiting another..." (logcat, pid
# 750 tid 815 android.display) and sys.boot_completed is never set;
# /vendor/bin/hw contains no light service binary.
# Fix = the generic AOSP pair, exactly as already landed for m681
# (device/meizu/m681/device.mk:433-453). The -service binary is only
# defaultPassthroughServiceImplementation<ILight>()
# (hardware/interfaces/light/2.0/default/service.cpp), so it dlopens the -impl.so
# at runtime and is useless without it; the impl wraps the legacy
# lights.mt6750.so that already ships in /system/vendor/lib*/hw.
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service \
    android.hardware.light@2.0-impl

# Vibrator had no HIDL backing (same gap m681 fixed 2026-07-12): the legacy
# vibrator blob ships in /vendor/lib*/hw but nothing registers
# android.hardware.vibrator@1.0::IVibrator/default. Non-blocking for boot, but
# vibration is dead without it.
PRODUCT_PACKAGES += \
    android.hardware.vibrator@1.0-service.mtk

# Audio output only for first boot; primary capture is intentionally not advertised.
PRODUCT_PACKAGES += \
    android.hardware.audio@2.0-impl \
    android.hardware.audio@2.0-service.mtk \
    android.hardware.audio.effect@2.0-impl \
    audio.a2dp.default \
    audio.usb.default \
    audio.r_submix.default \
    libaudiopolicymanagerdefault \
    libaudio-resampler \
    libnbaio \
    libtinyalsa \
    libtinycompress \
    libtinymix \
    libtinyxml \
    libfs_mgr

PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/audio_device.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_device.xml \
    vendor/meizu/meizu_m6/proprietary/vendor/etc/audio_policy.conf:system/etc/audio_policy.conf

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl.mtk \
    android.hardware.sensors@1.0-service.mtk

PRODUCT_COPY_FILES += \
    vendor/meizu/meizu_m6/proprietary/vendor/lib/hw/sensors.mt6750.so:system/vendor/lib/hw/sensors.mt6750.so \
    vendor/meizu/meizu_m6/proprietary/vendor/lib64/hw/sensors.mt6750.so:system/vendor/lib64/hw/sensors.mt6750.so \
    vendor/meizu/meizu_m6/proprietary/etc/permissions/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    vendor/meizu/meizu_m6/proprietary/etc/permissions/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    vendor/meizu/meizu_m6/proprietary/etc/permissions/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    vendor/meizu/meizu_m6/proprietary/etc/permissions/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    vendor/meizu/meizu_m6/proprietary/etc/permissions/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml

# Camera/GNSS/media framework pieces
PRODUCT_PACKAGES += \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    libstagefright_soft_avcenc \
    libstagefright_soft_aacdec \
    libstagefright_soft_aacenc \
    libstagefright_soft_amrdec \
    libstagefright_soft_amrnbenc \
    libstagefright_soft_amrwbenc \
    libstagefright_soft_avcdec \
    libstagefright_soft_flacdec \
    libstagefright_soft_flacenc \
    libstagefright_soft_g711dec \
    libstagefright_soft_gsmdec \
    libstagefright_soft_hevcdec \
    libstagefright_soft_mp3dec \
    libstagefright_soft_mpeg2dec \
    libstagefright_soft_mpeg4dec \
    libstagefright_soft_mpeg4enc \
    libstagefright_soft_opusdec \
    libstagefright_soft_rawdec \
    libstagefright_soft_vorbisdec \
    libstagefright_soft_vpxdec \
    libstagefright_soft_vpxenc \
    libcamera_parameters_mtk \
    libcam.client \
    libmtkshim_gui \
    libmmsdkservice.feature \
    libcurl \
    libandroid_net

PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:system/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:system/etc/media_codecs_google_video.xml \
    $(COMMON_PATH)/configs/media_codecs_performance.xml:system/etc/media_codecs_performance.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml \
    $(COMMON_PATH)/configs/media_codecs_performance.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance.xml \
    $(COMMON_PATH)/configs/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles.xml \
    $(COMMON_PATH)/configs/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    $(COMMON_PATH)/configs/media_codecs_firstboot.xml:system/etc/media_codecs.xml \
    $(COMMON_PATH)/configs/media_codecs_firstboot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(COMMON_PATH)/configs/seccomp_policy/mediacodec-vendor-empty.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    $(COMMON_PATH)/configs/mtk_omx_core.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/mtk_omx_core.cfg

# Keymaster/DRM/filesystems
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.drm@1.0-impl \
    android.hardware.drm@1.0-service \
    e2fsck \
    fibmap.f2fs \
    fsck.f2fs \
    mkfs.f2fs \
    make_ext4fs \
    resize2fs \
    setup_fs \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat \
    fsck.ntfs \
    mkfs.ntfs \
    mount.ntfs

# Fingerprint (Goodix mBack)
# The fitted sensor is Goodix GF3208; its legacy HAL (fingerprint.default.so)
# reports module API 2.0 (0x200). The AOSP @2.1 default service rejects that
# (kVersion 2.1), so use the LineageOS @2.0 wrapper service instead: it expects
# a 2.0 module yet still registers the V2_1 IBiometricsFingerprint interface
# that FingerprintService binds. No patch to shared hardware/interfaces needed.
# (Runtime: started by init.microtrust.rc only after soter.teei.init=INIT_OK.)
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.0-service

# Build Station: keymaster ABI fix for fingerprint HAL.
# fps_hal (/vendor/bin/hw/) loads fingerprint.default.so (Nougat blob) via
# hw_get_module(); that blob NEEDs libkeymaster_messages.so with Nougat ABI.
# Oreo's /system/lib64/libkeymaster_messages.so has a different C++ mangling
# for copy_size_and_data_from_buf (keymaster::UniquePtr vs global ::UniquePtr),
# causing dlopen to fail → FingerprintService "Failed to open Fingerprint HAL".
# Fix: override ld.config.txt with a device-local version that prepends
# /vendor/lib64/fp_a7 (which holds the matching Nougat blobs) to the [vendor]
# namespace search path, BEFORE /system/lib64.  The [legacy] namespace (used by
# /system/bin/keystore, /system/bin/goodixfingerprintd, etc.) is unchanged.
# Remove the generic BUILD_PREBUILT ld.config.txt (ld.config.legacy.txt) from
# core_minimal.mk so our PRODUCT_COPY_FILES is the sole installer.
PRODUCT_PACKAGES := $(filter-out \
    ld.config.txt \
    ,$(PRODUCT_PACKAGES))
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/ld.config.meizu_m6.txt:system/etc/ld.config.txt

# Ramdisk
# Build Station: keep platform root init.rc; do not ship legacy common rootdir/init.rc to root/init.rc.
# Build Station: keep platform init.usb.rc; do not ship legacy common rootdir/init.usb.rc to root/init.usb.rc.
PRODUCT_COPY_FILES += \
    system/core/rootdir/init.zygote64.rc:root/init.zygote64.rc \
    $(COMMON_PATH)/rootdir/init.mt6755.rc:root/init.mt6755.rc \
    $(COMMON_PATH)/rootdir/init.mt6755.rc:root/init.mt6750.rc \
    $(COMMON_PATH)/rootdir/init.mt6755.usb.rc:root/init.mt6755.usb.rc \
    $(COMMON_PATH)/rootdir/init.mt6755.usb.rc:root/init.mt6750.usb.rc \
    $(COMMON_PATH)/rootdir/init.rilproxy.rc:root/init.rilproxy.rc \
    $(COMMON_PATH)/rootdir/init.modem.rc:root/init.modem.rc \
    $(COMMON_PATH)/rootdir/init.nvdata.rc:root/init.nvdata.rc \
    $(COMMON_PATH)/rootdir/init.aee.rc:root/init.aee.rc \
    $(COMMON_PATH)/rootdir/init.project.rc:root/init.project.rc \
    $(COMMON_PATH)/rootdir/init.trace.rc:root/init.trace.rc \
    $(COMMON_PATH)/rootdir/init.xlog.rc:root/init.xlog.rc \
    $(COMMON_PATH)/rootdir/meta_init.rc:root/meta_init.rc \
    $(COMMON_PATH)/rootdir/meta_init.modem.rc:root/meta_init.modem.rc \
    $(COMMON_PATH)/rootdir/meta_init.project.rc:root/meta_init.project.rc \
    $(COMMON_PATH)/rootdir/vendor_init.mt6755.rc:root/vendor_init.mt6755.rc \
    $(COMMON_PATH)/rootdir/vendor_init.mt6755.rc:root/vendor_init.mt6750.rc \
    $(COMMON_PATH)/rootdir/factory_init.rc:root/factory_init.rc \
    $(COMMON_PATH)/rootdir/factory_init.project.rc:root/factory_init.project.rc \
    $(COMMON_PATH)/rootdir/fstab.mt6755:root/fstab.mt6755 \
    $(COMMON_PATH)/rootdir/fstab.mt6755:root/fstab.mt6750 \
    $(COMMON_PATH)/rootdir/ueventd.mt6755.rc:root/ueventd.mt6755.rc \
    $(COMMON_PATH)/rootdir/ueventd.mt6755.rc:root/ueventd.mt6750.rc \
    $(COMMON_PATH)/rootdir/enableswap.sh:root/enableswap.sh

# Bootdiag capture
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/forge-bootdiag.sh:system/bin/forge-bootdiag.sh \
    $(LOCAL_PATH)/m6-data-space-guard.sh:system/bin/m6-data-space-guard.sh \
    $(LOCAL_PATH)/forge-bootdiag.rc:system/etc/init/forge-bootdiag.rc

# Launcher/Lineage essentials
PRODUCT_PACKAGES += \
    LineageSettingsProvider \
    Trebuchet

DEVICE_PACKAGE_OVERLAYS := \
    $(COMMON_PATH)/overlay \
    $(LOCAL_PATH)/overlay

# Vendor blobs
$(call inherit-product, vendor/meizu/meizu_m6/meizu_m6-vendor.mk)

# Build Station: M6 legacy vendor daemons link stock core libs from the vendor namespace.
PRODUCT_COPY_FILES += \
    vendor/meizu/meizu_m6/proprietary/lib/libfs_mgr.so:system/vendor/lib/libfs_mgr.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libfs_mgr.so:system/vendor/lib64/libfs_mgr.so \
    vendor/meizu/meizu_m6/proprietary/lib/liblogwrap.so:system/vendor/lib/liblogwrap.so \
    vendor/meizu/meizu_m6/proprietary/lib64/liblogwrap.so:system/vendor/lib64/liblogwrap.so \
    vendor/meizu/meizu_m6/proprietary/lib/libxml2.so:system/vendor/lib/libxml2.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libxml2.so:system/vendor/lib64/libxml2.so \
    vendor/meizu/meizu_m6/proprietary/lib/libicui18n.so:system/vendor/lib/libicui18n.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libicui18n.so:system/vendor/lib64/libicui18n.so \
    vendor/meizu/meizu_m6/proprietary/lib/libicuuc.so:system/vendor/lib/libicuuc.so \
    vendor/meizu/meizu_m6/proprietary/lib64/libicuuc.so:system/vendor/lib64/libicuuc.so

# Build Station: M6 pure64 camera bring-up.
# Stock M6 has 64-bit camera provider and camera HAL blobs; install the
# standalone provider service so CameraService can fetch legacy/0 from hwservicemanager.
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    camera.device@1.0-impl \
    libyuv \
    camera.device@3.2-impl \
    android.hardware.camera.provider@2.4-service

# Build Station: M6 camera lane 2026-08-03 — Pie has no shared libskia
# (external/skia is cc_library_static; the code lives inside libhwui), but the
# Flyme blob libcam.camadapter.so carries DT_NEEDED [libskia.so] while
# importing ZERO Sk* symbols (readelf/nm, both ABIs). A missing NEEDED library
# fails the whole camera HAL load chain at open time:
#   MtkCam dlopen libcam_platform.so -> "libskia.so" not found -> No Platform
#   -> CameraClient initialize -38 -> every camera open fails (live 2026-08-03).
# Empty stub satisfies the loader at zero ABI risk (m95 precedent,
# device/meizu/m95/shims + BLOB_SHIMS.md). Installed as
# /system/vendor/lib{,64}/libskia.so via post-install symlink (see
# shims/Android.mk for why the module cannot be named libskia outright).
PRODUCT_PACKAGES += \
    libskia_m6_stub

# Build Station: M6 camera HAL LD_PRELOAD shims (device/meizu/meizu_m6/camera_compat).
#   libm6_camera_glconsumer_compat - GLConsumer::getCurrentBuffer() ABI bridge (from source)
#   libm6_camera_tsf_bypass        - stubs the NULL-deref TSF/LSC path in libcamalgo.so (prebuilt)
# The colon-joined LD_PRELOAD wiring is patched directly into the two init rc
# sources that get packaged (both installed via LOCAL_INIT_RC, so patching the
# source avoids a double-install collision with a competing ETC module):
#   - frameworks/av/media/mediaserver/mediaserver.rc
#   - hardware/interfaces/camera/provider/2.4/default/android.hardware.camera.provider@2.4-service.rc
PRODUCT_PACKAGES += \
    libm6_camera_glconsumer_compat \
    libm6_camera_tsf_bypass

# Build Station: keep soundtrigger isolated; sensors are now enabled after
# fresh capture proved kernel/I2C devices exist and userspace was filtered out.
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.soundtrigger@2.0-impl \
    ,$(PRODUCT_PACKAGES))
PRODUCT_COPY_FILES := $(filter-out \
    %android.hardware.soundtrigger@2.0-impl.so:% \
    ,$(PRODUCT_COPY_FILES))

# M6 GPS/GNSS assistance config (shipped gps.conf was empty -> no NTP time
# injection / no SUPL/XTRA). Restores standard user-plane assistance.
PRODUCT_COPY_FILES += \
    device/meizu/meizu_m6/gps.conf:system/etc/gps.conf \
    device/meizu/meizu_m6/gps.conf:system/vendor/etc/gps.conf

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
# Build Station: early ADB bring-up defaults
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0 \
    persist.sys.usb.config=adb \
    persist.service.adb.enable=1 \
    persist.sys.adb.shell=/system/bin/sh

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
    %:system/vendor/lib/hw/keystore.mt6750.so \
    %:system/vendor/lib64/hw/keystore.mt6750.so, \
    $(PRODUCT_COPY_FILES))
# M6/LOS16 hwc lane 2026-08-03: the hwcomposer.mt6755.so filter-out lines that
# used to sit in the block above (and in lineage.mk) are gone. They dated from
# the original cm-14.1 tree, whose proprietary-files.txt RENAMED the blob to
# hwcomposer.mt6750.so on extract and filtered the mt6755-named duplicates.
# The current vendor mk (vendor/meizu/meizu_m6/meizu_m6-vendor-blobs.mk:236,260)
# installs the blob ONLY under its real mt6755 name, which those filters named
# exactly. They were inert in practice (inherit-product merges vendor
# PRODUCT_COPY_FILES after this file is parsed, which is why the Jul 25 image
# still shipped the blob), but one refactor away from silently dropping the
# only HWC module on the device. SurfaceFlinger composes through this blob
# (HWC2On1Adapter, "HWC 1.5 device") — it must ship.
PRODUCT_CHARACTERISTICS := phone

# LOS 16.0: /vendor/bin/MPED links libmpe.sensorlistener.so, which imports the
# N-era android::SensorEventQueue::enableSensor. vendor/mediatek/symbols/sensor.cpp
# provides it; without the module + shim entry MPED crash-loops.
PRODUCT_PACKAGES += \
    libmtkshim_sensor

# mBack tap=Back daemon (lane mback, 2026-08-03): mbackd grabs mtk-kpd (event1),
# splits tap/click/hold by press duration and injects BACK/HOME/APP_SWITCH via
# uinput ("mbackd-keys" 4642:0001). Native fallback (vendor Generic.kl 102->HOME
# + overlay long-press=Recents) still applies whenever mbackd is not running.
PRODUCT_PACKAGES += \
    mbackd

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/mback/Vendor_4642_Product_0001.kl:system/usr/keylayout/Vendor_4642_Product_0001.kl
