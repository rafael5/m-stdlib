STDCOMPRESS     ; m-stdlib — gzip / deflate / zstd via $ZF callouts.
        ;
        ; Public extrinsics (output via .out byref; return 1=ok / 0=fail):
        ;   $$gzip^STDCOMPRESS(data,.out[,level])           — RFC 1952 gzip
        ;   $$gunzip^STDCOMPRESS(data,.out)                 — RFC 1952 gunzip
        ;   $$deflate^STDCOMPRESS(data,.out[,level])        — RFC 1951 raw deflate
        ;   $$inflate^STDCOMPRESS(data,.out)                — RFC 1951 raw inflate
        ;   $$zstdCompress^STDCOMPRESS(data,.out[,level])   — RFC 8478 zstd
        ;   $$zstdDecompress^STDCOMPRESS(data,.out)         — RFC 8478 zstd
        ;   $$available^STDCOMPRESS()                       — ""=ok, else missing
        ;   $$lastError^STDCOMPRESS()                       — last error or ""
        ;
        ; Levels: gzip / deflate accept 1..9 (default 6); zstd accepts 1..22
        ; (default 3). Level 0 (no compression) is rejected to avoid surprise
        ; pass-through. Level errors are caught in M before any callout.
        ;
        ; Output cap: 16 MiB per call (declared in tools/std_compress.xc).
        ; Streaming for larger payloads is queued.
        ;
        ; Binary safety: uses $ZASCII / $ZCHAR (byte semantics regardless of
        ; $ZCHSET). Compressed output contains arbitrary 0x00..0xFF bytes.
        ;
        ; Build: tools/build-callouts.sh produces so/<platform>/stdcompress.so.
        ; Runtime env: STDLIB_LIB=so/<platform>, ydb_xc_stdcompress=tools/std_compress.xc.
        ;
        ; Implementation note: the YDB external-call invocations (`$&pkg.X(...)`)
        ; are wrapped in XECUTE strings because tree-sitter-m v0.1 has no rule
        ; for the `$&` syntax (logged in TOOLCHAIN-FINDINGS). XECUTE defers
        ; parsing to YDB's own compiler at runtime, which accepts `$&`. The
        ; wrappers will collapse to direct calls once the grammar lands.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
gzip(data,out,level)    ; RFC 1952 gzip-format compress.
        ; doc: Example: do gzip^STDCOMPRESS("hello",.buf)
        new lvl
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 do setErr(",U-STDCOMPRESS-BAD-LEVEL,") quit 0
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_gzip(.data,.out,lvl)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
gunzip(data,out)        ; RFC 1952 gunzip.
        ; doc: Example: do gunzip^STDCOMPRESS(buf,.raw)
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_gunzip(.data,.out)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
deflate(data,out,level) ; RFC 1951 raw deflate (no header / trailer).
        ; doc: Example: do deflate^STDCOMPRESS("hello",.buf)
        new lvl
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 do setErr(",U-STDCOMPRESS-BAD-LEVEL,") quit 0
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_deflate(.data,.out,lvl)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
inflate(data,out)       ; RFC 1951 raw inflate.
        ; doc: Example: do inflate^STDCOMPRESS(buf,.raw)
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_inflate(.data,.out)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
zstdCompress(data,out,level)    ; Zstandard (RFC 8478) compress.
        ; doc: Example: do zstdCompress^STDCOMPRESS("hello",.buf)
        new lvl
        set lvl=$$zstdLevel($get(level,3))
        if lvl=-1 do setErr(",U-STDCOMPRESS-BAD-LEVEL,") quit 0
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_zstd_compress(.data,.out,lvl)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
zstdDecompress(data,out)        ; Zstandard decompress.
        ; doc: Example: do zstdDecompress^STDCOMPRESS(buf,.raw)
        new rc set rc=0
        xecute "set rc=$&stdcompress.stdcompress_zstd_decompress(.data,.out)"
        if 'rc do readCErr() quit 0
        do clearErr()
        quit 1
        ;
available()     ; "" iff both libz and libzstd loaded; else comma-list of missing.
        ; doc: Example: if $$available^STDCOMPRESS()'="" write "missing libs",!
        new gz,zstd,miss
        set gz=0,zstd=0
        xecute "set gz=$&stdcompress.stdcompress_available_libz()"
        xecute "set zstd=$&stdcompress.stdcompress_available_libzstd()"
        set miss=""
        if 'gz set miss="libz"
        if 'zstd set miss=$select(miss="":"libzstd",1:miss_",libzstd")
        quit miss
        ;
lastError()     ; Return last error message; "" if last call succeeded.
        ; doc: Example: if 'rc write $$lastError^STDCOMPRESS(),!
        quit $get(^STDLIB($job,"stdcompress","err"),"")
        ;
        ; ---------- internal helpers ----------
        ;
libzLevel(n)    ; Validate libz compression level — 1..9 valid, else -1.
        ; doc: Internal — level 0 (no compression) deliberately rejected.
        if n'=(n+0) quit -1
        if n<1 quit -1
        if n>9 quit -1
        quit n
        ;
zstdLevel(n)    ; Validate zstd compression level — 1..22 valid, else -1.
        ; doc: Internal — negative levels (--fast tier) deferred.
        if n'=(n+0) quit -1
        if n<1 quit -1
        if n>22 quit -1
        quit n
        ;
setErr(msg)     ; Store msg as last error (process-keyed global).
        ; doc: Internal — read via $$lastError().
        set ^STDLIB($job,"stdcompress","err")=msg
        quit
        ;
clearErr()      ; Clear last error.
        ; doc: Internal — called on success.
        kill ^STDLIB($job,"stdcompress","err")
        quit
        ;
readCErr()      ; Pull the C-side error string into the M-side store.
        ; doc: Internal — called after a callout returns 0.
        new buf,rc
        set buf=""
        xecute "set rc=$&stdcompress.stdcompress_lasterror(.buf)"
        set ^STDLIB($job,"stdcompress","err")=buf
        quit
        ;
