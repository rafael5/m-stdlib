$STDLIB_LIB/std_crypto.so
sha256:     ydb_int_t crypto_sha256(I:ydb_string_t*, O:ydb_string_t*[64])
sha384:     ydb_int_t crypto_sha384(I:ydb_string_t*, O:ydb_string_t*[64])
sha512:     ydb_int_t crypto_sha512(I:ydb_string_t*, O:ydb_string_t*[64])
hmacSha256: ydb_int_t crypto_hmac_sha256(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
hmacSha384: ydb_int_t crypto_hmac_sha384(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
hmacSha512: ydb_int_t crypto_hmac_sha512(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
