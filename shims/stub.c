/* Empty body for the forwarder libraries in Android.bp: their only content is
 * DT_NEEDED on the real library (Soong links without --as-needed, so the entry
 * survives). One exported marker keeps the object non-empty. */
void __meizu_m6_fwd_marker(void) {}
