$STDLIB_LIB/std_crypto.so
crypto_sha256:      ydb_int_t crypto_sha256(I:ydb_string_t*, O:ydb_string_t*[64])
crypto_sha384:      ydb_int_t crypto_sha384(I:ydb_string_t*, O:ydb_string_t*[64])
crypto_sha512:      ydb_int_t crypto_sha512(I:ydb_string_t*, O:ydb_string_t*[64])
crypto_hmac_sha256: ydb_int_t crypto_hmac_sha256(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
crypto_hmac_sha384: ydb_int_t crypto_hmac_sha384(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
crypto_hmac_sha512: ydb_int_t crypto_hmac_sha512(I:ydb_string_t*, I:ydb_string_t*, O:ydb_string_t*[64])
