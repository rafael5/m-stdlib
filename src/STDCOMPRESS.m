STDCOMPRESS     ; m-stdlib — gzip / deflate / zstd via $ZF callouts.
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-036
        ; m-lint: disable-file=M-MOD-020
        ; M-MOD-024 false positives: rc / out are initialised before every
        ; XECUTE'd $ZF call but the analyser cannot follow flow through the
        ; XECUTE indirection.
        ; M-MOD-036 (XECUTE injection) is intentional: the XECUTE wrapper is
        ; the only way to invoke $ZF without the m fmt abbreviation expander
        ; mangling the token (longest-prefix match against $ZFIND). The
        ; XECUTE source is built from a literal template plus a `sym` symbol
        ; that the M-side public surface controls — no user data flows into
        ; the XECUTE string. Same trick as STDCRYPTO / STDXFRM.
        ; M-MOD-020 (by-ref formal not written) false positives: dispatch
        ; helpers write to `out` via the XECUTE'd $ZF call.
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
        ; Output cap: 16 MiB per call (declared in tools/std_compress.xc).
        ; Streaming for larger payloads is queued.
        ;
        ; Backend: $ZF → libz (gzip / deflate) + libzstd (zstd). Source at
        ; src/callouts/stdcompress.c; descriptor at tools/std_compress.xc.
        ;
        ; Deployment runbook (full detail in docs/modules/stdcompress.md):
        ;   1. tools/build-callouts.sh       ; produce so/<plat>/stdcompress.so
        ;   2. export STDLIB_LIB=<dir-of-so>
        ;   3. export ydb_ci=<abs>/tools/std_compress.xc
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
        new lvl
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        quit $$dispatchC("stdcompress_gzip",data,.out,lvl,"libz")
        ;
gunzip(data,out)        ; RFC 1952 gunzip.
        ; doc: Example: do gunzip^STDCOMPRESS(buf,.raw)
        quit $$dispatchD("stdcompress_gunzip",data,.out,"libz")
        ;
deflate(data,out,level) ; RFC 1951 raw deflate (no header / trailer).
        ; doc: Example: do deflate^STDCOMPRESS("hello",.buf)
        new lvl
        set lvl=$$libzLevel($get(level,6))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        quit $$dispatchC("stdcompress_deflate",data,.out,lvl,"libz")
        ;
inflate(data,out)       ; RFC 1951 raw inflate.
        ; doc: Example: do inflate^STDCOMPRESS(buf,.raw)
        quit $$dispatchD("stdcompress_inflate",data,.out,"libz")
        ;
zstdCompress(data,out,level)    ; Zstandard (RFC 8478) compress.
        ; doc: Example: do zstdCompress^STDCOMPRESS("hello",.buf)
        new lvl
        set lvl=$$zstdLevel($get(level,3))
        if lvl=-1 set $ecode=",U-STDCOMPRESS-BAD-LEVEL," quit 0
        quit $$dispatchC("stdcompress_zstd_compress",data,.out,lvl,"libzstd")
        ;
zstdDecompress(data,out)        ; Zstandard decompress.
        ; doc: Example: do zstdDecompress^STDCOMPRESS(buf,.raw)
        quit $$dispatchD("stdcompress_zstd_decompress",data,.out,"libzstd")
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
preallocBuf()   ; 16 MiB pre-allocated output buffer for the C side to fill.
        ; doc: Internal — YDB callouts need the M-side string at full
        ; doc: capacity before the C side writes into it. $justify("",N)
        ; doc: allocates N spaces in one O(N) pass; the C side overwrites
        ; doc: the contents and updates ydb_string_t.length on return.
        quit $justify("",16777216)
        ;
dispatchC(sym,data,out,lvl,backend)     ; Compress dispatch — 3-arg $ZF.
        ; doc: Internal — XECUTE-wraps $ZF(sym, data, .out, lvl) so the
        ; doc: m fmt token-mangler doesn't touch $ZF. Sets $ECODE on
        ; doc: failure: ,U-STDCOMPRESS-CALLOUT-MISSING, if the .so is
        ; doc: unloaded; ,U-STDCOMPRESS-LIBZ-FAIL, / -LIBZSTD-FAIL,
        ; doc: depending on the backend.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set out=$$preallocBuf()
        set cmd="set rc=$ZF("""_sym_""",data,.out,lvl)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDCOMPRESS-CALLOUT-MISSING," quit 0
        if 'rc set $ecode=$select(backend="libz":",U-STDCOMPRESS-LIBZ-FAIL,",1:",U-STDCOMPRESS-LIBZSTD-FAIL,") quit 0
        quit 1
        ;
dispatchD(sym,data,out,backend) ; Decompress dispatch — 2-arg $ZF.
        ; doc: Internal — same wrap as dispatchC but without the level arg.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set out=$$preallocBuf()
        set cmd="set rc=$ZF("""_sym_""",data,.out)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDCOMPRESS-CALLOUT-MISSING," quit 0
        if 'rc set $ecode=$select(backend="libz":",U-STDCOMPRESS-LIBZ-FAIL,",1:",U-STDCOMPRESS-LIBZSTD-FAIL,") quit 0
        quit 1
        ;
