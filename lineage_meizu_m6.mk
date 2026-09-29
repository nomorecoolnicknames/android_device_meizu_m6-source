# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
# lineage_meizu_m6.mk - Meizu M6 (meizu_m6 / M711), MediaTek MT6750

# arm64 with a 32-bit second ABI. core_64_bit must come before the phone stack
# so core_minimal does not pin ro.zygote=zygote32.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Device configuration.
$(call inherit-product, device/meizu/meizu_m6/device.mk)

# LineageOS common phone stack.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Keep the established meizu_m6 product name and OTA assertions.
# Stock Flyme uses meizu_M6, but changing the custom-ROM name would break existing assertions.
PRODUCT_DEVICE := meizu_m6
PRODUCT_NAME := lineage_meizu_m6
PRODUCT_BRAND := Meizu
PRODUCT_MODEL := M6
PRODUCT_MANUFACTURER := Meizu

PRODUCT_GMS_CLIENTID_BASE := android-meizu

# The vendor ABI originates from Nougat (API 24).
# Select Treble and VNDK explicitly rather than changing the shipping API to the build SDK.
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
