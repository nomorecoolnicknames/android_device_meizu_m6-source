# Meizu M6

**LineageOS 18.1 · Android 11 · ARM64**

Device configuration and compatibility code maintained by [ReMeizu](https://github.com/nomorecoolnicknames/remeizu).

| Target | Configuration |
| --- | --- |
| Product | `lineage_meizu_m6-userdebug` |
| Device path | `device/meizu/meizu_m6` |
| Platform | MT6750 |
| Display | 720 × 1280 |
| Kernel route | 3.18 prebuilt; eBPF compatibility configuration |

## Status

The Treble product, vendor layout and compatibility configuration are present. A complete ROM and hardware run for this branch are not yet verified. Older Android/kernel results are not treated as tests of this configuration.

**Source available** means the listed implementation or configuration is in this repository. **External** means it also needs the matching platform, kernel or vendor inputs. **Untested** means there is no functional test for this branch.

## Components

| Subsystem | Implementation / source | Availability | Working status |
| --- | --- | --- | --- |
| Boot / storage | [BoardConfig.mk](BoardConfig.mk) · [rootdir/etc/fstab.mt6755](rootdir/etc/fstab.mt6755) | Config; kernel image external | Current kernel route untested |
| Display / touch | [shims/region.cpp](shims/region.cpp) · [overlay](overlay) · MTK HWC/Mali blobs | Config; Region ABI adapter source; kernel drivers external | Untested with this kernel/ROM configuration |
| Wi-Fi | [wifi](wifi) · [device.mk](device.mk) | Configuration; HAL/firmware external | Untested |
| Bluetooth | [device.mk](device.mk) · stock MTK transport | Config; controller firmware/vendor transport external | Untested |
| SIM / LTE / calls | [device.mk](device.mk) · [proprietary-files.txt](proprietary-files.txt) | RIL service configuration; modem and MTK vendor ABI external | Untested; board-specific modem inputs required |
| Camera | [device.mk](device.mk) · [proprietary-files.txt](proprietary-files.txt) | Provider configuration; camera HAL and calibration external | Untested; calibration and vendor ABI remain board-specific |
| Audio | [device.mk](device.mk) · [proprietary-files.txt](proprietary-files.txt) | MTK audio service/configuration; primary HAL external | Untested on this branch |
| Sensors | [rootdir/etc/init/init.meizu_m6.sensors.rc](rootdir/etc/init/init.meizu_m6.sensors.rc) | Init/HAL configuration; board sensor drivers external | Untested |
| Fingerprint | [device.mk](device.mk) · [proprietary-files.txt](proprietary-files.txt) | Service/TEE configuration; fingerprint HAL external | Untested |
| GPS | [proprietary-files.txt](proprietary-files.txt) | Configuration/vendor inputs; GNSS stack external | Location fix unverified |
| Power / USB / SELinux | [BoardConfig.mk](BoardConfig.mk) · [sepolicy](sepolicy) | Kernel/HAL configuration and policy | Functional testing and enforcing policy pending |

## Build

Use a matching LineageOS 18.1 source tree and place this checkout at `device/meizu/meizu_m6`. Provide these inputs before running lunch:

| Input | Location / requirement |
| --- | --- |
| Platform compatibility | Matching legacy MediaTek framework/HAL adaptations; this device tree alone is not the platform |
| Vendor inputs | `device/meizu/meizu_m6/proprietary/`, using the paths in `vendor-blobs.mk` |
| Kernel source / headers | `kernel/meizu/meizu_m6` |
| Kernel image | `device/meizu/meizu_m6/prebuilt/Image.gz-dtb`; use the matching board kernel and DTB |

```sh
source build/envsetup.sh
lunch lineage_meizu_m6-userdebug
m -j4 bacon
```

## Next steps

- Test the current camera compatibility changes through preview, capture and close/reopen.
- Verify SIM/calls/data, Wi-Fi association, Bluetooth pairing, charging and suspend.

The [ReMeizu overview](https://github.com/nomorecoolnicknames/remeizu/blob/main/PROJECT_STATUS.md) tracks the broader project; the [source index](https://github.com/nomorecoolnicknames/remeizu/blob/main/SOURCE_INDEX.md) links device, common and kernel trees.

## Credits

LineageOS and CyanogenMod contributors, the original device-tree authors, and ReMeizu contributors. Copyright and license notices remain with their source files.
