STDCOMPRESS     ; m-stdlib — gzip / deflate / zstd via $&stdcompress callouts.
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-036
        ; m-lint: disable-file=M-MOD-020
        ; M-MOD-024 false positives: rc / out are initialised before every
        ; XECUTE'd $& call but the analyser cannot follow flow through the
        ; XECUTE indirection.
        ; M-MOD-036 (XECUTE injection) is intentional: the XECUTE wrapper is
        ; the only way to invoke $&pkg.fn from M code that tree-sitter-m can
        ; still parse — same trick as STDCRYPTO. The XECUTE source is built
        ; from a literal template plus a `sym` symbol that the M-side public
        ; surface controls; no user data flows into the XECUTE string.
        ; M-MOD-020 (by-ref formal not written) false positives: dispatch
        ; helpers write to `out` via the XECUTE'd $& call.
        ;
        ; Public extrinsics (output via .out byref; return 1=ok / 0=fail):
        ;   $$gzip^STDCOMPRESS(data,.out[,level])           — RFC 1952 gzip
        ;   $$gunzip^STDCOMPRESS(data,.out)                 — RFC 1952 gunzip
        ;   $$deflate^STDCOMPRESS(data,.out[,level])        — RFC 1951 deflate
        ;   $$inflate^STDCOMPRESS(data,.out)                — RFC 1951 inflate
        ;   $$zstdCompress^STDCOMPRESS(data,.out[,level])   — RFC 8478 zstd
        ;   $$zstdDecompress^STDCOMPRESS(data,.out)         — RFC 8478 zstd
        ;   $$available^STDCOMPRESS()                       — ""=ok, else missing
        ;
        ; Errors set $ECODE: ,U-STDCOMPRESS-CALLOUT-MISSING, (.so unloaded);
        ; ,U-STDCOMPRESS-BAD-LEVEL, (level out of range); ,U-STDCOMPRESS-LIBZ-FAIL,
        ; (libz returned non-Z_STREAM_END); ,U-STDCOMPRESS-LIBZSTD-FAIL, (zstd
        ; returned an error frame).
        ;
        ; Levels: gzip / deflate accept 1..9 (default 6); zstd accepts 1..22
        ; (default 3). Level 0 (no compression) is rejected to avoid surprise
        ; pass-through.
        ;
        ; Output cap: 1 MiB per call (YDB's max M-string length on this
        ; build; declared in tools/std_compress.xc). Streaming for larger
        ; payloads is queued.
        ;
        ; Backend: $&stdcompress.<sym> → libz (gzip / deflate) + libzstd
        ; (zstd). Source at src/callouts/stdcompress.c; descriptor at
        ; tools/std_compress.xc.
        ;
        ; Deployment runbook (full detail in docs/modules/stdcompress.md):
        ;   1. tools/build-callouts.sh                  ; produce so/<plat>/stdcompress.so
        ;   2. export STDLIB_LIB=<dir-of-so>
        ;   3. export ydb_xc_stdcompress=<abs>/tools/std_compress.xc
        ;   4. ensure libz.so.1 + libzstd.so.1 are on the loader path
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
gzip(data,out,level)    ; RFC 1952 gzip-format compress.
        ; doc: data is treated as a byte string (one M character per byte).
        ; doc: Sets $ECODE=,U-STDCOMPRESS-BAD-LEVEL, if level outside 1..9;
        ; doc: ,U-STDCOMPRESS-CALLOUT-MISSING, if the .so is unloaded;
        ; doc: ,U-STDCOMPRESS-LIBZ-FAIL, on libz failure.
        ; doc: Example: do gzip^STDCOMPRESS("hello",.buf)
        new lvl,st
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        set st=$$dispatchC("gzip",data,.out,lvl)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZ-FAIL,") quit 0
        ;
gunzip(data,out)        ; RFC 1952 gunzip.
        ; doc: Example: do gunzip^STDCOMPRESS(buf,.raw)
        new st
        set st=$$dispatchD("gunzip",data,.out)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZ-FAIL,") quit 0
        ;
deflate(data,out,level) ; RFC 1951 raw deflate (no header / trailer).
        ; doc: Example: do deflate^STDCOMPRESS("hello",.buf)
        new lvl,st
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        set st=$$dispatchC("deflate",data,.out,lvl)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZ-FAIL,") quit 0
        ;
inflate(data,out)       ; RFC 1951 raw inflate.
        ; doc: Example: do inflate^STDCOMPRESS(buf,.raw)
        new st
        set st=$$dispatchD("inflate",data,.out)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZ-FAIL,") quit 0
        ;
zstdCompress(data,out,level)    ; Zstandard (RFC 8478) compress.
        ; doc: Example: do zstdCompress^STDCOMPRESS("hello",.buf)
        new lvl,st
        set lvl=$$zstdLevel($get(level,3))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        set st=$$dispatchC("zstdCompress",data,.out,lvl)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZSTD-FAIL,") quit 0
        ;
zstdDecompress(data,out)        ; Zstandard decompress.
        ; doc: Example: do zstdDecompress^STDCOMPRESS(buf,.raw)
        new st
        set st=$$dispatchD("zstdDecompress",data,.out)
        if st="" quit 1
        set $ecode=$select(st="MISSING":",U-STDCOMPRESS-CALLOUT-MISSING,",1:",U-STDCOMPRESS-LIBZSTD-FAIL,") quit 0
        ;
available()     ; "" iff both libz and libzstd loaded; else missing list.
        ; doc: Example: if $$available^STDCOMPRESS()'="" w "missing libs",!
        ; doc: Probes by attempting an empty round-trip on each backend.
        ; doc: Never raises — clears $ECODE on the way out.
        new gz,zstd,buf,miss
        set gz=$$gzip("",.buf,6)
        set zstd=$$zstdCompress("",.buf,3)
        set $ecode=""
        set miss=""
        if 'gz set miss="libz"
        if 'zstd set miss=$select(miss="":"libzstd",1:miss_",libzstd")
        quit miss
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
preallocBuf()   ; 1 MiB pre-allocated output buffer for the C side to fill.
        ; doc: Internal — YDB callouts need the M-side string at full
        ; doc: capacity before the C side writes into it. $justify("",N)
        ; doc: allocates N spaces in one O(N) pass; the C side overwrites
        ; doc: the contents and updates ydb_string_t.length on return.
        ; doc: Capped at 1 MiB (YDB's max M-string length on r2.02);
        ; doc: matches the [1048576] declaration in tools/std_compress.xc.
        quit $justify("",1048576)
        ;
dispatchC(sym,data,out,lvl)     ; Compress dispatch — 3-arg $&. Returns status.
        ; doc: Internal — XECUTE-wraps $&stdcompress.<sym>(data,.out,lvl)
        ; doc: so tree-sitter-m doesn't trip on the $&pkg.fn syntax.
        ; doc: Returns "" on success, "MISSING" if .so unloaded,
        ; doc: "FAIL" if libz/libzstd returned non-success. Caller maps
        ; doc: status to the per-backend $ECODE tag.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit ""MISSING"""
        set rc=0
        set out=$$preallocBuf()
        set cmd="set rc=$&stdcompress."_sym_"(data,.out,lvl)"
        xecute cmd
        if rc=-1 quit "MISSING"
        if 'rc quit "FAIL"
        quit ""
        ;
dispatchD(sym,data,out)         ; Decompress dispatch — 2-arg $&. Returns status.
        ; doc: Internal — same XECUTE-wrap rationale as dispatchC.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit ""MISSING"""
        set rc=0
        set out=$$preallocBuf()
        set cmd="set rc=$&stdcompress."_sym_"(data,.out)"
        xecute cmd
        if rc=-1 quit "MISSING"
        if 'rc quit "FAIL"
        quit ""
        ;
