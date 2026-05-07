# `STDFS` — File-system primitives

Read / write / append / exists / remove / size on regular text
files, plus three pure-string path manipulators (`basename`,
`dirname`, `join`). Centralises the YDB-style `OPEN`/`USE`/`READ`/
`WRITE`/`CLOSE` device dance so consumer modules don't have to
re-derive the deviceparam combinations or work around the
[`M-MOD-024`](../../TOOLCHAIN-FINDINGS.md) lint false-positive.

## Public API

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
- A binary-safe path (no implicit LF; raw byte round-trip) is
  reserved for a follow-on `readBytes` / `writeBytes` pair that
  arrives alongside the `$ZF→read(2)/write(2)` callout backend.

## Append semantics

`$$append^STDFS(path, data)` is implemented as **read-then-rewrite**:
the function reads the existing file, concatenates `data`, and
writes the result back via `writeFile`. This avoids a YDB SEQ
device quirk where the first `WRITE` after `OPEN dev:(append)`
sometimes lands at byte 0 instead of EOF. The native append path
will return when the `$ZF→write(2)` callout backend is wired up;
the public API will not change.

For very large files, the read-then-rewrite cost is `O(file size)`
per call. If you need many appends to one growing file, a future
`$$open^STDFS(path,mode)` / `$$write^STDFS(handle,data)` /
`$$close^STDFS(handle)` triplet (handle-style streaming I/O) is
the natural extension. Open issue.

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
| `,U-STDFS-OPEN-FAIL,` | `readFile`, `readLines`, `writeFile`, `writeLines`, `append` | Path missing or unopenable (read paths pre-check via `exists`; write paths surface YDB's OPEN failure verbatim through `else`). |
| `,U-STDFS-REMOVE-FAIL,` | `remove` | OPEN-with-DELETE failed for a reason other than "file already absent" (typically a permission or busy-fd issue). |

## Engine portability

YDB on Linux is the supported configuration. The path-manipulation
labels (`basename` / `dirname` / `join`) are pure-M and run
unchanged on IRIS today. The I/O labels rely on YDB's `OPEN`/`USE`/
`READ #n`/`CLOSE` semantics and the `$ZEOF` / `$ZLEVEL` extensions —
the IRIS arm lands when STDFS gets its `$ZF→stat`/`read`/`write`
callout backend (queued; the `tools/build-callouts.sh` harness
already ships).

## See also

- [`STDCSV`](stdcsv.md) — same OPEN/USE/CLOSE pattern, pre-dates
  STDFS by ~6 weeks; once STDFS stabilises, STDCSV's `parseFile`
  / `writeFile` will rebase onto STDFS for the device dance.
- [`STDCSPRNG`](stdcsprng.md) — same byte-faithful OPEN/USE/READ
  pattern for `/dev/urandom`.
- [`STDASSERT`](stdassert.md) — every test in `STDFSTST` is one
  STDASSERT call; the `$ETRAP+ZGOTO` pattern in `exists()` is the
  same one `raises^STDASSERT` uses.
