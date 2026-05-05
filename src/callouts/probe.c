/* Self-test fixture for tools/build-callouts.sh.
 *
 * This file is *not* a real Phase 3 callout — it's a one-symbol shim that
 * lets the build script verify the toolchain works on a host before any
 * STDHTTP / STDCRYPTO / STDCOMPRESS C source lands. Running
 *
 *     tools/build-callouts.sh
 *
 * on a clean checkout should produce so/<platform>/probe.<so|dylib> and
 * print a green `ok` line. The compiled output is gitignored.
 *
 * When real callouts arrive, this file stays put — it remains the smallest
 * possible reproduction of "the build path works" and is useful for
 * bisecting platform regressions.
 */
int probe_smoke(void) { return 42; }
