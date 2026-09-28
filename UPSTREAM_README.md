# android_device_meizu_meizu_m6
Device repository for Meizu M6 (CyanogenMod)

Install
-----------

1. Clone https://github.com/washinson/android_device_meizu_m3_meizu_m6-common/tree/cm12.1 into **device/meizu/m3_meizu_m6-common**

2. Apply patches

```
cd device/meizu/m3_meizu_m6-common/patches
bash apply.sh
``` 

3. Compile

```
. build/envsetup.sh
lunch cm_meizu_m6-userdebug
mka bacon
```

# Changelog:
## v0.8.3
Many changes
- USB
- charge only
- MTP default
- A2DP fix
- Tethering fix
- VPN fix
- etc

## v0.7
- Ril fix
- Bug fixing

## v0.6
- Home wakeup
- Long home menu

## v0.5
- Camera Fix

## v0.4
- Dualsim support
- Added media codecs

## v0.3
- Ril fixed (Only 1 sim, 2 sim will added in next release)

## v0.2
- Full rebase device tree
