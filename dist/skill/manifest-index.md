# m-stdlib — manifest index

m-stdlib v0.5.0; 32 modules; 284 public labels.

Generated from `dist/stdlib-manifest.json`. One entry per module
with every public label: signature on the left, synopsis on the
right. For full per-label detail (params, returns, raises,
examples, source location), use `m doc <module>.<label>`.

## `STDARGS`

argparse (v0.0.7).

- `do addflag^STDARGS(p, long, short, action, dest)` — Register a flag.
- `do addpos^STDARGS(p, name, dest)` — Register a positional argument.
- `do addsub^STDARGS(p, name, sub)` — Register a sub-command -> sub-parser handle.
- `do free^STDARGS(p)` — Release a parser's state.
- `$$help^STDARGS(p)` — Return formatted help text.
- `$$new^STDARGS(prog, desc)` — Allocate a fresh parser handle.
- `do parse^STDARGS(p, argline, ns)` — Parse argline; populate ns(dest)=value.

_raises: `U-STDARGS-MISSING-POSITIONAL`, `U-STDARGS-MISSING-VALUE`, `U-STDARGS-UNKNOWN-ACTION`, `U-STDARGS-UNKNOWN-FLAG`, `U-STDARGS-UNKNOWN-SUBCOMMAND`_

## `STDASSERT`

assertion library (v0.0.1).

- `do contains^STDASSERT(p, f, haystack, needle, desc)` — Assert haystack contains needle (M's "[" operator).
- `do eq^STDASSERT(p, f, actual, expected, desc)` — Assert actual=expected (string equality).
- `do false^STDASSERT(p, f, cond, desc)` — Assert cond is falsy (zero numeric prefix or empty).
- `do len^STDASSERT(p, f, actual, n, desc)` — Assert actual=n (length comparison helper).
- `do ne^STDASSERT(p, f, actual, expected, desc)` — Assert actual'=expected (string inequality).
- `do near^STDASSERT(p, f, a, b, eps, desc)` — Assert |a-b|<=eps (float comparison).
- `do raises^STDASSERT(p, f, code, errno, desc)` — Assert XECUTEing 'code' sets $ECODE containing 'errno'.
- `do report^STDASSERT(p, f)` — Print summary; halt with error if any failures.
- `do start^STDASSERT(p, f)` — Initialise pass/fail counters (call by-reference).
- `do true^STDASSERT(p, f, cond, desc)` — Assert cond is truthy (non-zero numeric prefix).

## `STDB64`

RFC-4648 Base64 (standard + URL-safe).

- `$$decode^STDB64(text)` — Inverse of encode(); accepts standard alphabet + '=' padding.
- `$$encode^STDB64(data)` — Standard base64 (RFC-4648 §4) with padding.
- `$$urldecode^STDB64(text)` — Decode URL-safe base64; padding may be present or omitted.
- `$$urlencode^STDB64(data)` — URL-safe base64 (RFC-4648 §5) without padding.
- `$$valid^STDB64(text)` — True iff text is well-formed standard base64 with padding.

## `STDCACHE`

LRU + TTL cache over a caller-owned local array.

- `$$capacity^STDCACHE(cache)` — Return the declared capacity (0 = unlimited).
- `do clear^STDCACHE(cache)` — Drop every entry; preserve capacity / TTL settings.
- `$$get^STDCACHE(cache, key)` — Return the cached value, or "" if absent / expired. Touches recency.
- `$$has^STDCACHE(cache, key)` — Return 1 iff key is present and not expired; reap if expired.
- `do new^STDCACHE(cache, capacity, ttl)` — Initialise cache with optional capacity / TTL.
- `do put^STDCACHE(cache, key, value)` — Insert / update. Promotes the key to most-recent. May evict.
- `do remove^STDCACHE(cache, key)` — Delete one entry. Idempotent — no-op if key is absent.
- `$$size^STDCACHE(cache)` — Return the current entry count.

## `STDCOLL`

collections (Set, Map, Stack, Queue, Deque, Heap, OrderedDict).

- `do dequeClear^STDCOLL(d)` — Drop every entry.
- `$$dequePeekBack^STDCOLL(d)` — Return back without removal; "" when empty.
- `$$dequePeekFront^STDCOLL(d)` — Return front without removal; "" when empty.
- `$$dequePopBack^STDCOLL(d)` — Pop and return the back; "" when empty.
- `$$dequePopFront^STDCOLL(d)` — Pop and return the front; "" when empty.
- `do dequePushBack^STDCOLL(d, value)` — Push value at the back.
- `do dequePushFront^STDCOLL(d, value)` — Push value at the front.
- `$$dequeSize^STDCOLL(d)` — Return deque length.
- `do heapClear^STDCOLL(h)` — Drop every entry.
- `$$heapPeek^STDCOLL(h)` — Return value at min key without removal; "" when empty.
- `$$heapPeekKey^STDCOLL(h)` — Return min key without removal; "" when empty.
- `$$heapPop^STDCOLL(h)` — Pop value at the min key; "" when empty.
- `$$heapPopKey^STDCOLL(h)` — Pop and return the min key; "" when empty.
- `do heapPush^STDCOLL(h, key, value)` — Push (key, value) onto the heap.
- `$$heapSize^STDCOLL(h)` — Return heap size.
- `do mapClear^STDCOLL(m)` — Drop every entry.
- `$$mapGet^STDCOLL(m, key, default)` — Return value at key; default if absent.
- `$$mapHas^STDCOLL(m, key)` — Return 1 iff key is set.
- `$$mapNext^STDCOLL(m, prev)` — Return next key after prev in $order; "" at end.
- `do mapPut^STDCOLL(m, key, value)` — Store value at key (overwrites).
- `do mapRemove^STDCOLL(m, key)` — Drop key (no-op when absent).
- `$$mapSize^STDCOLL(m)` — Return number of keys.
- `do odictClear^STDCOLL(o)` — Drop every entry.
- `$$odictFirst^STDCOLL(o)` — Return first key in insertion order; "" when empty.
- `$$odictGet^STDCOLL(o, key, default)` — Return value at key; default if absent.
- `$$odictHas^STDCOLL(o, key)` — Return 1 iff key is set.
- `$$odictLast^STDCOLL(o)` — Return last key in insertion order; "" when empty.
- `$$odictNext^STDCOLL(o, prev)` — Return next key (insertion order) after prev; "" at end.
- `$$odictPrev^STDCOLL(o, next)` — Return previous key (insertion order) before next; "" at start.
- `do odictPut^STDCOLL(o, key, value)` — Store value at key; create-or-update preserving position.
- `do odictRemove^STDCOLL(o, key)` — Drop key (no-op when absent).
- `$$odictSize^STDCOLL(o)` — Return number of keys.
- `do queueClear^STDCOLL(q)` — Drop every entry.
- `$$queuePeek^STDCOLL(q)` — Return front without removal; "" when empty.
- `$$queuePop^STDCOLL(q)` — Dequeue at front; "" when empty.
- `do queuePush^STDCOLL(q, value)` — Enqueue at back.
- `$$queueSize^STDCOLL(q)` — Return queue length.
- `do setAdd^STDCOLL(s, value)` — Add value to set s (idempotent).
- `do setClear^STDCOLL(s)` — Drop every member.
- `$$setHas^STDCOLL(s, value)` — Return 1 iff value is a member of set s.
- `$$setNext^STDCOLL(s, prev)` — Return the next member after prev in $order; "" at end.
- `do setRemove^STDCOLL(s, value)` — Remove value from set s; absent values are no-ops.
- `$$setSize^STDCOLL(s)` — Return cardinality.
- `do stackClear^STDCOLL(s)` — Drop every entry.
- `$$stackPeek^STDCOLL(s)` — Return the top without removal; "" when empty.
- `$$stackPop^STDCOLL(s)` — Remove and return the top; "" when empty.
- `do stackPush^STDCOLL(s, value)` — Push value on top of the stack.
- `$$stackSize^STDCOLL(s)` — Return depth.

## `STDCOMPRESS`

gzip / deflate / zstd via $&stdcompress callouts.

- `$$available^STDCOMPRESS()` — "" iff both libz and libzstd loaded; else missing list.
- `do deflate^STDCOMPRESS(data, out, level)` — RFC 1951 raw deflate (no header / trailer).
- `do gunzip^STDCOMPRESS(data, out)` — RFC 1952 gunzip.
- `do gzip^STDCOMPRESS(data, out, level)` — RFC 1952 gzip-format compress.
- `do inflate^STDCOMPRESS(data, out)` — RFC 1951 raw inflate.
- `do zstdCompress^STDCOMPRESS(data, out, level)` — Zstandard (RFC 8478) compress.
- `do zstdDecompress^STDCOMPRESS(data, out)` — Zstandard decompress.

_raises: `U-STDCOMPRESS-BAD-LEVEL`, `U-STDCOMPRESS-CALLOUT-MISSING`, `U-STDCOMPRESS-LIBZ-FAIL`, `U-STDCOMPRESS-LIBZSTD-FAIL`_

## `STDCRYPTO`

Cryptographic digests via $&stdcrypto → libcrypto.

- `$$available^STDCRYPTO()` — 1 iff std_crypto callout is loaded and resolves.
- `$$hmacSha256^STDCRYPTO(key, msg)` — 64-char lowercase hex HMAC-SHA-256 of msg under key.
- `$$hmacSha256Bytes^STDCRYPTO(key, msg)` — 32 raw bytes — HMAC-SHA-256.
- `$$hmacSha384^STDCRYPTO(key, msg)` — 96-char lowercase hex HMAC-SHA-384.
- `$$hmacSha384Bytes^STDCRYPTO(key, msg)` — 48 raw bytes — HMAC-SHA-384.
- `$$hmacSha512^STDCRYPTO(key, msg)` — 128-char lowercase hex HMAC-SHA-512.
- `$$hmacSha512Bytes^STDCRYPTO(key, msg)` — 64 raw bytes — HMAC-SHA-512.
- `$$sha256^STDCRYPTO(data)` — 64-char lowercase hex SHA-256 digest of data.
- `$$sha256Bytes^STDCRYPTO(data)` — 32 raw bytes — SHA-256 digest of data.
- `$$sha384^STDCRYPTO(data)` — 96-char lowercase hex SHA-384 digest of data.
- `$$sha384Bytes^STDCRYPTO(data)` — 48 raw bytes — SHA-384 digest of data.
- `$$sha512^STDCRYPTO(data)` — 128-char lowercase hex SHA-512 digest of data.
- `$$sha512Bytes^STDCRYPTO(data)` — 64 raw bytes — SHA-512 digest of data.

_raises: `U-STDCRYPTO-CALLOUT-MISSING`, `U-STDCRYPTO-DIGEST-FAIL`, `U-STDCRYPTO-HMAC-FAIL`_

## `STDCSPRNG`

Cryptographic random (kernel CSPRNG via getrandom(2) | /dev/urandom).

- `$$available^STDCSPRNG()` — Return 1 iff /dev/urandom is openable for reading; else 0.
- `$$base64^STDCSPRNG(n)` — Return URL-safe base64 of n random bytes (no padding).
- `$$bytes^STDCSPRNG(n)` — Return n random bytes from the kernel CSPRNG.
- `$$hex^STDCSPRNG(n)` — Return 2n lowercase hex chars representing n random bytes.
- `$$int^STDCSPRNG(min, max)` — Return uniform integer in [min, max] (inclusive both ends).
- `$$token^STDCSPRNG(n)` — Return an n-char URL-safe token from alphabet [A-Za-z0-9_-].
- `$$useCallout^STDCSPRNG()` — Return 1 iff the cs_random callout resolves; else 0.
- `$$uuid4^STDCSPRNG()` — Return a cryptographically strong RFC-4122 v4 UUID.

_raises: `U-STDCSPRNG-BAD-COUNT`, `U-STDCSPRNG-BAD-RANGE`, `U-STDCSPRNG-OPEN-FAIL`_

## `STDCSV`

RFC-4180 CSV parser/writer (pure-M).

- `$$parse^STDCSV(text, rows)` — Parse CSV text into rows(i,j); return row count.
- `do parseFile^STDCSV(path, callback)` — Parse file at path; dispatch callback per record.
- `$$write^STDCSV(rows)` — Serialise rows(i,j) to RFC-4180 CSV text.
- `do writeFile^STDCSV(path, rows)` — Serialise rows(i,j) and write to path as RFC-4180 CSV.

_raises: `U-STDCSV-OPEN-FAIL`_

## `STDDATE`

ISO-8601 datetime + arithmetic (v0.0.5).

- `$$add^STDDATE(h, dur)` — Add an ISO-8601 duration to a horolog. Negative prefix "-P..." accepted.
- `$$diff^STDDATE(h1, h2)` — Return h2 - h1 as an ISO-8601 duration.
- `$$fromh^STDDATE(h)` — Format a $HOROLOG (2/3/4-piece) as ISO-8601.
- `$$now^STDDATE()` — Return current time as ISO-8601 UTC with millisecond precision.
- `$$strftime^STDDATE(h, fmt)` — Format a horolog per a strftime-style format string.
- `$$strptime^STDDATE(text, fmt)` — Parse text per format string into a horolog.
- `$$toh^STDDATE(iso)` — Parse an ISO-8601 string into $HOROLOG form.

_raises: `U-STDDATE-BAD-DUR`, `U-STDDATE-BAD-HOROLOG`, `U-STDDATE-BAD-ISO`_

## `STDENV`

.env file loader with typed accessors.

- `$$get^STDENV(env, key, default)` — Return env(key); else default.
- `$$getBool^STDENV(env, key, default)` — Return env(key) interpreted as boolean; default if missing or unrecognized.
- `$$getFloat^STDENV(env, key, default)` — Return env(key) coerced to float; default if missing or non-numeric.
- `$$getInt^STDENV(env, key, default)` — Return env(key) coerced to integer; default if missing or non-numeric.
- `$$has^STDENV(env, key)` — Return 1 iff key is defined in env; else 0.
- `$$parse^STDENV(text, env)` — Parse .env text into env tree; return 1 on success, 0 on parse error.
- `$$parseFile^STDENV(path, env)` — Read path via STDFS and parse the contents.
- `$$valid^STDENV(text)` — Return 1 iff text is parseable as .env. Discards the result.

_raises: `U-STDFS-OPEN-FAIL`_

## `STDFIX`

fixture lifecycle and per-test isolation.

- `$$active^STDFIX()` — Predicate — is any nested transaction currently open?
- `do cleanup^STDFIX()` — Best-effort rollback of any leaked transaction scope.
- `do invoke^STDFIX(tag, code)` — Run code with registered hooks wrapping it.
- `do register^STDFIX(tag, setupCode, teardownCode)` — Declare a reusable setup/teardown pair.
- `do with^STDFIX(tag, code)` — XECUTE code inside an auto-managed transaction scope.

_raises: `U-STDFIX-EMPTY-TAG`, `U-STDFIX-UNREGISTERED-TAG`_

## `STDFMT`

printf-style formatter (subset of Python str.format).

- `$$f^STDFMT(template, a1, a2, a3, a4, a5, a6, a7, a8, a9)` — Positional formatter (up to 9 args).
- `$$fn^STDFMT(template, args)` — Named formatter (lookups in the passed array).

_raises: `U-STDFMT-MISSING-ARG`, `U-STDFMT-UNCLOSED-BRACE`, `U-STDFMT-UNESCAPED-RBRACE`, `U-STDFMT-UNKNOWN-TYPE`_

## `STDFS`

File-system primitives (text I/O, path manipulation, bytes).

- `do append^STDFS(path, data)` — Append data to path; create the file if missing.
- `do appendBytes^STDFS(path, data)` — Append data to path via O_APPEND — atomic at EOF, byte-faithful.
- `$$available^STDFS()` — 1 iff the stdfs callout is loaded and open(2) is reachable.
- `$$basename^STDFS(path)` — Return the last component of path.
- `$$dirname^STDFS(path)` — Return the parent path (everything but the last component).
- `do exists^STDFS(path)` — Return 1 iff path exists; else 0.
- `$$join^STDFS(left, right)` — POSIX path join: absolute right replaces left.
- `$$readBytes^STDFS(path)` — Return file content as a byte string — no CR/LF normalisation.
- `$$readFile^STDFS(path)` — Return file content as a string (lines joined by $C(10)).
- `do readLines^STDFS(path, lines)` — Read path into lines(1..N) (1-indexed; CRLF normalised).
- `do remove^STDFS(path)` — Delete path; idempotent (no-op if already absent).
- `$$size^STDFS(path)` — Return size of path in bytes; -1 if missing or unreadable.
- `do writeBytes^STDFS(path, data)` — Write data to path verbatim — no trailing LF, no transcoding.
- `do writeFile^STDFS(path, data)` — Write data to path (overwrite if exists).
- `do writeLines^STDFS(path, lines)` — Write lines(1..N) to path, separated and terminated by LF.

_raises: `U-STDFS-NOT-WIRED`, `U-STDFS-OPEN-FAIL`, `U-STDFS-READ-TRUNCATED`, `U-STDFS-REMOVE-FAIL`_

## `STDHEX`

RFC-4648 §8 hex encoding (lowercase by default).

- `$$decode^STDHEX(text)` — Case-insensitive hex → bytes.
- `$$encode^STDHEX(data)` — Lowercase hex (RFC-4648 §8 default form).
- `$$encodeu^STDHEX(data)` — Uppercase hex.
- `$$valid^STDHEX(text)` — True iff text is well-formed hex (any case).

## `STDHTTP`

HTTP/1.1 client (track H3, target tag v0.4.0).

- `$$available^STDHTTP()` — 1 iff the libcurl callout is loaded and curl_easy_init() works.
- `$$buildRequest^STDHTTP(req)` — Assemble an HTTP/1.1 request message from req array.
- `$$formatHeaders^STDHTTP(headers)` — Join headers(name)=value into a CRLF-terminated header block.
- `$$get^STDHTTP(url, resp)` — HTTP GET shortcut. Returns numeric status code, or 0 on error.
- `do parseHeader^STDHTTP(line, name, value)` — Split "Name: value" into (name, value).
- `do parseResponse^STDHTTP(raw, resp)` — Parse a complete HTTP/1.1 response message.
- `do parseStatusLine^STDHTTP(line, s)` — Split an HTTP/1.1 status line into version/code/reason.
- `$$post^STDHTTP(url, body, resp, contentType)` — HTTP POST shortcut. Defaults Content-Type to application/octet-stream.
- `$$request^STDHTTP(req, resp)` — Generic HTTP request. Returns numeric status code, or 0 on error.

## `STDJSON`

RFC 8259 JSON parser + serialiser.

- `$$encode^STDJSON(node)` — Serialise `node` to JSON text.
- `$$lastError^STDJSON()` — Return the message from the most recent failed parse.
- `$$parse^STDJSON(text, root)` — Parse `text` into `root`. Returns 1/0.
- `do parseFile^STDJSON(path, root)` — Stream-read `path`, parse into `root`.
- `$$type^STDJSON(node)` — Return the JSON type label of `node` (or "" if undef).
- `$$valid^STDJSON(text)` — True iff `text` is conformant RFC-8259 JSON.
- `$$valueOf^STDJSON(node)` — Return the scalar value for s/n leaves; "" otherwise.
- `do writeFile^STDJSON(path, node)` — Serialise `node` and write to `path`.

_raises: `U-STDJSON-ENCODE`, `U-STDJSON-PARSE`_

## `STDLOG`

structured key=value logger (v0.0.4).

- `do DEBUG^STDLOG(event, k1, v1, k2, v2, k3, v3, k4, v4, k5, v5)` — Emit a DEBUG line.
- `do ERROR^STDLOG(event, k1, v1, k2, v2, k3, v3, k4, v4, k5, v5)` — Emit an ERROR line.
- `do FATAL^STDLOG(event, k1, v1, k2, v2, k3, v3, k4, v4, k5, v5)` — Emit a FATAL line.
- `do FORMAT^STDLOG(name)` — Select line-rendering format. "kv" (default) or "json".
- `do INFO^STDLOG(event, k1, v1, k2, v2, k3, v3, k4, v4, k5, v5)` — Emit an INFO line (default level).
- `do LEVEL^STDLOG(threshold)` — Set the runtime threshold. Levels at or above pass.
- `do SINK^STDLOG(target)` — Configure where log lines go.
- `do WARN^STDLOG(event, k1, v1, k2, v2, k3, v3, k4, v4, k5, v5)` — Emit a WARN line.

_raises: `U-STDLOG-INVALID-FORMAT`, `U-STDLOG-INVALID-LEVEL`, `U-STDLOG-INVALID-SINK`_

## `STDMATH`

Numeric helpers (clamp / min / max / sum / count / mean over arrays).

- `$$clamp^STDMATH(x, lo, hi)` — Clamp x into [lo, hi]. Returns lo if x<lo, hi if x>hi, else x.
- `$$count^STDMATH(arr)` — Number of $ORDER-visible values at depth 1. 0 if empty.
- `$$max^STDMATH(arr)` — Largest value in arr. "" if empty.
- `$$mean^STDMATH(arr)` — Arithmetic mean = sum / count. "" if arr is empty (no /0).
- `$$min^STDMATH(arr)` — Smallest value in arr (1st-level $ORDER walk). "" if empty.
- `$$sum^STDMATH(arr)` — Sum of arr's values (unary-+ coercion). 0 if empty.

## `STDMOCK`

opt-in test-time call interception (mock registry).

- `$$args^STDMOCK(target, n, i)` — Return arg i of call n for target; "" if absent.
- `$$called^STDMOCK(target)` — Number of invocations for target since clear / unregister.
- `do clear^STDMOCK()` — Remove every redirect, counter, and recorded args list.
- `do invoke^STDMOCK(target, args)` — Record this call + invoke resolve(target).
- `do register^STDMOCK(target, replacement)` — Record a target -> replacement redirect.
- `$$resolve^STDMOCK(target)` — Return the replacement if registered, else target itself.
- `do unregister^STDMOCK(target)` — Remove one redirect (idempotent).

## `STDOS`

Process / env / cmdline helpers (YDB-only v1).

- `$$arg^STDOS(i)` — Return the i-th $ZCMDLINE argument (1-indexed); "" if out of bounds.
- `$$argc^STDOS()` — Return the number of $ZCMDLINE arguments.
- `do argv^STDOS(args)` — Populate args(1..N) from $ZCMDLINE; N is the implicit return.
- `$$cmdline^STDOS()` — Return the raw $ZCMDLINE string.
- `$$cwd^STDOS()` — Return the current working directory (from $PWD).
- `$$env^STDOS(name)` — Return the value of environment variable `name`, or "" if unset.
- `do exit^STDOS(rc)` — Terminate the YDB process with exit code rc (default 0).
- `$$hostname^STDOS()` — Return the host name (from $HOSTNAME) or "" if unset.
- `$$pid^STDOS()` — Return the current process ID as an integer.
- `$$splitArgs^STDOS(s, args)` — Tokenise `s` on whitespace; populate args(1..N); return N.
- `$$user^STDOS()` — Return the current username (from $USER).

## `STDPROF`

Wall-clock profiler with per-tag aggregates + percentiles.

- `do clear^STDPROF(prof)` — Drop every tag's data; preserves nothing.
- `$$count^STDPROF(prof, tag)` — Return number of completed cycles for tag; 0 if untracked.
- `$$max^STDPROF(prof, tag)` — Return slowest sample; 0 if no cycles.
- `$$mean^STDPROF(prof, tag)` — Return total\count (integer floor); 0 if no cycles.
- `$$min^STDPROF(prof, tag)` — Return fastest sample; 0 if no cycles.
- `do new^STDPROF(prof)` — Initialise / wipe the profiler.
- `$$percentile^STDPROF(prof, tag, p)` — Return the p-th percentile sample (0..100).
- `do start^STDPROF(prof, tag)` — Open a timer for tag. Stamps prof("active",tag) with $ZHOROLOG.
- `do stop^STDPROF(prof, tag)` — Close the timer; record one sample. No-op if no matching start.
- `$$tags^STDPROF(prof, out)` — Populate out(1..N) with tag names that have at least one cycle.
- `$$total^STDPROF(prof, tag)` — Return sum of elapsed microseconds across all cycles; 0 if untracked.

## `STDREGEX`

regular expressions (track L12, v0.2.0).

- `$$compile^STDREGEX(pattern)` — Compile pattern into a handle.
- `$$find^STDREGEX(h, s)` — 1-indexed start of the first match in s; 0 if no match.
- `do findall^STDREGEX(h, s, out)` — Populate out(1..N) with every non-overlapping match text.
- `do free^STDREGEX(h)` — Release the compiled-pattern state.
- `do groups^STDREGEX(h, s, g)` — Populate g(0..N) with the full match text and each capture group.
- `$$match^STDREGEX(h, s)` — True iff the entire string s matches the pattern.
- `$$replace^STDREGEX(h, s, repl)` — Return s with every match replaced by repl.
- `$$search^STDREGEX(h, s)` — True iff any substring of s matches the pattern.
- `do split^STDREGEX(h, s, out)` — Populate out(1..N) with the segments of s between matches.
- `$$valid^STDREGEX(pattern)` — True iff pattern parses cleanly under the v0.2.0 subset.

_raises: `U-STDREGEX-BAD-PATTERN`, `U-STDREGEX-NO-MATCH`, `U-STDREGEX-UNSUPPORTED`_

## `STDSEED`

declarative test data loader (v0.1.3).

- `do clear^STDSEED(path)` — Drop bookkeeping for `path`. Idempotent.
- `do load^STDSEED(path, filer)` — Load manifest at `path` via `filer` (default FILE^DIE).
- `do loadJson^STDSEED(jsonText, filer)` — Load JSON-array manifest via `filer`.
- `$$loaded^STDSEED(path)` — Predicate — 1 iff `path` is currently loaded.
- `$$validate^STDSEED(path)` — Parse-only check — return 1 on success; raise on syntax error.

_raises: `U-STDSEED-FILE-NOT-FOUND`, `U-STDSEED-FILER-ERROR`, `U-STDSEED-INVALID-JSON`, `U-STDSEED-INVALID-MANIFEST`, `U-STDSEED-MISSING-FIELD`, `U-STDSEED-MISSING-FILE`_

## `STDSEMVER`

SemVer 2.0.0 parse / compare / range matching.

- `$$build^STDSEMVER(s)` — Return the build tail (no leading '+'); "" if absent or invalid.
- `$$compare^STDSEMVER(a, b)` — Return -1/0/1 per SemVer §11 precedence (build ignored).
- `$$major^STDSEMVER(s)` — Return the major component; "" if s is invalid.
- `$$matches^STDSEMVER(v, range)` — Return 1 iff v satisfies the range expression.
- `$$minor^STDSEMVER(s)` — Return the minor component; "" if s is invalid.
- `$$parse^STDSEMVER(s, v)` — Populate v(1..5)=major,minor,patch,prerelease,build; return 1/0.
- `$$patch^STDSEMVER(s)` — Return the patch component; "" if s is invalid.
- `$$prerelease^STDSEMVER(s)` — Return the prerelease tail (no leading '-'); "" if absent or invalid.
- `$$valid^STDSEMVER(s)` — Return 1 iff s is a valid SemVer 2.0.0 string; else 0.

## `STDSNAP`

Snapshot testing: serialize an M tree, diff against a baseline.

- `do asserts^STDSNAP(p, f, path, data, desc)` — STDASSERT-style snapshot assertion.
- `$$matches^STDSNAP(path, data)` — Return 1 iff serialize(data) equals the file's content.
- `do save^STDSNAP(path, data)` — Write serialize(data) to path. Overwrites if exists.
- `$$serialize^STDSNAP(data)` — Walk data tree; return the canonical line-per-leaf dump.

_raises: `U-STDFS-OPEN-FAIL`_

## `STDSTR`

String helpers (pad / trim / split / replaceAll / case / repeat).

- `$$endsWith^STDSTR(s, suffix)` — Return 1 iff s ends with suffix; else 0. Empty suffix → 1.
- `$$pad^STDSTR(s, n, c)` — Alias for padLeft — common numeric-formatting shorthand.
- `$$padLeft^STDSTR(s, n, c)` — Left-pad s to width n with c (default " "). Returns s unchanged
- `$$padRight^STDSTR(s, n, c)` — Right-pad s to width n with c (default " "). Returns s unchanged
- `$$repeat^STDSTR(s, n)` — Concatenate s with itself n times. Returns "" for n ≤ 0 or s="".
- `$$replaceAll^STDSTR(s, find, repl)` — Replace every non-overlapping left-to-right occurrence.
- `$$split^STDSTR(s, sep, out)` — Split s on sep; populate out(1..N); return N.
- `$$startsWith^STDSTR(s, prefix)` — Return 1 iff s begins with prefix; else 0. Empty prefix → 1.
- `$$toLowerASCII^STDSTR(s)` — A-Z → a-z; preserves all other characters.
- `$$toUpperASCII^STDSTR(s)` — a-z → A-Z; preserves all other characters.
- `$$trim^STDSTR(s)` — Strip leading and trailing whitespace (space / tab / LF / CR).
- `$$trimLeft^STDSTR(s)` — Strip leading whitespace only.
- `$$trimRight^STDSTR(s)` — Strip trailing whitespace only.

## `STDTOML`

TOML 1.0 parser (deliberately narrow v1 subset).

- `$$get^STDTOML(root, key)` — Return the value at key (dotted path); "" if absent.
- `$$parse^STDTOML(text, root)` — Parse TOML text into root tree; return 1 on success, 0 on parse error.
- `$$type^STDTOML(root, key)` — Return the type tag at key, or "" if absent.
- `$$valid^STDTOML(text)` — Return 1 iff text parses as valid TOML; else 0.

## `STDURL`

RFC 3986 URI parser, builder, encoder, resolver.

- `$$build^STDURL(parts)` — Reassemble parts into a URL string.
- `$$decode^STDURL(s)` — Percent-decode all valid %HH; leave malformed % as literal.
- `$$encode^STDURL(s, safe)` — Percent-encode s. Unreserved chars + chars in safe pass through.
- `$$normalize^STDURL(url)` — Apply RFC 3986 §6.2 syntax-based normalization.
- `do parse^STDURL(url, parts)` — Split url into parts(scheme/userinfo/host/port/path/query/fragment).
- `$$resolve^STDURL(base, ref)` — Resolve ref against base per RFC 3986 §5.3 (strict mode).
- `$$valid^STDURL(url)` — True iff url is a well-formed RFC 3986 URI (or relative reference).

## `STDUUID`

UUID v4 + v7 (RFC 4122 / RFC 9562).

- `$$v4^STDUUID()` — Return a new RFC-4122 v4 UUID.
- `$$v7^STDUUID()` — Return a new RFC-9562 v7 UUID (time-ordered).
- `$$valid^STDUUID(u)` — Return 1 iff u is a canonical 36-char hex UUID; else 0.
- `$$variant^STDUUID(u)` — Classify UUID variant from the high bits of position 20.
- `$$version^STDUUID(u)` — Return integer version (1..15) from position 15, or "" if invalid.

## `STDXFRM`

Higher-order array transforms (map / filter / reduce via @-indirection lambdas).

- `do filter^STDXFRM(in, expr, out)` — Copy in(k)→out(k) iff <expr> is truthy.
- `do map^STDXFRM(in, expr, out)` — out(k) := <expr> for each k in $ORDER(in,k).
- `$$reduce^STDXFRM(in, expr, init)` — Fold left: walk in, evaluate expr with `acc`+`value`+`key`.

## `STDXML`

XML parser (well-formed XML 1.0 subset, in-progress).

- `$$attr^STDXML(node, name)` — Return attribute value; "" if missing.
- `$$attrNs^STDXML(node, name)` — Return the namespace URI for an attribute; "" if unprefixed or absent.
- `$$childByName^STDXML(node, name, out)` — Find first child with `name`; merge into `.out`. 1/0.
- `$$childCount^STDXML(node)` — Return number of element children; 0 if none.
- `$$lastError^STDXML()` — Return the last parse error diagnostic; "" if none / parse succeeded.
- `$$ns^STDXML(node)` — Return the namespace URI for the element; "" if not in any namespace.
- `$$parse^STDXML(text, root)` — Parse text into root tree; return 1/0.
- `$$rootName^STDXML(node)` — Return the element tag name; "" if missing.
- `$$text^STDXML(node)` — Return direct text content; "" if no text.
- `$$valid^STDXML(text)` — Return 1 iff text parses as valid XML; else 0.
- `$$xpath^STDXML(tree, expr, results)` — Run an XPath query; populate results(1..N); return N.
- `$$xpathOne^STDXML(tree, expr, out)` — First match into .out; return 1/0.
- `$$xpathText^STDXML(tree, expr)` — Return the direct text of the first match; "" if none.

