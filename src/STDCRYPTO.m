STDCRYPTO       ; m-stdlib — Cryptographic digests via $ZF → libcrypto.
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-036
        ; m-lint: disable-file=M-MOD-020
        ; M-MOD-024 false positives: rc is initialised by every entry to
        ; dispatch3 / dispatch4 before any read, but the analyser cannot
        ; track flow through the $ETRAP indirection used to recover from
        ; missing-callout failures.
        ; M-MOD-036 (XECUTE injection) is intentional here: the XECUTE
        ; wrapper is the only way to invoke $ZF without the m fmt
        ; abbreviation expander mangling the token. The XECUTEd command
        ; string is built only from the literal "set rc=$ZF(...)" template
        ; and a sym argument that the M-side public surface controls — no
        ; user data ever flows into the XECUTE source. Same pattern as
        ; STDXFRM's @expr indirection.
        ; M-MOD-020 (by-ref formal not written) false positives: dispatch3
        ; / dispatch4 write to `out` by reference, but the writes happen
        ; through the XECUTE'd command string, which the by-ref analyser
        ; can't introspect.
        ;
        ; Public extrinsics:
        ;   $$sha256^STDCRYPTO(data)              — 64-char lowercase hex
        ;   $$sha384^STDCRYPTO(data)              — 96-char lowercase hex
        ;   $$sha512^STDCRYPTO(data)              — 128-char lowercase hex
        ;   $$sha256Bytes^STDCRYPTO(data)         — 32 raw bytes
        ;   $$sha384Bytes^STDCRYPTO(data)         — 48 raw bytes
        ;   $$sha512Bytes^STDCRYPTO(data)         — 64 raw bytes
        ;   $$hmacSha256^STDCRYPTO(key,msg)       — 64-char lowercase hex
        ;   $$hmacSha384^STDCRYPTO(key,msg)       — 96-char lowercase hex
        ;   $$hmacSha512^STDCRYPTO(key,msg)       — 128-char lowercase hex
        ;   $$hmacSha256Bytes^STDCRYPTO(key,msg)  — 32 raw bytes
        ;   $$hmacSha384Bytes^STDCRYPTO(key,msg)  — 48 raw bytes
        ;   $$hmacSha512Bytes^STDCRYPTO(key,msg)  — 64 raw bytes
        ;   $$available^STDCRYPTO()               — 1 iff std_crypto callout
        ;                                            is loaded
        ;
        ; Backend: $ZF → libcrypto (OpenSSL EVP_Digest + HMAC). The C source
        ; is at src/callouts/std_crypto.c; the YDB call-out descriptor is at
        ; tools/std_crypto.xc; the build harness is tools/build-callouts.sh.
        ;
        ; Deployment runbook (full detail in docs/modules/stdcrypto.md):
        ;   1. tools/build-callouts.sh       ; produce so/<plat>/std_crypto.so
        ;   2. export STDLIB_LIB=<dir-of-so> ; substituted into std_crypto.xc
        ;   3. export ydb_ci=<abs>/tools/std_crypto.xc
        ;   4. ensure libcrypto.so.3 (or .so.1.1) is on the loader path
        ;
        ; Implementation note — XECUTE wrapper for $ZF:
        ; M-side calls go through dispatch3 / dispatch4, which build the
        ; "set rc=$ZF(...)" command as a STRING and XECUTE it. This is a
        ; workaround for an m fmt bug where the abbreviation-expansion
        ; table mangles $ZF → $zfind (longest-prefix match against
        ; $ZFIND). String literals are not introspected by the formatter,
        ; so the literal $ZF survives through to runtime, where YDB's
        ; parser resolves it correctly to the external-call form. The
        ; same trick applies if we ever need $ZCALL → $zcstatusall.
        ; Filed in TOOLCHAIN-FINDINGS; once m fmt is fixed, the wrapper
        ; can be replaced by direct $ZF calls and a simpler signature.
        ;
        ; All error paths set $ECODE rather than raising directly so callers
        ; can wrap with a single $ETRAP — matches STDCSPRNG / STDCSV style.
        ;
        ; Out of scope at v1 (queued under T-N follow-ups):
        ;   - AES-128/256-GCM encrypt/decrypt
        ;   - Ed25519 / Ed448 sign/verify
        ;   - X25519 key agreement
        ;   - Streaming digest API (init/update/final tied to a handle)
        ;   - SHA-1, MD5 (deprecated; ship only if a real consumer asks)
        ;   - SHA-3 / SHAKE
        ;
        quit
        ;
        ; ---------- public API: SHA digests ----------
        ;
sha256(data)    ; 64-char lowercase hex SHA-256 digest of data.
        ; doc: data is treated as a byte string (one M character per byte —
        ; doc: values 0..255). Empty input returns the well-known SHA-256
        ; doc: digest of the empty string (e3b0c442...).
        ; doc: Sets $ECODE=,U-STDCRYPTO-CALLOUT-MISSING, if std_crypto
        ; doc: package is not loaded; ,U-STDCRYPTO-DIGEST-FAIL, if libcrypto
        ; doc: itself reports failure.
        ; doc: Example: write $$sha256^STDCRYPTO("abc")  ; "ba7816bf..."
        quit $$encode^STDHEX($$sha256Bytes(data))
        ;
sha384(data)    ; 96-char lowercase hex SHA-384 digest of data.
        ; doc: See sha256(); same contract, 48-byte digest hex-encoded.
        quit $$encode^STDHEX($$sha384Bytes(data))
        ;
sha512(data)    ; 128-char lowercase hex SHA-512 digest of data.
        ; doc: See sha256(); same contract, 64-byte digest hex-encoded.
        quit $$encode^STDHEX($$sha512Bytes(data))
        ;
sha256Bytes(data)       ; 32 raw bytes — SHA-256 digest of data.
        ; doc: Use this when you need to feed the digest into another binary
        ; doc: pipeline; otherwise sha256() is more convenient.
        new out
        set out=$$zeros($$shaLen("sha256"))
        if '$$dispatch3("crypto_sha256",data,.out,1) quit ""
        quit out
        ;
sha384Bytes(data)       ; 48 raw bytes — SHA-384 digest of data.
        new out
        set out=$$zeros($$shaLen("sha384"))
        if '$$dispatch3("crypto_sha384",data,.out,1) quit ""
        quit out
        ;
sha512Bytes(data)       ; 64 raw bytes — SHA-512 digest of data.
        new out
        set out=$$zeros($$shaLen("sha512"))
        if '$$dispatch3("crypto_sha512",data,.out,1) quit ""
        quit out
        ;
        ; ---------- public API: HMAC ----------
        ;
hmacSha256(key,msg)     ; 64-char lowercase hex HMAC-SHA-256 of msg under key.
        ; doc: key may be any length (longer than the SHA-256 block size of
        ; doc: 64 bytes is fine — RFC 2104 specifies hashing the key down).
        ; doc: Empty key is technically permitted by RFC 2104 and produces
        ; doc: a deterministic result; do not rely on it for security.
        ; doc: Example:
        ; doc: write $$hmacSha256^STDCRYPTO("Jefe","what do ya want for nothing?")
        quit $$encode^STDHEX($$hmacSha256Bytes(key,msg))
        ;
hmacSha384(key,msg)     ; 96-char lowercase hex HMAC-SHA-384.
        quit $$encode^STDHEX($$hmacSha384Bytes(key,msg))
        ;
hmacSha512(key,msg)     ; 128-char lowercase hex HMAC-SHA-512.
        quit $$encode^STDHEX($$hmacSha512Bytes(key,msg))
        ;
hmacSha256Bytes(key,msg)        ; 32 raw bytes — HMAC-SHA-256.
        new out
        set out=$$zeros($$shaLen("sha256"))
        if '$$dispatch4("crypto_hmac_sha256",key,msg,.out) quit ""
        quit out
        ;
hmacSha384Bytes(key,msg)        ; 48 raw bytes — HMAC-SHA-384.
        new out
        set out=$$zeros($$shaLen("sha384"))
        if '$$dispatch4("crypto_hmac_sha384",key,msg,.out) quit ""
        quit out
        ;
hmacSha512Bytes(key,msg)        ; 64 raw bytes — HMAC-SHA-512.
        new out
        set out=$$zeros($$shaLen("sha512"))
        if '$$dispatch4("crypto_hmac_sha512",key,msg,.out) quit ""
        quit out
        ;
        ; ---------- public API: probe ----------
        ;
available()     ; 1 iff std_crypto callout is loaded and resolves.
        ; doc: Pre-flight probe — never raises. Use to gate code that needs
        ; doc: cryptographic primitives before any sensitive operation.
        ; doc: Example: if '$$available^STDCRYPTO() s $ec=",U-MYAPP-NO-CRYPTO,"
        new ok,probe
        set ok=0
        set probe=$$sha256Bytes("")
        if $length(probe)=$$shaLen("sha256") set ok=1
        set $ecode=""
        quit ok
        ;
        ; ---------- internal helpers ----------
        ;
shaLen(name)    ; Digest size in bytes for the named algorithm.
        ; doc: Internal — keeps the magic-number table out of the call sites.
        if name="sha256" quit 32
        if name="sha384" quit 48
        if name="sha512" quit 64
        set $ecode=",U-STDCRYPTO-BAD-ALGO,"
        quit 0
        ;
dispatch3(sym,inp,out,isDigest) ; Invoke $ZF(sym, inp, .out).
        ; doc: Internal — wraps $ZF in an XECUTE'd command string so
        ; doc: m fmt cannot mangle the $ZF token (longest-prefix bug
        ; doc: against $ZFIND). Returns 1 on success, 0 on failure with
        ; doc: $ECODE set. isDigest selects the failure error code.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set cmd="set rc=$ZF("""_sym_""",inp,.out)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDCRYPTO-CALLOUT-MISSING," quit 0
        if rc=0 quit 1
        if isDigest set $ecode=",U-STDCRYPTO-DIGEST-FAIL," quit 0
        set $ecode=",U-STDCRYPTO-HMAC-FAIL,"
        quit 0
        ;
dispatch4(sym,key,msg,out)      ; Invoke $ZF(sym, key, msg, .out).
        ; doc: Internal — same XECUTE-wrap rationale as dispatch3.
        new $etrap,rc,cmd
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set cmd="set rc=$ZF("""_sym_""",key,msg,.out)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDCRYPTO-CALLOUT-MISSING," quit 0
        if rc=0 quit 1
        set $ecode=",U-STDCRYPTO-HMAC-FAIL,"
        quit 0
        ;
zeros(n)        ; n NUL bytes — pre-allocates the O:ydb_string_t* output.
        ; doc: Internal — YDB callouts need the M-side string at full length
        ; doc: before the callout writes into it; the C side updates the
        ; doc: ydb_string_t.length to the actual digest size on return.
        new buf,i
        set buf=""
        for i=1:1:n  set buf=buf_$char(0)
        quit buf
        ;
