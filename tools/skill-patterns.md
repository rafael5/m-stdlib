# m-stdlib — canonical patterns

A copy-paste-ready idiom library for the most frequent m-stdlib
tasks. Each pattern is a 5-15 line M block that runs as-is once the
named symbols are on the routine path. Patterns assume the calling
code lives at `routine indent` (one tab / 8 spaces) per the
modern-pythonic style; keep that indent when pasting.

For one specific symbol, prefer `m doc <module>.<label>` from a
terminal. This file is the high-frequency-task catalogue, not the
exhaustive reference (`manifest-index.md` carries that).

---

## Test suite — STDASSERT

The minimum viable suite that `m test` discovers and runs. Replace
`STDFOO` with your module name; the runner picks up every label
whose name starts with `t<UpperCase>` and a `;@TEST "..."`
annotation.

```m
STDFOOTST	; Test suite for STDFOO.
	new pass,fail
	do start^STDASSERT(.pass,.fail)
	;
	do tParseRoundTrips(.pass,.fail)
	;
	do report^STDASSERT(pass,fail)
	quit
	;
tParseRoundTrips(pass,fail)	;@TEST "parse round-trips a known input"
	new tree
	do eq^STDASSERT(.pass,.fail,$$parse^STDFOO("x",.tree),1,"parse returns 1")
	do eq^STDASSERT(.pass,.fail,$$type^STDFOO(.tree),"object","root is object")
	quit
	;
```

Every assertion takes `.pass,.fail` by-reference plus a description
string. `$$raises^STDASSERT` for $ECODE assertions; `$$contains` for
substring; `$$near` for float-with-epsilon.

---

## Per-test isolation — STDFIX `with`

Wrap any test body that touches globals so its writes get rolled
back before the next test runs. The helper opens a YDB transaction,
XECUTEs your code, then `trollback`s exactly the level it opened —
outer transactions stay alive.

```m
do with^STDFIX("test-isolation","do tBody^STDFOOTST(.pass,.fail)")
```

The string second argument is M code; for a more complex setup
register a fixture once and `invoke` it per-test:

```m
do register^STDFIX("dbReset","do reset^MYAPP","do drop^MYAPP")
do invoke^STDFIX("dbReset","do tCheck^MYTST(.pass,.fail)")
```

---

## Mocking — STDMOCK

Test-time call interception. Production code that wants to be
mockable calls through `do invoke^STDMOCK(target,.args)` instead of
`do @target@(.args)`; tests register a stub before invoking.

```m
do register^STDMOCK("EN^DIE","stub^DIETST")
new args set args(1)=42
do invoke^STDMOCK("EN^DIE",.args)
write $$called^STDMOCK("EN^DIE")	; 1
do clear^STDMOCK
```

m-cli's test runner clears the registry between cases automatically.

---

## Structured logging — STDLOG

One-line key=value emitter. Up to 5 (k,v) pairs per call. The level
sets the threshold; sub-threshold lines are dropped at no cost.

```m
do LEVEL^STDLOG("INFO")
do INFO^STDLOG("login","user","alice","ip","1.2.3.4")
do WARN^STDLOG("retry","attempt","3")
do ERROR^STDLOG("db_failed","sqlcode","-803")
```

Switch to JSON-line output with `do FORMAT^STDLOG("json")`. Sinks:
`SINK^STDLOG("stderr"|"stdout"|"global"|"global:^MYLOG")`.

---

## JSON — STDJSON

Parse-then-walk. The tree is a caller-owned local; each node
carries a one-character sigil (`o`/`a`/`s:`/`n:`/`t`/`f`/`z`).

```m
new tree
if '$$parse^STDJSON(jsonText,.tree) write "json error: ",$$lastError^STDJSON(),! quit
if $$type^STDJSON(.tree)="array" do
. new i
. set i=""
. for  set i=$order(tree(i)) quit:i=""  do
. . write "  ",i,": ",$$valueOf^STDJSON(.tree(i)),!
```

Round-trip with `$$encode^STDJSON(.tree)`. `parseFile` /
`writeFile` for whole-file IO.

---

## URLs — STDURL

Parse, encode, decode, normalise, resolve relative references.

```m
new parts
do parse^STDURL("https://example.com/foo?x=1",.parts)
write parts("scheme"),!	; "https"
write parts("host"),!	; "example.com"
write parts("path"),!	; "/foo"
write $$encode^STDURL("hello world",""),!	; "hello%20world"
write $$resolve^STDURL("http://a/b/c","../g"),!	; "http://a/b/g"
```

`$$valid^STDURL` is the strict gate; `$$decode` is lenient (matches
Python `urllib.parse.unquote`).

---

## CSV — STDCSV

RFC-4180 parser/writer. `parse` populates `rows(i,j)`; `write`
inverts; `parseFile` streams a file dispatching one callback per
record.

```m
new rows
set n=$$parse^STDCSV("a,b,c"_$char(13,10)_"1,2,3"_$char(13,10),.rows)
write n,!	; 2
write rows(1,1),"/",rows(2,3),!	; "a/3"
```

`parseFile^STDCSV(path,"onrow^MYAPP")` invokes `onrow^MYAPP(rownum,
.fields)` per record — handy for streaming files larger than memory.

---

## Datetime — STDDATE

ISO-8601 ↔ `$HOROLOG`. `now` is the canonical "now" (always UTC,
trailing Z). `add`/`diff` for ISO-8601 duration arithmetic.

```m
write $$now^STDDATE(),!	; "2026-05-08T17:42:31.123Z"
write $$fromh^STDDATE("47117,0"),!	; "1970-01-01T00:00:00"
write $$toh^STDDATE("1970-01-01"),!	; "47117,0"
write $$add^STDDATE("47117,0","P1DT2H30M"),!	; "47118,9000"
write $$diff^STDDATE("47117,0","47118,3600"),!	; "P1DT1H"
```

`strftime`/`strptime` for POSIX-style format strings.

---

## Cryptographic random — STDCSPRNG

Kernel CSPRNG via `/dev/urandom` or `$ZF→getrandom(2)`. **Use this
instead of `$RANDOM` for any token, key, or nonce.**

```m
write $$bytes^STDCSPRNG(16),!	; 16 random bytes
write $$hex^STDCSPRNG(16),!	; 32-char hex token
write $$base64^STDCSPRNG(32),!	; ~43-char URL-safe token
write $$token^STDCSPRNG(22),!	; 22-char [A-Za-z0-9_-] token
write $$int^STDCSPRNG(1,6),!	; fair 6-sided die
write $$uuid4^STDCSPRNG(),!	; cryptographically strong UUID v4
```

---

## SHA digests + HMAC — STDCRYPTO

`$&stdcrypto.fn → libcrypto`. Suffix with `Bytes` for raw 32/48/64
bytes; without for lowercase hex.

```m
write $$sha256^STDCRYPTO("abc"),!	; "ba7816bf..."
write $$hmacSha256^STDCRYPTO("key","msg"),!	; lowercase hex MAC
if '$$available^STDCRYPTO() set $ec=",U-MYAPP-NO-CRYPTO," quit
```

Pre-flight with `$$available` — never raises; clears `$ECODE` on
the way out.

---

## Compression — STDCOMPRESS

gzip / deflate / zstd via `$&stdcompress.fn → libz + libzstd`.
Output goes into a by-ref `out` byte string; the function returns
1 on success / 0 on failure with `$ECODE` set.

```m
new compressed,raw
do gzip^STDCOMPRESS("the quick brown fox",.compressed)
do gunzip^STDCOMPRESS(compressed,.raw)
write raw,!	; "the quick brown fox"
do zstdCompress^STDCOMPRESS(payload,.zbuf,3)	; level 1..22
```

Output capped at 1 MiB per call (YDB string-length limit on r2.02).

---

## HTTP — STDHTTP

libcurl-backed `$$get` / `$$post` / `$$request`. Soft-fails to
`resp("error")="STDHTTP-NOT-WIRED"` when the callout descriptor
isn't deployed.

```m
new resp
set status=$$get^STDHTTP("https://example.com",.resp)
write status,!	; 200
write resp("body"),!
write resp("header","content-type"),!	; lowercase keys
```

For POST with a typed body:
```m
set status=$$post^STDHTTP("https://example.com/api",payload,.resp,"application/json")
```

---

## Argparse — STDARGS

CLI parser handle. Register flags / positionals / sub-commands,
then `parse` against `$ZCMDLINE`.

```m
new p,ns
set p=$$new^STDARGS("widget","frob the widget")
do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
do addpos^STDARGS(p,"path","path")
do parse^STDARGS(p,$zcmdline,.ns)
write ns("path"),! write ns("verbose"),!
do free^STDARGS(p)
```

Actions: `store_true` / `store` / `count` / `append`. Sub-commands
via `addsub` + a child parser handle.

---

## File I/O — STDFS

Text-mode `readFile`/`writeFile`/`readLines`/`writeLines`.
Byte-faithful `readBytes`/`writeBytes`/`appendBytes` via $ZF→libc.
Path manipulation: `basename`/`dirname`/`join`. Existence:
`exists`/`size`.

```m
do writeFile^STDFS("/tmp/note.txt","hello, world")
write $$readFile^STDFS("/tmp/note.txt"),!	; "hello, world"
write $$exists^STDFS("/tmp/note.txt"),!	; 1
do remove^STDFS("/tmp/note.txt")

new lines
do readLines^STDFS("/etc/hosts",.lines)
write lines(1),!	; first line, CRLF normalised
```

For binary data use `writeBytes` / `readBytes` — they bypass YDB's
SEQ-device record-terminator handling.

---

## Snapshot testing — STDSNAP

Capture the canonical line-per-leaf dump of a tree, save it to a
file, and assert it matches on subsequent runs. Pairs with
STDASSERT for the assertion-counter integration.

```m
new cfg
do load^STDSEED("snapshots/cfg.tsv","fileViaDie^STDSEED")
do asserts^STDSNAP(.pass,.fail,"snapshots/cfg.snap",.cfg,"config matches baseline")
```

m-cli's `m test --update-snapshots` flips a sentinel that makes
`asserts` rewrite the baseline instead of comparing — useful after
intentional changes to the rendered shape.
