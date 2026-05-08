$STDLIB_LIB/stdfs.so
stdfs_available:   ydb_long_t stdfs_available()
stdfs_writeBytes:  ydb_long_t stdfs_writeBytes(I:ydb_string_t*, I:ydb_string_t*)
stdfs_appendBytes: ydb_long_t stdfs_appendBytes(I:ydb_string_t*, I:ydb_string_t*)
stdfs_readBytes:   ydb_long_t stdfs_readBytes(I:ydb_string_t*, O:ydb_string_t*[16777216])
stdfs_lasterror:   ydb_long_t stdfs_lasterror(O:ydb_string_t*[1024])
