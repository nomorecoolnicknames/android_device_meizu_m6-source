# Meizu M6

**LineageOS 16.0 · Android 9 · ARM64**

Device configuration and compatibility code maintained by [ReMeizu](https://github.com/nomorecoolnicknames/remeizu).

| Target | Configuration |
| --- | --- |
| Product | `lineage_meizu_m6-userdebug` |
| Device path | `device/meizu/meizu_m6` |
| Platform | MT6750 |
| Display | 720 × 1280 |
| Kernel route | 3.18 prebuilt; optional source build |

## Status

An earlier LOS16 build booted on M6 on 2026-08-06 with working display/HWC and ADB. Wi-Fi scanning and Bluetooth startup were observed; camera and telephony were incomplete. This branch includes later changes whose complete ROM has not been tested on hardware.

**Source available** means the listed implementation or configuration is in this repository. **External** means it also needs the matching platform, kernel or vendor inputs. **Untested** means there is no functional test for this branch.

## Components

| Subsystem | Implementation / source | Availability | Working status |
| --- | --- | --- | --- |
| Boot / storage | [BoardConfig.mk](BoardConfig.mk) · inherited common init/fstab | Config; kernel image external | Earlier LOS16 boot; current changes untested |
| Display / touch | [overlay](overlay) · [device_meizu_m6.mk](device_meizu_m6.mk) · external MTK HWC/Mali stack | Config; kernel drivers external | Earlier LOS16 display/HWC worked; current changes untested |
| Wi-Fi | [wifi](wifi) · [device_meizu_m6.mk](device_meizu_m6.mk) | Configuration; HAL/firmware external | Earlier LOS16 scanned networks; association unverified |
| Bluetooth | [bluetooth](bluetooth) · stock MTK transport | Config; controller firmware/vendor transport external | Earlier LOS16 enabled; pairing/audio unverified |
| SIM / LTE / calls | [rild-mtk-hidl.rc](rild-mtk-hidl.rc) | RIL service configuration; modem and MTK vendor ABI external | Calls/data not verified; earlier LOS16 reported no service |
| Camera | [camera_compat](camera_compat) | GLConsumer/TSF compatibility source; camera HAL external | Earlier provider crash; later compatibility changes untested |
| Audio | [device_meizu_m6.mk](device_meizu_m6.mk) · [proprietary-files.txt](proprietary-files.txt) | MTK audio service/configuration; primary HAL external | Untested on this branch |
| Sensors | [device_meizu_m6.mk](device_meizu_m6.mk) · [proprietary-files.txt](proprietary-files.txt) | Init/HAL configuration; board sensor drivers external | Untested |
| Fingerprint | [init.fingerprint.rc](init.fingerprint.rc) | Service/TEE configuration; fingerprint HAL external | Earlier daemon startup only; enrollment/unlock unverified |
| GPS | [gps.conf](gps.conf) | Configuration/vendor inputs; GNSS stack external | Location fix unverified |
| Power / USB / SELinux | [BoardConfig.mk](BoardConfig.mk) | Kernel/HAL configuration and policy | Earlier ADB worked; suspend/charging/enforcing unverified |

## Build

Use a matching LineageOS 16.0 source tree and place this checkout at `device/meizu/meizu_m6`. LOS16 uses JDK 8. Provide these inputs before running lunch:

| Input | Location / requirement |
| --- | --- |
| Common device tree | `device/meizu/m3_meizu_m6-common` |
| MTK RIL/HAL integration | Matching `vendor/mediatek` sources, including MTK telephony headers |
| Vendor inputs | Prepared `vendor/meizu/meizu_m6` tree matching this device and branch |
| Kernel source / headers | `kernel/meizu/meizu_m6/kernel-3.18` |
| Kernel image | `device/meizu/meizu_m6/prebuilt-kernel/Image.gz-dtb`; use the matching board kernel and DTB |

```sh
source build/envsetup.sh
lunch lineage_meizu_m6-userdebug
m -j4 bacon
```

For the optional kernel source route, set `M6_KERNEL_FROM_SOURCE=true` and `M6_KERNEL_CROSS_COMPILE_PREFIX` to an absolute AArch64 GCC 4.9 prefix ending in `aarch64-linux-android-`. The selected source/configuration remain `kernel/meizu/meizu_m6/kernel-3.18` and `meizu_m6_defconfig`.

## Next steps

- Test the current camera compatibility changes through preview, capture and close/reopen.
- Verify SIM/calls/data, Wi-Fi association, Bluetooth pairing, charging and suspend.

The [ReMeizu overview](https://github.com/nomorecoolnicknames/remeizu/blob/main/PROJECT_STATUS.md) tracks the broader project; the [source index](https://github.com/nomorecoolnicknames/remeizu/blob/main/SOURCE_INDEX.md) links device, common and kernel trees.

## Credits

LineageOS and CyanogenMod contributors, the original device-tree authors, and ReMeizu contributors. Historical upstream build notes and links are retained in [UPSTREAM_README.md](UPSTREAM_README.md). Copyright and license notices remain with their source files.
