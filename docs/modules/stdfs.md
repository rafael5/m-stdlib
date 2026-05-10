---
module: STDFS
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'File-system primitives (text I/O, path manipulation, bytes)'
labels: ['append', 'appendBytes', 'available', 'basename', 'dirname', 'exists', 'join', 'readBytes', 'readFile', 'readLines', 'remove', 'size', 'writeBytes', 'writeFile', 'writeLines']
errors: ['U-STDFS-NOT-WIRED', 'U-STDFS-OPEN-FAIL', 'U-STDFS-READ-TRUNCATED', 'U-STDFS-REMOVE-FAIL']
conformance: []
see_also: ['STDENV', 'STDSNAP']
---

# `STDFS` — File-system primitives

Read / write / append / exists / remove / size on regular text
files, plus three pure-string path manipulators (`basename`,
`dirname`, `join`). Centralises the YDB-style `OPEN`/`USE`/`READ`/
`WRITE`/`CLOSE` device dance so consumer modules don't have to
re-derive the deviceparam combinations or work around the
[`M-MOD-024`](../tracking/discoveries.md) lint false-positive.

## Public API

### Text I/O + path manipulation (pure-M, YDB SEQ device)

| Extrinsic | Signature | Returns |
|---|---|---|
| `readFile` | `$$readFile^STDFS(path)` | File content as a string (lines joined by `$C(10)`). |
| `writeFile` | `do writeFile^STDFS(path, data)` | Writes `data` to `path`, overwriting any existing file. |
| `append` | `do append^STDFS(path, data)` | Appends `data` to `path`; creates the file if missing. |
| `readLines` | `do readLines^STDFS(path, .lines)` | Populates `lines(1..N)` from file (one line per index). |
| `writeLines` | `do writeLines^STDFS(path, .lines)` | Writes `lines(1..N)` to `path`, LF-separated. |
| `exists` | `$$exists^STDFS(path)` | `1` iff path exists; else `0`. |
| `remove` | `do remove^STDFS(path)` | Deletes `path`; idempotent (no-op if absent). |
| `size` | `$$size^STDFS(path)` | Size in bytes; `-1` if missing. |
| `basename` | `$$basename^STDFS(path)` | Last path component. |
| `dirname` | `$$dirname^STDFS(path)` | Parent path. |
| `join` | `$$join^STDFS(left, right)` | POSIX path join (absolute right wins). |

### Byte-faithful I/O (`$ZF` → libc `read(2)` / `write(2)`)

| Extrinsic | Signature | Returns |
|---|---|---|
| `readBytes` | `$$readBytes^STDFS(path)` | File content as a byte string — no LF stripping, no CRLF normalisation. |
| `writeBytes` | `do writeBytes^STDFS(path, data)` | Writes `data` verbatim — **no trailing LF added**. |
| `appendBytes` | `do appendBytes^STDFS(path, data)` | Atomic append via `O_APPEND`; creates the file if missing. |
| `available` | `$$available^STDFS()` | `1` iff `stdfs.so` is loaded and reachable; else `0`. |

## Examples

```m
; round-trip a string
DO writeFile^STDFS("/tmp/note.txt","hello, world")
SET body=$$readFile^STDFS("/tmp/note.txt")  ; "hello, world"

; build then read an array
SET lines(1)="alpha",lines(2)="beta",lines(3)="gamma"
DO writeLines^STDFS("/tmp/list.txt",.lines)
KILL lines  DO readLines^STDFS("/tmp/list.txt",.lines)

; existence guard
IF '$$exists^STDFS(path) DO writeFile^STDFS(path,"<default>")

; path manipulation
WRITE $$basename^STDFS("/etc/hosts"),!     ; "hosts"
WRITE $$dirname^STDFS("/etc/hosts"),!      ; "/etc"
WRITE $$join^STDFS("/var","log"),!         ; "/var/log"
WRITE $$join^STDFS("/var","/abs"),!        ; "/abs"  (absolute right wins)
```

## Trailing-LF semantics

`writeFile` always ends the on-disk file with `LF`, regardless of
whether `data` does. This matches the POSIX text-file convention
(`echo "x" > file` produces `"x\n"`, two bytes) and the YDB SEQ
device's stream-mode close finalisation. Practical consequences:

- `$$readFile^STDFS(path)` strips the **single** trailing LF when
  reconstructing the string, so a string `"hello"` round-trips
  back to `"hello"` — even though the on-disk file is six bytes.
- `$$size^STDFS(path)` reports the **on-disk byte count**, which
  is `$LENGTH(data) + 1` if `data` did not already end in LF, and
  `$LENGTH(data)` otherwise. Use this for "what does `ls -l`
  show", not for "how many bytes did I pass to writeFile".
- For binary payloads (no implicit LF, exact byte round-trip),
  use `$$readBytes^STDFS` / `do writeBytes^STDFS` — these go
  through the libc `read(2)` / `write(2)` callout instead of the
  YDB SEQ device.

## Byte-faithful I/O (T13 + T14)

`$$readBytes^STDFS(path)` and `do writeBytes^STDFS(path, data)`
preserve every byte exactly. Unlike `readFile` / `writeFile`,
they do not strip CR, do not collapse line endings, and do not
add a trailing LF. The on-disk byte count after `writeBytes` is
exactly `$LENGTH(data)`. This makes them the right tool for:

- gzipped / zstd-compressed payloads
- signed binary blobs (where any added byte invalidates the signature)
- captured HTTP response bodies that need bit-exact replay
- snapshot fixtures that include CR / NUL / high-bit bytes

Backend: `$ZF → libc open(2) / read(2) / write(2) / close(2)`,
sourced from `src/callouts/stdfs.c` and described by
`tools/std_fs.xc`. Built by `tools/build-callouts.sh`. When the
`.so` is missing, the byte-faithful entries set
`$ECODE=,U-STDFS-NOT-WIRED,` — the text-I/O entries continue to
work because they use the YDB SEQ device.

The 16 MiB per-call output cap is declared in the `.xc`
descriptor. If a `readBytes` call would exceed it, `$ECODE` is
set to `,U-STDFS-READ-TRUNCATED,` (no silent truncation —
truncation would corrupt downstream consumers expecting
byte-faithful round-trip semantics). For larger files a
streaming `open` / `write` / `close` triplet is the natural
follow-on; not yet scheduled.

## Append semantics

`$$append^STDFS(path, data)` is a **text-mode** operation: it reads the
existing file via `readFile` (LF-stripped reconstruction), concatenates
`data`, and writes the result back via `writeFile` (which always emits
exactly one trailing LF on disk). Cost is `O(file size)` per call.

This implementation is deliberate, not a workaround for the missing
callout. The native `O_APPEND` path would leave an interior LF in the
file whenever the previous content already ended with one — readFile
would then round-trip to `"head\n-tail"` instead of the documented
`"head-tail"`. Keeping append() at read-then-rewrite preserves the
contract that `readFile` after `append` equals `readFile(old) + data`.

For byte-faithful append at EOF (no LF normalisation, single `write(2)`
syscall, atomic under concurrent writers), use `do appendBytes^STDFS`
directly. That entry lands data verbatim and is the right tool for
binary log streams, append-only data files, and structured payloads
where each chunk already carries its own framing.

## `exists` and the YDB `$ZSEARCH` cache

`$ZSEARCH` is the obvious primitive for existence checks, but it
caches the directory enumeration per-process — a path created and
then deleted within one M process can still appear "present" via
`$ZSEARCH` until the next OPEN. STDFS bypasses this by **probing
via OPEN with `timeout=0`**: an `$ETRAP` catches the YDB hard-error
(`Z150379354`) that fires on missing files and unwinds via
`ZGOTO $zlevel:existsRet^STDFS` — the same arg-less-`quit`-avoidance
pattern that `raises^STDASSERT` uses (TOOLCHAIN P1 fix). The result
is an existence check that reflects the actual filesystem, not the
process-local search cache.

## Path manipulation semantics

`basename` and `dirname` follow GNU coreutils conventions:

| Input | `basename` | `dirname` |
|---|---|---|
| `/etc/hosts` | `hosts` | `/etc` |
| `/foo/bar/` | `bar` | `/foo` |
| `plain` | `plain` | `.` |
| `/` | `/` | `/` |
| `""` | `""` | `.` |

`join`:

- Empty operand drops out: `join("","b") = "b"`, `join("/a","") = "/a"`.
- Absolute right wins: `join("/a","/b") = "/b"` (matches Python `os.path.join`).
- Trailing slash on the left is collapsed: `join("/a/","b") = "/a/b"`.

## Edge cases

- **Empty file round-trip.** `writeFile(path,"")` creates a zero-byte
  file; `readFile(path)` returns `""`. Confirmed by
  `tests/STDFSTST.m:tWriteThenReadEmpty`.
- **CRLF normalisation on read.** `readFile` and `readLines` strip
  a trailing CR from each line, so a file produced on Windows
  reads back identically to the same file produced on Linux.
- **`remove()` idempotency.** Removing a missing path is a no-op
  (no `$ECODE` set). This matches `unlink`-with-`ENOENT-suppression`
  semantics — useful inside teardown blocks.
- **`size()` of missing path returns `-1`,** not `0`. A
  zero-byte-existing file returns `0`.

## Error codes

| `$ECODE` | Raised by | Meaning |
|---|---|---|
| `,U-STDFS-OPEN-FAIL,` | `readFile`, `readLines`, `writeFile`, `writeLines`, `append`, `readBytes`, `writeBytes`, `appendBytes` | Path missing or unopenable. Text-I/O surfaces YDB's OPEN failure; byte-I/O surfaces libc `open(2)` failure (full errno text in `stdfs_lasterror`). |
| `,U-STDFS-REMOVE-FAIL,` | `remove` | OPEN-with-DELETE failed for a reason other than "file already absent" (typically a permission or busy-fd issue). |
| `,U-STDFS-NOT-WIRED,` | `readBytes`, `writeBytes`, `appendBytes` | `stdfs.so` not loaded (`$ZTRNLNM("ydb_xc_std_fs")` empty, descriptor missing, or `dlopen` failed). The text-I/O entries are unaffected. |
| `,U-STDFS-READ-TRUNCATED,` | `readBytes` | File exceeds the 16 MiB per-call buffer cap declared in `tools/std_fs.xc`. No silent truncation. |

## Deployment

The byte-faithful API depends on `stdfs.so`. To deploy:

```bash
tools/build-callouts.sh                     # produces so/<plat>/stdfs.so
export STDLIB_LIB=$(pwd)/so/linux-x86_64    # or whichever platform
export ydb_xc_std_fs=$(pwd)/tools/std_fs.xc
```

Verify with `$$available^STDFS()` from any M shell — `1` means
the descriptor is exported and `open(2)` works on `/dev/null`.

When the `.so` is absent the rest of STDFS still works, and
`append()` automatically falls back to read-then-rewrite — see
the "Append semantics" section.

## Engine portability

YDB on Linux is the supported configuration. The path-manipulation
labels (`basename` / `dirname` / `join`) are pure-M and run
unchanged on IRIS today. The text-I/O labels rely on YDB's
`OPEN`/`USE`/`READ #n`/`CLOSE` semantics and the `$ZEOF` /
`$ZLEVEL` extensions; the byte-I/O labels rely on the `$ZF`
host-call ABI which YDB exposes via `ydb_xc_*` and IRIS exposes
via `$ZF(-2,...)` / `^%ZSTART` glue. The IRIS arm of the byte-I/O
path lands once a real consumer drives it; the public M API will
not change.

## See also

- [`STDCSV`](stdcsv.md) — same OPEN/USE/CLOSE pattern, pre-dates
  STDFS by ~6 weeks; once STDFS stabilises, STDCSV's `parseFile`
  / `writeFile` will rebase onto STDFS for the device dance.
- [`STDCSPRNG`](stdcsprng.md) — same byte-faithful OPEN/USE/READ
  pattern for `/dev/urandom`.
- [`STDASSERT`](stdassert.md) — every test in `STDFSTST` is one
  STDASSERT call; the `$ETRAP+ZGOTO` pattern in `exists()` is the
  same one `raises^STDASSERT` uses.
