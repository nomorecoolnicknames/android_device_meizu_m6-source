# Meizu M6: LineageOS 16.0

Device configuration, init rules, policy and compatibility code.
Place at `device/meizu/meizu_m6` in the matching LineageOS source tree.
Provide the referenced common/MediaTek trees, matching kernel source or prebuilt,
and board-specific vendor inputs from `proprietary-files.txt` and dependency manifests.
Keep the included kernel/input checksum checks enabled.
Select `lunch lineage_meizu_m6-userdebug`.

The default kernel route uses a prebuilt. Source builds use `M6_KERNEL_FROM_SOURCE=true`
and require an absolute `M6_KERNEL_CROSS_COMPILE_PREFIX` for AArch64 GCC 4.9.
