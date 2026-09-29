# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
# BoardConfig.mk - Meizu M6 (meizu_m6 / M711), MediaTek MT6750

# N-era blobs go in with PRODUCT_COPY_FILES (vendor-blobs.mk), the way
# vendor/meizu/m95/m95-vendor.mk does it. Android 11+ rejects ELF files in
# PRODUCT_COPY_FILES; this flag only lifts that check (m95 BoardConfig.mk carries
# the same debt): nothing validates the blobs' DT_NEEDED at build time, so the
# closure is checked offline instead - meizu-fleet/tools/treble-closure.py,
# results in the report above.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Blob vs AOSP module at the same /vendor path (e.g. hw/fingerprint.default.so)
# warns instead of erroring, as on m95. The winner per path must be checked by
# sha256 against proprietary/SHA256SUMS after a full build.
BUILD_BROKEN_DUP_RULES := true

DEVICE_PATH := device/meizu/meizu_m6

# MT6750 uses eight ARMv8.0 Cortex-A53 cores. Keep the Cortex-A53 erratum workaround.
# Do not enable ARMv8.1 LSE instructions or inherit an unrelated 32-bit-zygote workaround.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

TARGET_USES_64_BIT_BINDER := true

# ---------------------------------------------------------------------------
# Board / platform identity
#
# TARGET_BOARD_PLATFORM: mt6750, as in the existing common tree
#   (m3_meizu_m6-common/BoardConfigCommon.mk: TARGET_BOARD_PLATFORM := mt6750,
#    TARGET_BOOTLOADER_BOARD_NAME := mt6750) and as the stock build.prop says
#   (ro.board.platform=mt6750). This is what selects hw modules named
#   *.mt6750.so, which is what the blobs are called.
# ro.hardware stays mt6755 (see cmdline below) because that is what the kernel
#   publishes and what names init.mt6755.rc / ueventd.mt6755.rc / fstab.mt6755.
#   Both statements are FACTs and they are not in conflict: MTK ships a mt6755
#   BSP for a mt6750-branded part.
#
# GPU: INFERENCE, not FACT. MT6750 is the down-binned MT6755 (factbase §7), so
#   the GPU IP is the same Mali-T860MP2 at a lower clock. Nothing on this disk
#   quotes a GPU string off an M6. It is cosmetic - it feeds ro.hardware.egl
#   fallbacks only.
# ---------------------------------------------------------------------------
TARGET_BOARD_PLATFORM := mt6750
TARGET_BOOTLOADER_BOARD_NAME := mt6750
TARGET_BOARD_PLATFORM_GPU := mali-t860mp2

TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true

BOARD_NAME := meizu_m6
# FACT: the existing tree asserts exactly `meizu_m6`
# (rom-work/device/meizu/meizu_m6/BoardConfig.mk). `meizu_M6` added because that
# is the factory ro.product.device.
TARGET_OTA_ASSERT_DEVICE := meizu_m6,meizu_M6,M711,m711

# M6 is 720x1280. Build both ili9881c and ili9881p panel drivers and let bootloader identity select the panel.
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# A-only geometry: recovery 32 MiB, custom 512 MiB, boot 16 MiB, system 2560 MiB.
# Userdata size is inherited and must be checked against the actual storage variant.
BOARD_FLASH_BLOCK_SIZE := 131072

BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11683216896

# The stock custom partition is mmcblk0p3 (512 MiB); this product uses it for /vendor.
# Preserve its contents before installing a vendor image.
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4

# A-only. No A/B, no virtual A/B, no dynamic partitions, no super image.
# NOTE: PRODUCT_USE_DYNAMIC_PARTITIONS must NOT be assigned here - it is a
# product variable marked .KATI_READONLY before BoardConfig.mk is read.
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false

# ---------------------------------------------------------------------------
# Treble / VNDK - ON (owner directive 2026-09-24: "all of the fleet Treble",
# template device/meizu/m95). Until 2026-09-24 this block said OFF; the facts it
# was built on still hold and are why this is a conversion, not a flag flip:
#   FACT: stock is NOT Treble - Android 7.0 NRD90M, ro.product.first_api_level=24,
#     no `vendor` entry in the stock scatter, no ro.treble/ro.vndk in the stock
#     build.prop (lineage_meizu_m6.mk);
#   FACT: the booting LOS 16.0 build was non-Treble ("ld.config.legacy.txt
#     (PRODUCT_FULL_TREBLE=false, BOARD_VNDK_VERSION not set)",
#     gunwest-import/m6rom16/rom-work/device/meizu/meizu_m6/ld.config.meizu_m6.txt:3-4)
#     and needed a 40-entry TARGET_LD_SHIM_LIBS cascade.
#
# What the conversion is:
#   * PRODUCT_FULL_TREBLE_OVERRIDE := true (lineage_meizu_m6.mk) - the shipping
#     level stays the honest 24, so the build would never turn Treble on by
#     itself (config.mk:668-676); with the override PRODUCT_TREBLE_LINKER_
#     NAMESPACES, PRODUCT_SEPOLICY_SPLIT and PRODUCT_ENFORCE_VINTF_MANIFEST all
#     follow it (config.mk:678-694);
#   * a real /vendor image (partition block above, fstab first_stage_mount);
#   * BOARD_VNDK_VERSION := current, exactly as m95 after measuring that a pinned
#     older VNDK cannot build on A13 (device/meizu/m95/BoardConfig.mk, "VNDK 30
#     was TRIED FIRST and REJECTED"). No PRODUCT_EXTRA_VNDK_VERSIONS: m95 ships
#     v30 only to boot an existing 18.1 vendor.img; M6 has no older Treble vendor.
#
# What it costs, measured offline (report §4): a vendor process no longer sees
# /system/lib*. Blobs that NEED a system-only library (libmedia, libskia,
# libandroid_runtime, libstagefright, libnativehelper, ...) fail to load until
# they get a vendor copy or a shim - m95 closed the same list with
# shims/Android.bp. And SurfaceFlinger loads libGLES_mali in the sphal namespace,
# where only LLNDK, VNDK-SP and (platform branch meizu-legacy-vendor) libbinder
# are visible; the M6 Mali also NEEDs libui.so, which m95's does not.
# ---------------------------------------------------------------------------
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VNDK_VERSION := current
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Vendor-owned properties (hw module suffixes, RIL, legacy-kernel VINTF flag).
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Boot addresses: kernel 0x40080000, ramdisk 0x45000000, tags 0x44000000.
# The second-stage size is zero; keep header base/offset values consistent.
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00f00000
BOARD_TAGS_OFFSET := 0x03f88000
BOARD_MKBOOTIMG_ARGS := --board 1552631950 --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --second_offset $(BOARD_SECOND_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET)

# Legacy MTK boot header: no header_version, no dtb in bootimg, no dtbo.
BOARD_BOOT_HEADER_VERSION := 0
BOARD_INCLUDE_DTB_IN_BOOTIMG :=
BOARD_INCLUDE_RECOVERY_DTBO :=

# binder.devices supplies binder, hwbinder and vndbinder on this 3.18 kernel.
# androidboot.hardware=mt6755 selects the matching init and fstab files.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.hardware=mt6755 androidboot.selinux=permissive binder.devices=binder,hwbinder,vndbinder androidboot.usb.config=adb buildvariant=userdebug

# Use the pinned 3.18.140 prebuilt with the eBPF changes required by this Android branch.
# Kernel sources are also needed for UAPI header generation; force-prebuilt prevents an unintended full kernel build.
# The panel configuration keeps physical rotation hardware disabled and rotation set to zero.
TARGET_NO_KERNEL := false
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
# 2026-09-25 (Treble): the kernel SOURCE is needed after all, while the
# prebuilt above stays what boot.img carries. FACT (first `m vendorimage` of
# branch lineage-20-treble, build-meizu_m6-treble-vendorimage_systemimage_
# check-vintf-all.log): the Soong genrule generated_kernel_includes
# (vendor/lineage/build/soong/Android.bp:21) runs
# `make -C $(TARGET_KERNEL_SOURCE) headers_install`, and with no source the
# vendor image fails on .dummy_dep with "kernel/meizu/meizu_m6: No such file or
# directory" - the same wall m95 hit on 2026-09-16 (device/meizu/m95/
# BoardConfig.mk, kernel block). Same fix as m95:
#   * kernel/meizu/meizu_m6 is a symlink to the eBPF worktree of this device's
#     3.18.140 kernel, meizu-fleet/wt/kernel_meizu_m6_ebpf/kernel-3.18 (branch
#     forge/meizu_m6-ebpf: the m95 eBPF series + meizu_m6_a13_defconfig + the kbuild
#     host-csingle/HOSTLDFLAGS fix m95 needed for headers_install, m95 kernel
#     3522613e). Created by hand, like kernel/meizu/m95; see
#     meizu-fleet/designs/TREBLE_M6_M6T_20260924.md §6.
#   * TARGET_FORCE_PREBUILT_KERNEL keeps kernel.mk on the prebuilt branch
#     (kernel.mk:180-190: FULL_KERNEL_BUILD := false, KERNEL_BIN :=
#     TARGET_PREBUILT_KERNEL); without it a present source + config means a
#     from-source kernel build.
# Headers vs ABI: the prebuilt is the same 3.18.140 line without the eBPF
# commits; the uapi difference is linux/bpf.h, which no vendor module of this
# tree includes. When the eBPF kernel becomes the boot kernel, drop
# TARGET_FORCE_PREBUILT_KERNEL (or swap the prebuilt) and headers and binary
# come from one tree.
TARGET_KERNEL_SOURCE := kernel/meizu/meizu_m6
TARGET_KERNEL_CONFIG := meizu_m6_a13_defconfig
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_KERNEL_VERSION := 3.18
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
BOARD_KERNEL_IMAGE_NAME := kernel

# ---------------------------------------------------------------------------
# Recovery / fstab
# ---------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6755
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_CHARGER_SHOW_PERCENTAGE := true

# ---------------------------------------------------------------------------
# Wi-Fi - MediaTek WMT / conn_soc combo chip.
#
# FACT: the common tree already declares MediaTek + lib_driver_cmd_mt66xx
#   (m3_meizu_m6-common/BoardConfigCommon.mk).
# FACT, and the reason WIFI_DRIVER_STATE_CTRL_PARAM must be present rather than
#   just WIFI_DRIVER_FW_PATH_PARAM: frameworks/opt/net/wifi/libwifi_hal builds
#   wifi_hal_common.cpp with -DWIFI_DRIVER_STATE_CTRL_PARAM only when the board
#   defines it; without it wifi_change_driver_state() is a no-op, /dev/wmtWifi is
#   never written, wlan0 never appears and wpa_supplicant dies with "Could not
#   read interface wlan0 flags: No such device". Measured on REDACTED_UNIT
#   2026-08-03: writing 1 to /dev/wmtWifi by hand brings up wlan0 with driver
#   mt-wifi immediately, so only the trigger was missing. (The whole paragraph is
#   quoted from the LOS16 BoardConfig that fixed it.)
# ---------------------------------------------------------------------------
BOARD_WLAN_DEVICE := MediaTek
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_mt66xx
WIFI_DRIVER_STATE_CTRL_PARAM := /dev/wmtWifi
WIFI_DRIVER_STATE_ON := 1
WIFI_DRIVER_STATE_OFF := 0
WIFI_DRIVER_OPERSTATE_PATH := /sys/class/net/wlan0/operstate
WIFI_DRIVER_STATE_CTRL_RETRIES := 8
WIFI_DRIVER_STATE_CTRL_RETRY_DELAY_US := 1000000

# ---------------------------------------------------------------------------
# Bluetooth
# FACT: BOARD_HAVE_BLUETOOTH_MTK := true in the common tree, and BT reaches
#   "enabled: true, state: ON, crashed 0" on the live LOS16 build (factbase §5.2;
#   pairing itself is UNVERIFIED).
# FACT: the LOS16 system.prop pins ro.hardware.bluetooth=blueangel, but the
#   LOS15.1 tree's own comment says "Use source-built Bluedroid HAL; stock
#   blueangel aborts in interop_database_add". The two lanes disagree; neither
#   claim has been re-tested on A13. Nothing is asserted here - see system.prop.
# ---------------------------------------------------------------------------
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_MTK := true

# ---------------------------------------------------------------------------
# SELinux
#
# FACT: the LOS 16.0 lane had to turn build-time assertions off for exactly this
#   family - "Pie public-policy neverallows reject Oreo-era MTK vendor rules
#   (first hits: dac_override for mtk_wmt_loader/mtk_gsm0710muxd/
#   mtk_aee_core_forwarder)" (m6rom16 m3_meizu_m6-common/BoardConfigCommon.mk).
#   A13's policy is strictly stricter than Pie's. Runtime is permissive via the
#   cmdline above. This is an acknowledged debt, not a solution.
# ---------------------------------------------------------------------------
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Mount points for the fstab's /protect_f, /protect_s, /nvdata (nofail). On A13
# the root after switch_root IS system.img, read-only, so init cannot mkdir them;
# without the directory mount_all skips the entry -> no /nvdata -> no NVRAM ->
# no IMEI/modem (init.meizu_m6.nvram.rc). system/core/rootdir/Android.mk:93-95
# splices this list into the mkdir of init.environ.rc's post-install. Same as
# m5c/m5s/m2note; labels in sepolicy/vendor/file_contexts (e2fsdroid fails on
# an unlabelled root dir - m5c build 2026-09-17).
BOARD_ROOT_EXTRA_FOLDERS := nvdata protect_f protect_s

# ---------------------------------------------------------------------------
# Not-Qualcomm. Leaving these on drags SurfaceFlinger into QTI wrappers; the
# LOS14.1 mt6755-common tree ties that directly to a black-screen deadlock it
# had to debug.
# ---------------------------------------------------------------------------
BOARD_USES_QCOM_HARDWARE := false
TARGET_USES_QCOM_BSP := false

# ---------------------------------------------------------------------------
# System properties file
# ---------------------------------------------------------------------------
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop
