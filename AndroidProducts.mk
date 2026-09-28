# Pie (Android 9) derives the product NAME from the basename of a path-only
# PRODUCT_MAKEFILES entry, NOT from PRODUCT_NAME inside. lineage.mk basename is
# "lineage", so use the explicit name:path form to keep the authoritative
# lineage.mk while presenting it under the product name lineage_meizu_m6.
PRODUCT_MAKEFILES := \
    lineage_meizu_m6:$(LOCAL_DIR)/lineage.mk

COMMON_LUNCH_CHOICES := \
    lineage_meizu_m6-userdebug \
    lineage_meizu_m6-eng
