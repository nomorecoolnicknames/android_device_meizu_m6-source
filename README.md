# Meizu M6: LineageOS 16.0

Device configuration, init rules, SELinux policy and compatibility code for Android 9.
Place this tree at `device/meizu/meizu_m6` in the matching LineageOS source tree.

The build requires the referenced common and MediaTek platform trees, matching kernel
source/headers and prebuilt image where selected, and this board’s proprietary inputs.
Use `proprietary-files.txt`, dependency manifests and kernel checks provided by this branch.
Prebuilt firmware and complete ROM images are not supplied by this repository.

After providing those inputs, select `lunch lineage_meizu_m6-userdebug`.
These sources remain under development; compiling them does not certify all hardware
or establish a tested installable release.

Retain the copyright and license notices in individual files.

The default kernel route uses a prebuilt. Source builds use `M6_KERNEL_FROM_SOURCE=true`
and require an absolute `M6_KERNEL_CROSS_COMPILE_PREFIX` for AArch64 GCC 4.9.
