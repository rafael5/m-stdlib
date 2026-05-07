/*
 * cs_random.c — m-stdlib Phase 3 cryptographic-random callout (track T12).
 *
 * Backend: Linux getrandom(2) — same kernel ChaCha20 CSPRNG that backs
 * /dev/urandom, but reachable via syscall (no fd churn, no record-
 * terminator dance, batched reads). Single entry point:
 *
 *   cs_random(n, out)  -> 0 ok | -2 syscall failure | -3 buffer too small
 *
 *   n   : ydb_int_t  — number of random bytes requested.
 *   out : ydb_string_t* — caller-allocated buffer; out->length is the
 *         M-side capacity. The C side fills exactly n bytes (looping over
 *         getrandom(2) since the syscall caps at 256 bytes per call when
 *         interrupted) and updates out->length to n on return.
 *
 * Build:
 *   tools/build-callouts.sh             # produces so/<plat>/cs_random.so
 * Loading:
 *   tools/std_csprng.xc                 # YDB call-out descriptor
 *   export STDLIB_LIB=<abs-path-to-so/<plat>>
 *   export ydb_xc_std_csprng=<abs-path>/tools/std_csprng.xc
 *
 * The /dev/urandom backend in STDCSPRNG.m stays in place as a soft-fall-
 * back: when ydb_xc_std_csprng is unset (or this .so is missing), the
 * pure-M `bytes()` reads bytes from the device one at a time. Same
 * kernel pool, same security guarantees — only the I/O cost differs.
 *
 * Status codes:
 *    0 = ok (out filled with n bytes)
 *   -2 = getrandom(2) failed (errno preserved by the kernel; out
 *        contents are undefined and out->length is set to 0)
 *   -3 = caller-provided output buffer too small for n bytes
 */

#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <sys/random.h>
#include "libyottadb.h"

int cs_random(ydb_int_t n, ydb_string_t *out)
{
    unsigned char *buf;
    size_t got = 0;
    ssize_t r;

    if (out == NULL || out->address == NULL) return -3;
    if (n < 0) return -3;
    if ((unsigned long)n > (unsigned long)out->length) return -3;

    if (n == 0) {
        out->length = 0;
        return 0;
    }

    buf = (unsigned char *)out->address;
    while (got < (size_t)n) {
        r = getrandom(buf + got, (size_t)n - got, 0);
        if (r < 0) {
            if (errno == EINTR) continue;
            out->length = 0;
            return -2;
        }
        got += (size_t)r;
    }

    out->length = (unsigned long)n;
    return 0;
}
