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
        ; doc: @param n       int     byte count (>= 0)
        ; doc: @returns       byte-string  n random bytes; "" for n=0
        ; doc: @raises        U-STDCSPRNG-BAD-COUNT  n < 0
        ; doc: @raises        U-STDCSPRNG-OPEN-FAIL  neither backend can produce bytes
        ; doc: @example       set b=$$bytes^STDCSPRNG(16)  ; 16 random bytes
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$hex^STDCSPRNG, $$base64^STDCSPRNG, $$token^STDCSPRNG, $$uuid4^STDCSPRNG
        ; doc: Tries $ZF → cs_random (getrandom(2)) first; falls back to a
        ; doc: /dev/urandom READ *b loop when the callout descriptor is unset
        ; doc: or the .so does not resolve.
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        new buf
        set buf=$$dispatchRandom(n)
        if buf'="" quit buf
        quit $$bytesFromDevice(n)
        ;
bytesFromDevice(n)      ; /dev/urandom backend — soft-fall-back when callout absent.
        ; doc: @internal
        ; doc: Reads n bytes one at a time via READ *b so record terminators
        ; doc: (LF=$C(10), CR=$C(13)) in the byte stream don't truncate the read.
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
        ; doc: @param n       int     byte count (>= 0)
        ; doc: @returns       string  2n lowercase hex chars
        ; doc: @raises        U-STDCSPRNG-BAD-COUNT  n < 0
        ; doc: @example       set t=$$hex^STDCSPRNG(16)  ; 32-char hex token
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$bytes^STDCSPRNG, $$encode^STDHEX
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        quit $$encode^STDHEX($$bytes(n))
        ;
base64(n)       ; Return URL-safe base64 of n random bytes (no padding).
        ; doc: @param n       int     byte count (>= 0)
        ; doc: @returns       string  URL-safe base64 (no padding)
        ; doc: @raises        U-STDCSPRNG-BAD-COUNT  n < 0
        ; doc: @example       set t=$$base64^STDCSPRNG(32)  ; ~43-char URL-safe token
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$bytes^STDCSPRNG, $$urlencode^STDB64
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        quit $$urlencode^STDB64($$bytes(n))
        ;
token(n)        ; Return an n-char URL-safe token from alphabet [A-Za-z0-9_-].
        ; doc: @param n       int     character count (>= 0)
        ; doc: @returns       string  n-char token from [A-Za-z0-9_-]
        ; doc: @raises        U-STDCSPRNG-BAD-COUNT  n < 0
        ; doc: @example       set t=$$token^STDCSPRNG(22)  ; 22-char URL-safe token
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$base64^STDCSPRNG, $$bytes^STDCSPRNG
        ; doc: Each character is one uniform draw from a 64-char alphabet
        ; doc: (6 bits of entropy per char), giving 6n bits of entropy total.
        if n<0 set $ecode=",U-STDCSPRNG-BAD-COUNT," quit ""
        if 'n quit ""
        new alpha,raw,out,i
        set alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        set raw=$$bytes(n),out=""
        for i=1:1:n  set out=out_$extract(alpha,($ascii(raw,i)#64)+1)
        quit out
        ;
int(min,max)    ; Return uniform integer in [min, max] (inclusive both ends).
        ; doc: @param min     int     lower bound (inclusive)
        ; doc: @param max     int     upper bound (inclusive)
        ; doc: @returns       int     uniform random integer in [min, max]
        ; doc: @raises        U-STDCSPRNG-BAD-RANGE  max < min
        ; doc: @example       set d=$$int^STDCSPRNG(1,6)  ; fair 6-sided die
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$bytes^STDCSPRNG
        ; doc: Uses rejection sampling on the smallest power of 256 covering
        ; doc: the range, so the distribution is unbiased. Range is bounded
        ; doc: by M scalar precision (~10^18 ≈ 2^60).
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
        ; doc: @returns       string  canonical 36-char hex UUID v4 (lowercase, hyphenated)
        ; doc: @example       set id=$$uuid4^STDCSPRNG()
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$v4^STDUUID, $$bytes^STDCSPRNG
        ; doc: 122 bits of entropy from the kernel CSPRNG. Use this when the
        ; doc: UUID is a security boundary (session tokens, signed-URL nonces,
        ; doc: JWT jti) — STDUUID's $$v4 uses non-cryptographic $RANDOM.
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
        ; doc: @returns       bool    1 iff /dev/urandom is readable
        ; doc: @example       if '$$available^STDCSPRNG() set $ecode=",U-MYAPP-NO-CSPRNG,"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$useCallout^STDCSPRNG
        ; doc: Pre-flight probe — never raises. The device is the always-
        ; doc: available soft-fall-back; see useCallout() to detect the
        ; doc: perf-tier backend separately.
        new dev,prev
        set dev="/dev/urandom",prev=$io
        open dev:(readonly:nowrap):2  else  quit 0
        use prev
        close dev
        quit 1
        ;
useCallout()    ; Return 1 iff the cs_random callout resolves; else 0.
        ; doc: @returns       bool    1 iff $ZF → cs_random is wired and getrandom(2) succeeded
        ; doc: @example       if $$useCallout^STDCSPRNG() write "fast path"
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$available^STDCSPRNG, $$bytes^STDCSPRNG
        ; doc: Pre-flight probe for the $ZF → getrandom(2) backend.
        ; doc: Never raises — clears $ECODE on the way out.
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
        ; doc: @internal
        ; doc: XECUTE-wraps $ZF so m fmt cannot mangle the token. Returns
        ; doc: the filled buffer on rc=0; returns "" when the descriptor
        ; doc: isn't deployed, the .so doesn't resolve, or getrandom(2)
        ; doc: reports failure — caller falls back to /dev/urandom on "".
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
