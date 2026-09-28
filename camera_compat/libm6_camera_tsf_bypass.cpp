// libm6_camera_tsf_bypass.so — AndroidForge M6 camera bring-up shim (LD_PRELOAD).
//
// Root cause (BRINGUP_STATE.md 2026-06-13 КАМЕРА): camera TSF/LSC calibration
// NVRAM is absent on this port (CAMERA_TSF missing, readRamVersion all 0). The MTK
// ISP online lens-shading TSF runs with a NULL calibration table and NULL-derefs,
// killing the camera HAL host (mediaserver) ~1.5s into preview.
//
// libcamalgo is built without -Bsymbolic, so its intra/inter-lib calls go through
// the PLT and LD_PRELOAD preempts them (verified: stubbing the Shading_TSF leaf
// moved the SIGSEGV up from TsfCore::Shading_TSF_int_gain to TsfCore::TsfCoreProcess
// — same missing-table problem hit at multiple points inside the TSF core). We
// therefore stub the whole online-TSF subtree at TsfCore::TsfCoreProcess(); after it
// returns, AppTsf::TsfMain() only runs its epilogue (no further table deref), so the
// crash is eliminated. Camera previews/captures without TSF lens-shading refinement.
//
// Mangled members of the stock blob (libcamalgo.so):
//   TsfCore::TsfCoreProcess()                              _ZN7TsfCore14TsfCoreProcessEv
//   TsfCore::Shading_TSF_int_gain(void*,int,int,int*,int*) _ZN7TsfCore20Shading_TSF_int_gainEPviiPiS1_
//   isEnableTSF(int)                                       _Z11isEnableTSFi

extern "C" {

// TsfCore::TsfCoreProcess() — stub the entire per-frame TSF core. x0=this.
int _ZN7TsfCore14TsfCoreProcessEv(void* /*thiz*/) { return 0; }

// TsfCore::Shading_TSF_int_gain(...) — kept as a defensive neutral-gain stub in
// case any other path reaches it. x0=this,x1=void*,x2/x3=int,x4/x5=int* outputs.
int _ZN7TsfCore20Shading_TSF_int_gainEPviiPiS1_(
        void* /*thiz*/, void* /*a1*/, int /*a2*/, int /*a3*/, int* o1, int* o2)
{ if (o1) *o1 = 1024; if (o2) *o2 = 1024; return 0; }

int _Z11isEnableTSFi(int /*sensorId*/) { return 0; }

}
