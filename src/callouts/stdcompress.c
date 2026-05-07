// link: -lz -lzstd
/* m-stdlib STDCOMPRESS — libz + libzstd glue for YDB external calls.
 *
 * One C entry per public M extrinsic. All entries share the same shape:
 *
 *   ydb_long_t stdcompress_X(ydb_string_t *in, ydb_string_t *out, ...);
 *
 * `in->address` / `in->length` is the input byte buffer. `out->address` is
 * a YDB-allocated buffer whose capacity comes from the .xc-declared
 * [STDCOMPRESS_OUT_BUFSIZE] qualifier; the callee writes up to that many
 * bytes and sets `out->length` to the actual bytes written. Returns 1 on
 * success, 0 on failure (caller reads stdcompress_lasterror() for detail).
 *
 * Last-error reporting: a single 1-KB process-static buffer holds the most
 * recent error message. The buffer is cleared at the start of every public
 * call and populated on failure. M reads it via stdcompress_lasterror().
 *
 * Thread safety: YDB's MUMPS process model is single-threaded per process;
 * the static buffer is fine. If a future host-call entrypoint becomes
 * multi-threaded, switch to __thread storage class.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <zlib.h>
#include <zstd.h>

/* YDB's libyottadb.h is the source of truth for ydb_string_t / ydb_long_t.
 * If unavailable at compile time (host without YDB installed), tools/build-
 * callouts.sh's ydb_include_flag() drops the -I flag and we fall back to
 * the inline declarations below. The on-disk ABI matches what YDB ships. */
#if defined(__has_include)
#  if __has_include(<libyottadb.h>)
#    include <libyottadb.h>
#    define HAVE_LIBYOTTADB_H 1
#  endif
#endif

#ifndef HAVE_LIBYOTTADB_H
typedef struct {
    unsigned int length;
    char *address;
} ydb_string_t;
typedef long ydb_long_t;
#endif

#define STDCOMPRESS_OUT_BUFSIZE (1 * 1024 * 1024)
#define STDCOMPRESS_ERR_BUFSIZE 1024

static char g_lasterr[STDCOMPRESS_ERR_BUFSIZE];

static void clear_err(void) {
    g_lasterr[0] = '\0';
}

static void set_err(const char *msg) {
    if (!msg) { g_lasterr[0] = '\0'; return; }
    size_t n = strlen(msg);
    if (n >= STDCOMPRESS_ERR_BUFSIZE) n = STDCOMPRESS_ERR_BUFSIZE - 1;
    memcpy(g_lasterr, msg, n);
    g_lasterr[n] = '\0';
}

static void set_err_libz(const char *prefix, int rc) {
    char buf[STDCOMPRESS_ERR_BUFSIZE];
    const char *zmsg = zError(rc);
    if (!zmsg) zmsg = "unknown";
    snprintf(buf, sizeof(buf), "%s%s", prefix, zmsg);
    set_err(buf);
}

static void set_err_libzstd(const char *prefix, size_t rc) {
    char buf[STDCOMPRESS_ERR_BUFSIZE];
    const char *zmsg = ZSTD_getErrorName(rc);
    if (!zmsg) zmsg = "unknown";
    snprintf(buf, sizeof(buf), "%s%s", prefix, zmsg);
    set_err(buf);
}

/* ---------- availability ---------- */

ydb_long_t stdcompress_available_libz(int argc) {
    (void)argc;
    /* zlibVersion() is a libz-resident symbol; if dlopen succeeded we can
     * call it. Returns the linked version string; non-null = available. */
    return zlibVersion() != NULL ? 1 : 0;
}

ydb_long_t stdcompress_available_libzstd(int argc) {
    (void)argc;
    return ZSTD_versionNumber() > 0 ? 1 : 0;
}

/* ---------- libz gzip / deflate ---------- */

static ydb_long_t libz_compress_with_window(ydb_string_t *in, ydb_string_t *out,
                                            ydb_long_t level, int windowBits) {
    clear_err();

    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    int rc = deflateInit2(&zs, (int)level, Z_DEFLATED, windowBits,
                          /*memLevel=*/8, Z_DEFAULT_STRATEGY);
    if (rc != Z_OK) {
        set_err_libz(",U-STDCOMPRESS-LIBZ-", rc);
        return 0;
    }

    zs.next_in = (Bytef *)in->address;
    zs.avail_in = in->length;
    zs.next_out = (Bytef *)out->address;
    zs.avail_out = STDCOMPRESS_OUT_BUFSIZE;

    rc = deflate(&zs, Z_FINISH);
    if (rc != Z_STREAM_END) {
        deflateEnd(&zs);
        set_err_libz(",U-STDCOMPRESS-LIBZ-", rc == Z_OK ? Z_BUF_ERROR : rc);
        return 0;
    }

    out->length = (unsigned int)zs.total_out;
    deflateEnd(&zs);
    return 1;
}

static ydb_long_t libz_decompress_with_window(ydb_string_t *in, ydb_string_t *out,
                                              int windowBits) {
    clear_err();

    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    int rc = inflateInit2(&zs, windowBits);
    if (rc != Z_OK) {
        set_err_libz(",U-STDCOMPRESS-LIBZ-", rc);
        return 0;
    }

    zs.next_in = (Bytef *)in->address;
    zs.avail_in = in->length;
    zs.next_out = (Bytef *)out->address;
    zs.avail_out = STDCOMPRESS_OUT_BUFSIZE;

    rc = inflate(&zs, Z_FINISH);
    if (rc != Z_STREAM_END) {
        inflateEnd(&zs);
        set_err_libz(",U-STDCOMPRESS-LIBZ-", rc == Z_OK ? Z_BUF_ERROR : rc);
        return 0;
    }

    out->length = (unsigned int)zs.total_out;
    inflateEnd(&zs);
    return 1;
}

ydb_long_t stdcompress_gzip(int argc, ydb_string_t *in, ydb_string_t *out, ydb_long_t level) {
    if (argc != 3) return 0;
    /* windowBits = 15 + 16 selects gzip framing per zlib.h. */
    return libz_compress_with_window(in, out, level, 15 + 16);
}

ydb_long_t stdcompress_gunzip(int argc, ydb_string_t *in, ydb_string_t *out) {
    if (argc != 2) return 0;
    return libz_decompress_with_window(in, out, 15 + 16);
}

ydb_long_t stdcompress_deflate(int argc, ydb_string_t *in, ydb_string_t *out, ydb_long_t level) {
    if (argc != 3) return 0;
    /* windowBits = -15 selects raw deflate (no header / trailer). */
    return libz_compress_with_window(in, out, level, -15);
}

ydb_long_t stdcompress_inflate(int argc, ydb_string_t *in, ydb_string_t *out) {
    if (argc != 2) return 0;
    return libz_decompress_with_window(in, out, -15);
}

/* ---------- libzstd ---------- */

ydb_long_t stdcompress_zstd_compress(int argc, ydb_string_t *in, ydb_string_t *out,
                                     ydb_long_t level) {
    if (argc != 3) return 0;
    clear_err();

    size_t bound = ZSTD_compressBound(in->length);
    if (bound > STDCOMPRESS_OUT_BUFSIZE) {
        set_err(",U-STDCOMPRESS-OUT-OF-MEMORY,");
        return 0;
    }

    size_t rc = ZSTD_compress(out->address, STDCOMPRESS_OUT_BUFSIZE,
                              in->address, in->length, (int)level);
    if (ZSTD_isError(rc)) {
        set_err_libzstd(",U-STDCOMPRESS-LIBZSTD-", rc);
        return 0;
    }

    out->length = (unsigned int)rc;
    return 1;
}

ydb_long_t stdcompress_zstd_decompress(int argc, ydb_string_t *in, ydb_string_t *out) {
    if (argc != 2) return 0;
    clear_err();

    size_t rc = ZSTD_decompress(out->address, STDCOMPRESS_OUT_BUFSIZE,
                                in->address, in->length);
    if (ZSTD_isError(rc)) {
        set_err_libzstd(",U-STDCOMPRESS-LIBZSTD-", rc);
        return 0;
    }

    out->length = (unsigned int)rc;
    return 1;
}

/* ---------- last-error reader ---------- */

ydb_long_t stdcompress_lasterror(int argc, ydb_string_t *out) {
    if (argc != 1) return 0;
    size_t n = strlen(g_lasterr);
    if (n > STDCOMPRESS_OUT_BUFSIZE) n = STDCOMPRESS_OUT_BUFSIZE;
    if (n > 0) memcpy(out->address, g_lasterr, n);
    out->length = (unsigned int)n;
    return 1;
}

/* ---------- error setter for M-side checks (level validation) ---------- */

ydb_long_t stdcompress_set_bad_level(int argc, ydb_string_t *codec) {
    if (argc != 1) return 0;
    char buf[STDCOMPRESS_ERR_BUFSIZE];
    int n = (int)codec->length;
    if (n >= STDCOMPRESS_ERR_BUFSIZE - 64) n = STDCOMPRESS_ERR_BUFSIZE - 64;
    snprintf(buf, sizeof(buf), ",U-STDCOMPRESS-BAD-LEVEL-%.*s,", n, codec->address);
    set_err(buf);
    return 0;
}
