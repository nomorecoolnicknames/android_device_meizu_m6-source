// libskia (stub) — DT_NEEDED placebo for M6 Nougat camera blobs on LOS 16.0.
//
// Android P merged skia into libhwui (external/skia/Android.bp declares it
// cc_library_static); there is no /system/lib{,64}/libskia.so on a Pie image.
// The Flyme libcam.camadapter.so still carries DT_NEEDED [libskia.so], and a
// missing NEEDED library fails the whole load:
//   MtkCam/devicemgr: dlopen libcam_platform.so ->
//     dlopen failed: library "libskia.so" not found ->
//   [openDeviceLocked] No Platform ->
//   CameraClient initialize: -38 -> every camera open fails
// (M6 REDACTED_UNIT live logcat, 2026-08-03; framework enumerates 2 cameras
// fine — only open is broken.)
//
// readelf/nm FACT (2026-08-03): libcam.camadapter.so imports ZERO Sk* symbols
// in both ABIs — the dependency is linker cruft, so an empty library satisfies
// it at zero ABI risk. Shipping the real stock libskia.so instead would drag
// in libtiff.so plus four MTK-patched libpng exports (png_build_index etc.)
// that Pie's libpng does not have — a chain, not a fix.
//
// libaal.so (13 Sk imports) and libvtmal.so (18) genuinely call Skia and are
// NOT rescued by this stub; faking N-era Sk* object layouts would be memory
// corruption, not a shim. Same analysis and resolution as the m95 port
// (device/meizu/m95/BLOB_SHIMS.md, device/meizu/m95/shims/).
extern "C" void __m6_libskia_stub_marker(void) {}
