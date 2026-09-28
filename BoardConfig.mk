#
# BoardConfig.mk - Meizu M6 (meizu_m6 / M711), MediaTek MT6750
# LineageOS 20 / Android 13 device tree.
#
# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# ---------------------------------------------------------------------------
# EVIDENCE POLICY (see /srv/forge/android/CLAUDE.md §2)
# FACT       = read off a file / image header / device capture on this disk.
# INFERENCE  = derived from one or more FACTs.
# HYPOTHESIS = untested; carries a falsification step.
#
# Companion report: /srv/forge/android/meizu-fleet/trees/M6_LOS20_TREE.md
#
# THE ONE-LINE TRUTH ABOUT THIS TREE: it is a placeholder, not a ROM. The kernel
# pinned below is 3.18.140 - it boots this device every day under LineageOS 16.0
# (Pie), and it cannot boot Android 13. 3.18 has no CONFIG_CGROUP_BPF and no
# ANDROID_BINDER_DEVICES, and A13's bpfloader.rc carries
# `reboot_on_failure reboot,bpfloader-failed`, i.e. a permanent reboot loop
# rather than a degraded boot. The symbol-by-symbol gap table is
# meizu-fleet/trees/M681_LOS20_TREE.md §3.1 (written for 4.4/4.9; 3.18 is worse
# than both). This is a bench for the MT6755/MT6750 4.19 campaign.
#
# 2026-09-25, branch lineage-20-treble: FULL TREBLE, like m95. /vendor is the
# real `custom` partition (mmcblk0p3, 512 MiB), every N blob lives there
# (vendor-blobs.mk), VNDK = current. Report with the evidence:
# meizu-fleet/designs/TREBLE_M6_M6T_20260924.md. Correction to the paragraph
# above, from the same report: m95 boots A13 on 3.18.22, so the kernel wall is
# not "3.18", it is the missing eBPF (the m95 kernel carries a backport series,
# see the kernel block below); 4.19 is no longer the only way out.
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Architecture
#
# FACT: MT6750 is 8x Cortex-A53, AArch64, ARMv8.0-A - the down-binned bin of the
#   same silicon as MT6755: BSP directory `mt6755`, CONFIG_ARCH_MT6755=y,
#   registry kernel_platform: mt6755 for m681/meizu_m6/l681
#   (meizu-fleet/factbase/mt6755_family.md §7, quoting
#    docs/MT6755_FAMILY_4.9_PORT.md §1).
# FACT: live on hardware - [ro.boot.hardware]: [mt6755] and [ro.hardware]:
#   [mt6755] on the M6 stock harvest, unit REDACTED_UNIT
#   (meizu_m6/captures/20260620-121905-m6-STOCK-flyme-harvest-REDACTED_UNIT/
#    10-getprop.txt). The SoC markets as MT6750; the software platform is mt6755.
# FACT: no LSE atomics (FEAT_LSE is ARMv8.1-A) on any Cortex-A53.
#
# FACT: build/soong/cc/config/arm64_device.go:31-33 maps "armv8-a" to exactly
#   `-march=armv8-a`; :57-59 maps "cortex-a53" to `-mcpu=cortex-a53`. Neither
#   enables +lse. Forbidden neighbours in the same table: "armv8-2a",
#   "cortex-a55". NEITHER is used here.
#
# DO NOT change TARGET_ARCH_VARIANT to armv8-2a or TARGET_CPU_VARIANT to
# cortex-a55/kryo*/exynos-m*. That is an instant SIGILL storm on this SoC.
#
# CHANGED vs the existing LOS15.1/16.0 trees, deliberately:
#   FACT: device/meizu/m3_meizu_m6-common/BoardConfigCommon.mk sets
#     TARGET_CPU_VARIANT := generic and TARGET_2ND_ARCH_VARIANT := armv7-a-neon.
#   `generic` costs the A53 erratum workaround (-Wl,--fix-cortex-a53-843419,
#   arm64_device.go:120/145) and the A53 scheduling model for no benefit. This
#   tree pins cortex-a53 on both ABIs, matching the m681 pass which was verified
#   at the artifact level (zero `+lse`, zero `-moutline-atomics` in the generated
#   build.ninja; meizu-fleet/trees/M681_LOS20_TREE.md §2.1).
#
# Open risk R7, fleet-wide (BRINGUP_STATE.md §1.2): two LOS20 modules carry
# higher-than-v8.0 flags and land in the image - XNNPACK's armv8.2 microkernels
# inside libtflite.so (runtime-gated by cpuinfo_has_arm_neon_dot()) and
# /system/bin/crypto (-march=armv8-a+crypto, i.e. ARMv8.0 + optional Crypto
# Extensions, not ARMv8.1). Re-check after any toolchain bump with the ninja scan
# in M681_LOS20_TREE.md §8.
#
# REJECTED for this tree: M6_PURE_ARM64 := true, the LOS16 switch that publishes
#   only arm64-v8a and refuses to start zygote_secondary. FACT: it exists in
#   gunwest-import/m6rom16/rom-work/device/meizu/meizu_m6/BoardConfig.mk with the
#   comment "app_process32 still aborts and kills zygote64". That was an Oreo/Pie
#   bring-up workaround for a specific 32-bit abort on Nougat blobs; carrying it
#   into A13 before anything has ever booted would bake in a workaround for a bug
#   nobody has reproduced on A13. It is a one-line change if it turns out to be
#   needed again.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Screen
#
# FACT: 720x1280 - device/meizu/meizu_m6/cm.mk:22-23 in the LOS15.1 tree
#   (TARGET_SCREEN_HEIGHT := 1280, TARGET_SCREEN_WIDTH := 720), and the M6T dump
#   analysis states the comparison the other way round as a hard fact:
#   "M6T is 720 x 1440 (18:9), M6 is 720 x 1280 (16:9)"
#   (meizu_m6t/M6T_DUMP_ANALYSIS_2026-07-22.md §3).
# FACT: [ro.sf.lcd_density]: [320] on the live stock unit and in the stock
#   build.prop => xhdpi.
#
# PANEL - THE OPEN QUESTION OF THIS DEVICE, and it is NOT decided in this tree.
#   FACT (factbase §5.1, from M6_LOS16_BRINGUP_STATE.md): the panel depends on
#   the individual handset.
#     unit REDACTED_UNIT (dead, deep discharge June 2026): ili9881p_hd_dsi_txd,
#       PLL 230->240;
#     unit REDACTED_UNIT (the live bench unit): ili9881c_hd_dsi_txd, TPS65132
#       bias, 201-entry init table and timings reverse-engineered out of the
#       stock Flyme 6.2.0.0RU kernel.
#   FACT: selection is by NAME from LK - disp_lcm_probe() does
#     strcmp(lcm_drv->name, plcm_name); compare_id is not in that path at all
#     (M6T_ROADMAP.md §2.1). And `videolfb-lcmname` in the DTB is NOT a reliable
#     identity: the stock M6 DTB carries nt35695_fhd_dsi_cmd_truly_nt50358_drv
#     while the runtime lights ili9881c (M6T_DUMP_ANALYSIS §3).
#   CONSEQUENCE, written here so it is not forgotten: this device tree cannot and
#   must not pin a panel. The kernel must compile BOTH ili9881c and ili9881p and
#   let LK choose. Any new M6 body requires reading the atag/expdb lcmname before
#   a first flash. The existing 4.4 port carries ili9881p, i.e. the DEAD unit's
#   panel - flashing it to REDACTED_UNIT is the documented way to reproduce the
#   25-second WDT cycle (factbase §5.3, INFERENCE).
# ---------------------------------------------------------------------------
TARGET_SCREEN_WIDTH := 720
TARGET_SCREEN_HEIGHT := 1280
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# ---------------------------------------------------------------------------
# Partitions - A-only, no slots, no dynamic partitions, no super.
#
# GROUND TRUTH = the stock MTK scatter on disk,
#   /srv/forge/android/meizu_m6/stock-flyme-7.1.2.0G/scatter.txt.
#   Sizes are the deltas between consecutive start offsets (FACT):
#     recovery 0x00008000 -> para     0x02008000  => 0x02000000 =   32 MiB
#     custom   0x02088000 -> expdb    0x22088000  => 0x20000000 =  512 MiB
#     expdb    0x22088000 -> frp      0x22a88000  => 0x00a00000 =   10 MiB
#     boot     0x2c300000 -> logo     0x2d300000  => 0x01000000 =   16 MiB
#     system   0x30800000 -> cache    0xd0800000  => 0xa0000000 = 2560 MiB
#     cache    0xd0800000 -> userdata 0xeb800000  => 0x1b000000 =  432 MiB
#   There is NO `vendor` entry in the stock scatter.
#
# FACT (independent cross-check): every one of those five numbers is already in
#   the common BoardConfig of the tree that builds the booting LOS 16.0 image
#   (device/meizu/m3_meizu_m6-common/BoardConfigCommon.mk):
#   boot 16777216, recovery 33554432, system 2684354560, cache 452984832.
#   Two artifacts, a factory scatter and a shipping ROM tree, same numbers.
#
# FACT (measured on hardware): boot = mmcblk0p21, 16 MiB
#   (meizu-fleet/factbase/mt6755_family.md §5.1, live unit REDACTED_UNIT).
#
# NOTE - M6 differs from m681 here, do not copy m681's numbers:
#   recovery is 32 MiB on M6 vs 16 MiB on m681, and every offset from `para`
#   onward is shifted, so the block-device NUMBERS differ too (boot is p21 here,
#   p22 on m681). See rootdir/etc/fstab.mt6755 for the full derivation.
#
# INFERENCE, not FACT: BOARD_USERDATAIMAGE_PARTITION_SIZE 11683216896 is carried
#   from the common BoardConfig. The scatter has no end offset for userdata. It
#   is inert - we do not build userdata.img.
# ---------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 131072

BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11683216896

# /vendor = the `custom` partition, mmcblk0p3, 512 MiB.
# FACT (live unit REDACTED_UNIT on stock Flyme 6.2.0.0RU, 2026-07-25,
#   meizu_m6/captures/m6cap-20260725-1305/03-partitions): /proc/partitions
#   `179 3 524288 mmcblk0p3` (524288 KiB = 536870912 B) and by-name
#   `custom -> /dev/block/mmcblk0p3`; the dead unit REDACTED_UNIT gives the same
#   two lines (captures/20260530-stock-lk-boot-reverse-inputs/). Stock scatter
#   delta above says the same 0x20000000.
# FACT: what stock keeps there is regional data only - 21 MB of language packs
#   and theme APKs plus /custom/{meizu,gms,media,.pre.config}, formatted and
#   refilled by the Flyme updater (stock-flyme-7.1.2.0G/META-INF/com/google/
#   android/updater-script:18-40). Nothing in the boot chain reads it; on the
#   sibling m681 the same p3 has been a real /vendor since 2026-08-24
#   (BRINGUP_STATE.md §1.1 item 5). Back it up before the first vendor.img flash.
# FACT: the vendor payload is 274 MiB of blobs (proprietary/, 735 files) plus
#   the AOSP HAL modules - well inside 512 MiB.
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

# ---------------------------------------------------------------------------
# Boot image geometry
#
# FACT - read directly out of the boot image that was ON THIS DEVICE before the
#   2026-08-06 flash, /srv/forge/android/gunwest-import/m6-flash-20260806/
#   boot-before-20260806.img (16 777 216 B, sha256 981d2812a9cb89ac... - the
#   same `981d2812…` recorded as the rollback image in
#   meizu-fleet/factbase/mt6755_family.md §5.3). Android boot header v0:
#     kernel_addr  0x40080000  => BOARD_KERNEL_BASE 0x40078000 (addr - 0x8000)
#     ramdisk_addr 0x45000000  => ramdisk_offset 0x04f88000
#     second_addr  0x40f78000  => second_offset  0x00f00000  (second_size = 0)
#     tags_addr    0x44000000  => tags_offset    0x03f88000
#     page_size    2048        name "1552631950"  header_version 0
#
# FACT (second artifact, identical header): the 2026-08-07 rollback image
#   m6-flash-20260806/boot-3.18-los16-rollback.img gives the same five values
#   and the same board name.
#
# FACT (third source): those exact mkbootimg arguments are in the tree that
#   built them - `--kernel_offset 0x00008000 --ramdisk_offset 0x04f88000
#   --tags_offset 0x03f88000 --board 1552631950` with
#   BOARD_KERNEL_BASE := 0x40078000 (m3_meizu_m6-common/BoardConfigCommon.mk).
#
# NOTE on second_offset: stock Flyme uses 0x00e88000 (second_addr 0x40f00000) -
#   header parse of stock-flyme-7.1.2.0G/boot.img, board "1554686824". The LOS16
#   builds use 0x00f00000. second_size is 0 in every one of them, so the field is
#   inert; the LOS16 value is used because that is the image that boots.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Kernel command line
#
# FACT: the exact cmdline of the images that boot this device (header parse of
#   boot-before-20260806.img and boot-3.18-los16-rollback.img):
#     bootopt=64S3,32N2,64N2 androidboot.selinux=permissive
#     binder.devices=binder,hwbinder,vndbinder buildvariant=userdebug
#   `binder.devices=` is load-bearing on 3.18: that kernel does have
#   CONFIG_ANDROID_BINDER_DEVICES (unlike m681's 4.4, where the symbol does not
#   exist in Kconfig at all - BRINGUP_STATE.md §1.1 item 3), and hwbinder is what
#   every HIDL service needs.
#
# ADDED here: androidboot.hardware=mt6755 and androidboot.usb.config=adb.
#   The first is belt and braces - FACT: the device already reports
#   [ro.boot.hardware]: [mt6755] without it, because the MTK kernel supplies it
#   from the atags (live capture, REDACTED_UNIT). Stating it explicitly is what
#   m681's LOS16 does and it is what names init.mt6755.rc and fstab.mt6755.
# ---------------------------------------------------------------------------
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.hardware=mt6755 androidboot.selinux=permissive binder.devices=binder,hwbinder,vndbinder androidboot.usb.config=adb buildvariant=userdebug

# ---------------------------------------------------------------------------
# Kernel - PREBUILT. This tree never compiles a kernel.
#
# 2026-09-25 19:10 - prebuilt/Image.gz-dtb is now the eBPF kernel of lane
#   kernel-ebpf-318: 7 787 096 B, sha256 cbe24adeb55bf30a861069325f047c4df7229e082f739deaa4edab3ba68abf47
#   (= meizu-fleet/artifacts/kernel-meizu_m6/Image.gz-dtb-ebpf-1cc05ed218a, checked against its SHA256SUMS),
#   3.18.140 #1 SMP PREEMPT Fri Sep 25 17:49:59 MSK 2026, source forge/meizu_m6-ebpf 1cc05ed218a
#   (meizu-fleet/wt/kernel_*_ebpf, meizu_m6_a13_defconfig; design
#   meizu-fleet/designs/KERNEL_EBPF_FLEET_20260925.md). FACT (that lane): the
#   real 3.18.140 verifier (UML) accepts all 19 critical LOS20 BPF programs.
#   1cc05ed218a (parent c7025096481) fixes fs/proc/dcheck_root.c: the Huawei
#   late_initcall opened /default.prop and checked filp only for NULL; the A13
#   ramdisk has no /default.prop, filp_open returns ERR_PTR(-ENOENT) -> panic
#   before init with an A13 ramdisk in EVERY earlier image, the LOS16 kernel
#   below included (an A9 ramdisk has /default.prop, which is why LOS16 boots).
#   First-boot check: dmesg | grep DEFAULT_PROP_FILE -> "OPEN FAIL!", no oops.
#   CONFIG_MTK_LCM_PHYSICAL_ROTATION_HW is unset and ROTATION="0", as in the
#   pinned LOS16 kernel below (the upright-UI lesson holds).
#   The paragraphs below describe the PREVIOUS prebuilt and are kept as history.
#
# HISTORY - the previous prebuilt/Image.gz-dtb was 7 740 671 B,
#   sha256 e70854445d07a4063af52df08aa53a35ae5a92676521fa0de42fed9f17f3b8ca.
#   THREE independent artifacts on this disk carry that exact hash:
#     1. gunwest-import/m6rom16/rom-work/device/meizu/meizu_m6/prebuilt-kernel/
#        Image.gz-dtb  (the source this file was copied from, 2026-09-16);
#     2. pages [2048, 2048+7740671) of m6-flash-20260806/boot-before-20260806.img
#        - the image that was on p21 of the live unit before the 08-06 flash;
#     3. the same pages of m6-flash-20260806/boot-3.18-los16-rollback.img.
# FACT: its gzip payload carries the banner
#   "Linux version 3.18.140 (n8n@n8nagent) (gcc version 4.9 20150123
#    (prerelease) (GCC)) #3 SMP PREEMPT Mon Aug 3 20:55:37 MSK 2026".
# FACT: this is the kernel of the currently working LineageOS 16.0 build on unit
#   REDACTED_UNIT - sys.boot_completed=1, HWC mt6755 enabled, Wi-Fi supplicant
#   running, BT state ON, mbackd running (factbase §5.2, measurement 2026-08-06).
#   It is, in other words, the ONLY kernel in this whole task that is known to
#   boot its device today.
#
# ROTATION, and why this kernel and not its predecessor. FACT, recorded in the
#   BoardConfig this was taken from and corrected on 2026-08-03: the earlier
#   prebuilt had CONFIG_MTK_LCM_PHYSICAL_ROTATION_HW=y, which is a real hardware
#   180 flip in the display path (ddp_ovl.c:603 + primary_display.c:5165 +
#   mtk_disp_mgr.c:1400) meant to compensate a 180-mounted panel. On THIS body it
#   CAUSED the upside-down UI rather than fixing it. The kernel pinned here has
#   _HW unset and CONFIG_MTK_LCM_PHYSICAL_ROTATION="0"; user-confirmed upright
#   2026-08-03. The predecessor is kept in that tree as
#   prebuilt-kernel/Image.gz-dtb.rot_hw_backup. Do not "restore" it.
#
# HONEST LABEL: Android 13 will NOT start on this kernel. It is 3.18: no
#   CONFIG_CGROUP_BPF, so bpfloader fails, so `reboot_on_failure reboot,
#   bpfloader-failed` turns the whole system into a reboot loop. The prebuilt is
#   here so the tree is self-consistent and `m nothing` is honest, NOT because
#   it boots A13. The real fix is the MT6755 4.19 campaign.
#
# 2026-09-25 (Treble report §3): sharper than the paragraph above. FACT:
#   meizu_m6_defconfig sets no CONFIG_BPF* at all and kernel/bpf/ has no
#   arraymap.c/hashtab.c, so bpf() is absent and bpfloader's own
#   createMap(BPF_MAP_TYPE_ARRAY) fails (system/bpf/bpfloader/BpfLoader.cpp:
#   202-208) -> exit 1 -> reboot. FACT: m95 boots A13 on 3.18.22 with a
#   backport series in meizu_mx6_m95/kernel/m685 (bff848dd bpffs/pinning/maps,
#   8a7d274c helpers/prog types/attach, ee0cebee + d3f29d6a fixes, cf625052
#   config, 71d371d4/9c36a785/a17f1228 apex+adbd, 65654a98 remount soft
#   lockup). Porting that series to this 3.18.140 source is the shortest path.
#   The cgroup-v2 gap is already handled in userspace (system/core branch
#   meizu-legacy-kernel 9476c48).
# Treble itself needs NO kernel change: FACT, the appended DTB of this prebuilt
#   has no firmware/android node (dtc), so first-stage init falls back to the
#   ramdisk fstab (ReadFirstStageFstab -> ReadDefaultFstab), and the kernel
#   emits PARTNAME (by-name links exist on this unit), which is what the by-name
#   first_stage_mount entries in rootdir/etc/fstab.mt6755 match against.
#
# The LOS kernel task takes the prebuilt branch only when KERNEL_SRC does not
# exist on disk (vendor/lineage/build/tasks/kernel.mk:127-148), so
# TARGET_KERNEL_SOURCE deliberately points at a path that is never synced.
# (Superseded 2026-09-25: the source exists now, TARGET_FORCE_PREBUILT_KERNEL
# below keeps the prebuilt.)
# The real source, for the record, is
#   /srv/forge/android/meizu_m6/kernel-meizu_M6-N-ex6-linux-3.18.140/kernel-3.18
#   (CORRECTION 2026-09-25: no such directory exists; the 3.18.140 source is
#   branch m6-linux-3.18.140 of /srv/forge/android/meizu_m6/kernel-meizu_M6-N-ex6)
#   with meizu_m6_defconfig (factbase §5.2: the ex6 tree, NOT kernel-meizu_M6-N-ex6,
#   whose defconfig says sunwave while the shipping binary is goodix).
# ---------------------------------------------------------------------------
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
