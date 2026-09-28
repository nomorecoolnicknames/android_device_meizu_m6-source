// N-ABI android::GraphicBuffer constructor for the MediaTek Nougat blobs of this set
// (lane treble-m6-m6t, 2026-09-25; not part of the m95 shims - m95's libui_ext is a newer
// build that already calls the std::string constructor).
//
// FACT (nm -D): libui_ext (GraphicBufferUtil::downSampleCopy, in hwcomposer's closure) and 12
// camera/OMX blobs import the Nougat constructor
//   GraphicBuffer(uint32_t w, uint32_t h, PixelFormat format, uint32_t usage)
//   = _ZN7android13GraphicBufferC1Ejjij,
// which A13 libui no longer exports. A13 keeps the same constructor with a trailing
// std::string requestorName (frameworks/native/libs/ui/include/ui/GraphicBuffer.h:143, exported as
// _ZN7android13GraphicBufferC1EjjijNSt3__112basic_string...), so this forwards with
// "<Unknown>", the header's default.
//
// The object is the caller's: `new` in the blob sizes it for Nougat - 232 bytes on arm64,
// 136 on arm32 - while the A13 constructor writes 256 / 160 (FACT: operator new before
// GraphicBuffer() in A13 libgui). The difference is the tail vector mDeathCallbacks, so an
// unpatched caller loses 24 bytes of heap. Callers are byte-patched at import time to allocate
// the A13 size (shims/bytepatch.txt, meizu-fleet/tools/treble-gbuf-sites.py). A caller that
// was not patched aborts here with its return address instead of corrupting the heap:
// malloc_usable_size() of scudo is the requested size, of jemalloc the size class - in both
// cases "at least the A13 size" means the constructor stays inside the allocation.
//
// ABI: std::string is not trivially copyable, so the Itanium C++ ABI passes it by reference to
// a temporary the caller owns and destroys - declared here as a pointer, like the other
// manual declarations in ui.cpp.
#include <malloc.h>
#include <stdint.h>

#include <string>

#include <log/log.h>

namespace {
constexpr size_t kA13GraphicBufferSize = sizeof(void*) == 8 ? 256 : 160;
}

extern "C" {

void _ZN7android13GraphicBufferC1EjjijNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(
        void* self, uint32_t w, uint32_t h, int32_t format, uint32_t usage, std::string* requestorName);

void _ZN7android13GraphicBufferC1Ejjij(void* self, uint32_t w, uint32_t h, int32_t format,
                                       uint32_t usage) {
    size_t have = malloc_usable_size(self);
    if (have < kA13GraphicBufferSize) {
        LOG_ALWAYS_FATAL("N GraphicBuffer(%u, %u, %d, %#x) on a %zu-byte object (caller %p): A13 "
                         "needs %zu - byte-patch the caller's operator new (shims/bytepatch.txt)",
                         w, h, format, usage, have, __builtin_return_address(0),
                         kA13GraphicBufferSize);
    }
    std::string name("<Unknown>");
    _ZN7android13GraphicBufferC1EjjijNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE(
            self, w, h, format, usage, &name);
}

}  // extern "C"
