STDCSPRNG       ; m-stdlib — Cryptographic random (kernel CSPRNG via getrandom(2) | /dev/urandom).
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-036
        ; M-MOD-024 false positives: the linter parses YDB OPEN/USE
        ; deviceparams (readonly, nowrap, noecho) as local-variable reads,
        ; then cascades read-of-undefined complaints across bytes/available;
        ; rc / out are also initialised before the XECUTE'd $ZF dispatch
        ; but the analyser cannot follow flow through XECUTE indirection.
        ; Same finding as STDCSV / STDCRYPTO — tracked as a P2 in
        ; TOOLCHAIN-FINDINGS.md.
        ; M-MOD-036 (XECUTE injection) is intentional: the XECUTE wrapper
        ; is the only way to invoke $ZF without m fmt's abbreviation
        ; expander mangling the token (longest-prefix match against
        ; $ZFIND). Same trick as STDCRYPTO / STDHTTP / STDCOMPRESS;
        ; the XECUTE source is built from a literal template only.
        ;
        ; Public extrinsics:
        ;   $$bytes^STDCSPRNG(n)        — n random bytes
        ;   $$hex^STDCSPRNG(n)          — 2n lowercase hex chars (n bytes hex-encoded)
        ;   $$base64^STDCSPRNG(n)       — URL-safe base64 of n bytes (no padding)
        ;   $$token^STDCSPRNG(n)        — n-char URL-safe token from [A-Za-z0-9_-]
        ;   $$int^STDCSPRNG(min,max)    — uniform integer in [min,max] (inclusive)
        ;   $$uuid4^STDCSPRNG()         — crypto-strong RFC-4122 v4 UUID
        ;   $$available^STDCSPRNG()     — 1 iff /dev/urandom is readable
        ;   $$useCallout^STDCSPRNG()    — 1 iff cs_random callout is loaded
        ;
        ; Entropy: Linux kernel ChaCha20 CSPRNG. Two backends share the
        ; same pool, so the choice is purely a perf concern:
        ;   • cs_random — $ZF → getrandom(2). Batched single-call read;
        ;     no fd churn, no record-terminator dance. Picked when
        ;     $ZTRNLNM("ydb_xc_std_csprng") is set (descriptor deployed)
        ;     and the .so resolves on first probe.
        ;   • /dev/urandom — pure-M READ *b loop; one device read per
        ;     byte. Always available on Linux YDB; the soft-fall-back
        ;     when the callout is absent.
        ; The public API is identical across both — callers never need to
        ; pick. Suitable for session tokens, password reset tokens, JWT
        ; signing salts, nonces.
        ;
        ; Distinct from $RANDOM (Mersenne Twister): $RANDOM is fast and
        ; statistically uniform but its output is predictable from a few
        ; samples — never use it for security-sensitive identifiers. Use
        ; STDCSPRNG instead.
        ;
        ; Deployment runbook (full detail in docs/modules/stdcsprng.md):
        ;   1. tools/build-callouts.sh       ; produce so/<plat>/cs_random.so
        ;   2. export STDLIB_LIB=<dir-of-so> ; substituted into std_csprng.xc
        ;   3. export ydb_xc_std_csprng=<abs>/tools/std_csprng.xc
        ; With those unset, bytes() / hex() / base64() / token() / int() /
        ; uuid4() all keep working via /dev/urandom — the callout is a
        ; perf-only swap.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
bytes(n)        ; Return n random bytes from the kernel CSPRNG.
        ; doc: For n=0 returns "". May contain any byte value 0..255.
        ; doc: Tries $ZF → cs_random (getrandom(2)) first; falls back
        ; doc: to a /dev/urandom READ *b loop when the callout descriptor
        ; doc: is unset or the .so does not resolve. Both paths read from
        ; doc: the same kernel ChaCha20 pool — the choice is a perf swap.
        ; doc: Sets $ECODE=,U-STDCSPRNG-BAD-COUNT, if n<0.
        ; doc: Sets $ECODE=,U-STDCSPRNG-OPEN-FAIL, if neither backend can
        ; doc: produce bytes (callout missing AND /dev/urandom unopenable).
        ; doc: Example: set b=$$bytes^STDCSPRNG(16)  ; 16 random bytes
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        new buf
        set buf=$$dispatchRandom(n)
        if buf'="" quit buf
        quit $$bytesFromDevice(n)
        ;
bytesFromDevice(n)      ; /dev/urandom backend — soft-fall-back when callout absent.
        ; doc: Internal — reads n bytes one at a time via READ *b so
        ; doc: record terminators (LF=$C(10), CR=$C(13)) in the byte
        ; doc: stream don't truncate the read. Sets $ECODE=,U-STDCSPRNG-
        ; doc: OPEN-FAIL, if the device cannot be opened.
        new dev,buf,prev,i,b
        set dev="/dev/urandom",buf="",prev=$io
        open dev:(readonly:nowrap):2  else  set $ecode=",U-STDCSPRNG-OPEN-FAIL," quit ""
        use dev:(noecho)
        for i=1:1:n  read *b  set buf=buf_$char(b)
        use prev
        close dev
        quit buf
        ;
hex(n)  ; Return 2n lowercase hex chars representing n random bytes.
        ; doc: Convenience wrapper: $$encode^STDHEX($$bytes(n)).
        ; doc: Example: set t=$$hex^STDCSPRNG(16)  ; 32-char hex token
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        quit $$encode^STDHEX($$bytes(n))
        ;
base64(n)       ; Return URL-safe base64 of n random bytes (no padding).
        ; doc: Convenience wrapper: $$urlencode^STDB64($$bytes(n)).
        ; doc: Example: set t=$$base64^STDCSPRNG(32)  ; ~43-char URL-safe token
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        quit $$urlencode^STDB64($$bytes(n))
        ;
token(n)        ; Return an n-char URL-safe token from alphabet [A-Za-z0-9_-].
        ; doc: Each character is one uniform draw from a 64-char alphabet
        ; doc: (6 bits of entropy per char), giving 6n bits of entropy total.
        ; doc: Sets $ECODE=,U-STDCSPRNG-BAD-COUNT, if n<0.
        ; doc: Example: set t=$$token^STDCSPRNG(22)  ; 22-char URL-safe token
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        new alpha,raw,out,i
        set alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        set raw=$$bytes(n),out=""
        for i=1:1:n  set out=out_$extract(alpha,($ascii(raw,i)#64)+1)
        quit out
        ;
int(min,max)    ; Return uniform integer in [min, max] (inclusive both ends).
        ; doc: Uses rejection sampling on the smallest power of 256 covering
        ; doc: the range, so the distribution is unbiased.
        ; doc: Sets $ECODE=,U-STDCSPRNG-BAD-RANGE, if max<min.
        ; doc: Range is bounded by M scalar precision (~10^18 ≈ 2^60); do
        ; doc: not pass spans larger than 2^53 if exact uniformity is required.
        ; doc: Example: set d=$$int^STDCSPRNG(1,6)  ; fair 6-sided die
        if max<min set $ecode=",U-STDCSPRNG-BAD-RANGE," quit ""
        if max=min quit min
        new range,nbytes,limit,accept,r,i,b
        set range=max-min+1
        set nbytes=1,limit=256
        for  quit:limit'<range  set nbytes=nbytes+1,limit=limit*256
        set accept=limit-(limit#range)
        set r=accept
        for  quit:r<accept  do
        . set r=0
        . set b=$$bytes(nbytes)
        . for i=1:1:nbytes  set r=(r*256)+$ascii(b,i)
        quit min+(r#range)
        ;
uuid4() ; Return a cryptographically strong RFC-4122 v4 UUID.
        ; doc: 122 bits of entropy from /dev/urandom. Same canonical 36-char
        ; doc: hex form as STDUUID's $$v4 — but use this when the UUID is a
        ; doc: security boundary (session tokens, signed-URL nonces, JWT jti).
        ; doc: Example: set id=$$uuid4^STDCSPRNG()
        new b,h,b7,b9
        set b=$$bytes(16)
        set b7=$ascii(b,7)
        set b7=(b7#16)+64
        set $extract(b,7)=$char(b7)
        set b9=$ascii(b,9)
        set b9=(b9#64)+128
        set $extract(b,9)=$char(b9)
        set h=$$encode^STDHEX(b)
        quit $extract(h,1,8)_"-"_$extract(h,9,12)_"-"_$extract(h,13,16)_"-"_$extract(h,17,20)_"-"_$extract(h,21,32)
        ;
available()     ; Return 1 iff /dev/urandom is openable for reading; else 0.
        ; doc: Pre-flight probe — never raises. Useful for guarding code that
        ; doc: needs CSPRNG entropy before any sensitive operation begins.
        ; doc: Returns 1 whenever /dev/urandom is readable, irrespective of
        ; doc: whether the cs_random callout is loaded (the device is the
        ; doc: always-available soft-fall-back; see useCallout() to detect
        ; doc: the perf-tier backend separately).
        ; doc: Example: if '$$available^STDCSPRNG() set $ecode=",U-MYAPP-NO-CSPRNG,"
        new dev,prev
        set dev="/dev/urandom",prev=$io
        open dev:(readonly:nowrap):2  else  quit 0
        use prev
        close dev
        quit 1
        ;
useCallout()    ; Return 1 iff the cs_random callout resolves; else 0.
        ; doc: Pre-flight probe for the $ZF → getrandom(2) backend.
        ; doc: Never raises — clears $ECODE on the way out. Cheap fast
        ; doc: path: if $ZTRNLNM("ydb_xc_std_csprng") is empty the
        ; doc: descriptor isn't deployed — return 0 without paying the
        ; doc: XECUTE / $ZF round-trip. Otherwise issues a 1-byte probe
        ; doc: through the callout; returns 1 only when the .so loaded
        ; doc: and getrandom(2) succeeded.
        ; doc: Example:
        ; doc:   if $$useCallout^STDCSPRNG() write "fast path"
        new buf,n
        if $$env^STDOS("ydb_xc_std_csprng")="" quit 0
        set buf=$$dispatchRandom(1)
        set n=$length(buf)
        set $ecode=""
        quit $select(n=1:1,1:0)
        ;
        ; ---------- internal helpers ----------
        ;
dispatchRandom(n)       ; Invoke $ZF("cs_random", n, .out). Returns out on success, "" on miss.
        ; doc: Internal — XECUTE-wraps $ZF so m fmt cannot mangle the
        ; doc: token (longest-prefix bug against $ZFIND). Returns the
        ; doc: filled buffer on rc=0 (callout success); returns "" when
        ; doc: the descriptor isn't deployed, the .so doesn't resolve,
        ; doc: or getrandom(2) reports failure — the M-side caller falls
        ; doc: back to /dev/urandom on "". Same XECUTE rationale as
        ; doc: STDCRYPTO.dispatch3 / STDHTTP.dispatchPerform.
        new $etrap,rc,cmd,out,i
        if $$env^STDOS("ydb_xc_std_csprng")="" quit ""
        set $etrap="set $ecode="""" set rc=-99 quit"
        set rc=0
        ; Pre-allocate n NUL bytes — cs_random reads out->length as the
        ; M-side capacity and overwrites in place.
        set out=""
        for i=1:1:n  set out=out_$char(0)
        set cmd="set rc=$ZF(""cs_random"",n,.out)"
        xecute cmd
        set $ecode=""
        if rc'=0 quit ""
        quit out
