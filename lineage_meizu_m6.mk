#
# lineage_meizu_m6.mk - Meizu M6 (meizu_m6 / M711), MediaTek MT6750
# LineageOS 20 (Android 13)
#
# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Companion report: /srv/forge/android/meizu-fleet/trees/M6_LOS20_TREE.md
#

# arm64 with a 32-bit second ABI. core_64_bit must come before the phone stack
# so core_minimal does not pin ro.zygote=zygote32.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Device configuration.
$(call inherit-product, device/meizu/meizu_m6/device.mk)

# LineageOS common phone stack.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# ---------------------------------------------------------------------------
# Identity - codename `meizu_m6`, taken from the existing device tree, not
# invented.
#
# FACT: every product makefile of the existing tree sets PRODUCT_DEVICE :=
#   meizu_m6 - meizu_m6/android_device_meizu_m6/cm_meizu_m6.mk:6 and :53
#   (product cm_meizu_m6, the LOS 15.1 lane) and
#   gunwest-import/m6rom16/rom-work/device/meizu/meizu_m6/lineage_meizu_m6.mk:23
#   (product lineage_meizu_m6, the LOS 16.0 lane that boots the live unit).
#   Its AndroidProducts.mk COMMON_LUNCH_CHOICES matches.
# FACT: BOARD_NAME := meizu_m6 and TARGET_OTA_ASSERT_DEVICE := meizu_m6 in that
#   tree's BoardConfig.mk.
#
# NOTE the deliberate mismatch with the factory string: stock Flyme reports
#   [ro.product.device]: [meizu_M6] (capital M), measured on unit REDACTED_UNIT
#   in captures/20260620-121905-m6-STOCK-flyme-harvest-.../10-getprop.txt, and
#   /srv/forge/android/meizu_m6/stock-flyme-7.1.2.0G/META-INF/build.prop agrees
#   (ro.product.device=meizu_M6, ro.product.model=MEIZU M6). The project's trees
#   have used the lowercase `meizu_m6` since the 15.1 lane; changing it now would
#   orphan every recovery/OTA assert already flashed on the live unit. Kept.
# ---------------------------------------------------------------------------
PRODUCT_DEVICE := meizu_m6
PRODUCT_NAME := lineage_meizu_m6
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := M6
PRODUCT_MANUFACTURER := Meizu

PRODUCT_GMS_CLIENTID_BASE := android-meizu

# ---------------------------------------------------------------------------
# Shipping API level - the single most load-bearing line in this file.
#
# FACT: the stock firmware this device's whole blob set comes from is Nougat.
#   /srv/forge/android/meizu_m6/stock-flyme-7.1.2.0G/META-INF/build.prop:
#     ro.build.version.sdk=24
#     ro.build.version.release=7.0
#     ro.build.id=NRD90M
#     ro.product.first_api_level=24
#     ro.build.fingerprint=Meizu/meizu_M6/meizu_M6:7.0/NRD90M/1553585720:user/release-keys
#   (the package is named "Flyme 7.1.2.0G" but the platform inside it is 7.0.)
# FACT: confirmed live on hardware - the stock harvest from unit REDACTED_UNIT
#   reports [ro.build.description]: [meizu_M6-user 7.0 NRD90M 1553585720
#   release-keys] and [sys.boot_completed]: [1].
#
# (Until 2026-09-24 the paragraph below was the whole story. Treble is now
# forced on by the override further down; everything else it lists still
# follows the level 24.)
# Declaring 24 is what turns OFF, by the build system's own rules and not by an
# override flag: PRODUCT_FULL_TREBLE (needs >= 26, build/make/core/config.mk:
# 668-676), PRODUCT_USE_VNDK / BOARD_VNDK_VERSION (needs > 27 AND full treble,
# config.mk:721-736), PRODUCT_TREBLE_LINKER_NAMESPACES / PRODUCT_SEPOLICY_SPLIT
# / PRODUCT_ENFORCE_VINTF_MANIFEST (config.mk:683-695),
# PRODUCT_ENFORCE_PRODUCT_PARTITION_INTERFACE (> 29),
# PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS (>= 29),
# PRODUCT_SET_DEBUGFS_RESTRICTIONS (>= 31).
#
# This is not a guess for M6 - it is what the lane already concluded. FACT:
#   gunwest-import/m6rom16/rom-work/device/meizu/meizu_m6/ld.config.meizu_m6.txt:3-4
#   states, in the file that actually shipped in the booting LOS 16.0 build,
#   "Base: system/core/rootdir/etc/ld.config.legacy.txt (PRODUCT_FULL_TREBLE=false,
#    BOARD_VNDK_VERSION not set)".
# ---------------------------------------------------------------------------
PRODUCT_SHIPPING_API_LEVEL := 24

# FULL TREBLE, forced (owner directive 2026-09-24; m95 does the same from
# BoardConfig.mk). The shipping level above stays the honest 24 - raising it to
# 26+ would claim a launch that never happened and switch on the requirement
# set of a newer launch (ro.product.first_api_level, VNDK/VINTF strictness).
# build/make/core/config.mk:668-676 takes the override before looking at the
# level; LINKER_NAMESPACES, SEPOLICY_SPLIT and ENFORCE_VINTF_MANIFEST follow
# (config.mk:678-694). The rest of the switch is in BoardConfig.mk ("Treble /
# VNDK") and the reasoning in meizu-fleet/designs/TREBLE_M6_M6T_20260924.md.
PRODUCT_FULL_TREBLE_OVERRIDE := true

PRODUCT_CHARACTERISTICS := phone

# FACT: 720x1280 panel (BoardConfig.mk).
TARGET_BOOT_ANIMATION_RES := 720

# FACT: copied verbatim from the stock Flyme build.prop cited above.
PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=meizu_M6 \
    PRIVATE_BUILD_DESC="meizu_M6-user 7.0 NRD90M 1553585720 release-keys"

BUILD_FINGERPRINT := Meizu/meizu_M6/meizu_M6:7.0/NRD90M/1553585720:user/release-keys

# ---------------------------------------------------------------------------
# Dual SIM. FACT: the existing tree's system.prop declares
#   ro.telephony.sim.count=2, persist.radio.multisim.config=dsds
#   (android_device_meizu_m6/system.prop), and the live unit runs with two
#   modems (ro.mtk_enable_md1=1 / ro.mtk_enable_md3=1).
# Declared here rather than in system.prop because on A13 the multisim config is
# read from the product property namespace.
# ---------------------------------------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    persist.radio.multisim.config=dsds \
    ro.telephony.default_network=10,10
