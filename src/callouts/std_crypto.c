// link: -lcrypto
/*
 * std_crypto.c — m-stdlib Phase 3 cryptographic digest + HMAC callouts.
 *
 * Backend: OpenSSL libcrypto (EVP_Digest + HMAC). Produces six entry points:
 *   crypto_sha256 / crypto_sha384 / crypto_sha512
 *   crypto_hmac_sha256 / crypto_hmac_sha384 / crypto_hmac_sha512
 *
 * Build:
 *   tools/build-callouts.sh           # produces so/<plat>/std_crypto.so
 * Loading:
 *   tools/std_crypto.xc                # YDB call-out descriptor
 *   export STDLIB_LIB=<abs-path-to-so/<plat>>
 *   export ydb_xc_std_crypto=<abs-path>/tools/std_crypto.xc
 *
 * Calling convention:
 *   Each entry point takes one or two ydb_string_t* INPUT buffers, plus one
 *   ydb_string_t* OUTPUT buffer pre-allocated by YDB (size declared via
 *   O:ydb_string_t*[64] in the .xc descriptor — large enough for SHA-512).
 *   The C side writes the raw digest bytes into out->address and updates
 *   out->length to the actual digest size. Returns 0 on success.
 *
 * Status codes:
 *    0 = ok
 *   -1 = OpenSSL EVP_MD_CTX allocation failed
 *   -2 = EVP_Digest{Init,Update,Final} reported failure
 *   -3 = caller-provided output buffer is too small for the digest
 *   -4 = HMAC() returned NULL
 */

#include <stddef.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include "libyottadb.h"

static int sha_digest(const EVP_MD *md, ydb_string_t *in, ydb_string_t *out)
{
    EVP_MD_CTX   *ctx;
    unsigned int  len = 0;
    unsigned char buf[EVP_MAX_MD_SIZE];

    if (out == NULL || out->address == NULL) return -3;

    ctx = EVP_MD_CTX_new();
    if (ctx == NULL) return -1;

    if (EVP_DigestInit_ex(ctx, md, NULL) != 1 ||
        EVP_DigestUpdate(ctx, in ? (const void *)in->address : NULL,
                         in ? (size_t)in->length : 0) != 1 ||
        EVP_DigestFinal_ex(ctx, buf, &len) != 1) {
        EVP_MD_CTX_free(ctx);
        return -2;
    }
    EVP_MD_CTX_free(ctx);

    if ((unsigned long)len > (unsigned long)out->length) return -3;
    memcpy(out->address, buf, len);
    out->length = (unsigned long)len;
    return 0;
}

static int hmac_digest(const EVP_MD *md,
                       ydb_string_t *key, ydb_string_t *msg,
                       ydb_string_t *out)
{
    unsigned int   len = 0;
    unsigned char  buf[EVP_MAX_MD_SIZE];
    const void          *kptr = (key && key->address) ? (const void *)key->address : "";
    int                  klen = (key) ? (int)key->length : 0;
    const unsigned char *mptr =
        (const unsigned char *)((msg && msg->address) ? msg->address : "");
    size_t               mlen = (msg) ? (size_t)msg->length : 0;

    if (out == NULL || out->address == NULL) return -3;
    if (HMAC(md, kptr, klen, mptr, mlen, buf, &len) == NULL) return -4;
    if ((unsigned long)len > (unsigned long)out->length) return -3;

    memcpy(out->address, buf, len);
    out->length = (unsigned long)len;
    return 0;
}

int crypto_sha256(ydb_string_t *in, ydb_string_t *out)
{
    return sha_digest(EVP_sha256(), in, out);
}

int crypto_sha384(ydb_string_t *in, ydb_string_t *out)
{
    return sha_digest(EVP_sha384(), in, out);
}

int crypto_sha512(ydb_string_t *in, ydb_string_t *out)
{
    return sha_digest(EVP_sha512(), in, out);
}

int crypto_hmac_sha256(ydb_string_t *key, ydb_string_t *msg, ydb_string_t *out)
{
    return hmac_digest(EVP_sha256(), key, msg, out);
}

int crypto_hmac_sha384(ydb_string_t *key, ydb_string_t *msg, ydb_string_t *out)
{
    return hmac_digest(EVP_sha384(), key, msg, out);
}

int crypto_hmac_sha512(ydb_string_t *key, ydb_string_t *msg, ydb_string_t *out)
{
    return hmac_digest(EVP_sha512(), key, msg, out);
}
