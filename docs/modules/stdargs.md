# `STDARGS` — argparse

A small argument parser for M command-line scripts. Long flags
(`--verbose`), short flags (`-v`), grouped count flags (`-vvv`),
positionals, sub-commands, and the `--` end-of-flags terminator. Args
arrive as a single string — `$ZCMDLINE` on YDB, or any explicit
string elsewhere.

## Public API

| Label | Signature | Returns |
|---|---|---|
| `new` | `$$new^STDARGS(prog,desc)` | A positive integer parser handle. |
| `addflag` | `do addflag^STDARGS(p,long,short,action,dest)` | — (mutates `p`). |
| `addpos` | `do addpos^STDARGS(p,name,dest)` | — (mutates `p`). |
| `addsub` | `do addsub^STDARGS(p,name,subParserHandle)` | — (mutates `p`). |
| `parse` | `do parse^STDARGS(p,argline,.ns)` | — (populates `ns(dest)` by reference). |
| `help` | `$$help^STDARGS(p)` | Formatted help text. |
| `free` | `do free^STDARGS(p)` | — (drops parser state). |

The handle keys into `^STDLIB($job,"stdargs",p,...)`. State is
per-process and per-handle. `free()` is idempotent; the handle must
not be reused after.

## Actions

| Action | Behaviour | Default in `ns` |
|---|---|---|
| `store_true` | `ns(dest)=1` if flag seen | `ns(dest)=0` |
| `store` | `ns(dest)=<next token>` | (none) |
| `count` | `ns(dest)+=1` per occurrence; `-vvv` expands | `ns(dest)=0` |
| `append` | `ns(dest,k)=<next token>` (k is auto-incrementing 1..N) | (none) |

`store_true` and `count` flags are pre-populated with `0` so absent
flags are observable. `store` and `append` flags do not appear in
`ns` if the flag was never given.

`addflag` with an action outside this set sets `$ECODE` to
`,U-STDARGS-UNKNOWN-ACTION,`.

## Examples

```m
; basic flag + positional
new p,ns
set p=$$new^STDARGS("rsync","copy a tree")
do addflag^STDARGS(p,"--verbose","-v","count","verbose")
do addflag^STDARGS(p,"--exclude","-e","append","exclude")
do addpos^STDARGS(p,"src","src")
do addpos^STDARGS(p,"dst","dst")
do parse^STDARGS(p,"-vv --exclude .git --exclude node_modules /a /b",.ns)
write ns("verbose"),!         ; 2
write ns("exclude",1),!       ; .git
write ns("exclude",2),!       ; node_modules
write ns("src"),!             ; /a
write ns("dst"),!             ; /b
do free^STDARGS(p)

; sub-commands
new p,sub,ns
set p=$$new^STDARGS("m","tooling")
set sub=$$new^STDARGS("m test","run tests")
do addflag^STDARGS(sub,"--filter","-f","store","filter")
do addsub^STDARGS(p,"test",sub)
do parse^STDARGS(p,"test --filter STDB64",.ns)
write ns("__sub__"),!         ; test
write ns("filter"),!          ; STDB64
do free^STDARGS(p)
do free^STDARGS(sub)

; help text
write $$help^STDARGS(p)
```

## The `--` terminator

A bare `--` token ends flag parsing. Subsequent tokens are positional
even if they start with `-`:

```m
do parse^STDARGS(p,"-- --verbose",.ns)
write ns("path"),!            ; --verbose  (positional, not a flag)
```

## Sub-commands

When any sub-command is registered with `addsub`, the first non-flag
token of `argline` MUST name one — anything else sets `$ECODE` to
`,U-STDARGS-UNKNOWN-SUBCOMMAND,`. The chosen sub-command name is
recorded as `ns("__sub__")`. The remainder of the argline is
re-parsed against the sub-parser's flags / positionals into the same
`ns`, so a top-level `parse()` populates everything in one call.

## Grouped short flags

Short-flag tokens of length > 2 (`-vvv`) are expanded char by char.
Every char must be the short form of a `count`-action flag; otherwise
`,U-STDARGS-UNKNOWN-FLAG,` fires. This rules out the ambiguity
between grouped flags and a `store`-style short with an attached
value.

## Error codes

| `$ECODE` | When |
|---|---|
| `,U-STDARGS-UNKNOWN-ACTION,` | `addflag` with a non-recognised action |
| `,U-STDARGS-UNKNOWN-FLAG,` | `parse` sees a flag that was never registered |
| `,U-STDARGS-UNKNOWN-SUBCOMMAND,` | `parse` sees a first token that names no registered sub |
| `,U-STDARGS-MISSING-VALUE,` | `store`/`append` flag has no following token |
| `,U-STDARGS-MISSING-POSITIONAL,` | A registered positional was never filled |

## Tokenisation

`parse()` splits `argline` on runs of ASCII space and tab — quoting
is the shell's job (and `$ZCMDLINE` arrives post-shell). If you need
a value with embedded spaces, pass an already-tokenised list of
tokens joined with `_$char(31)_` and tokenise yourself; first-class
quoted-arg support is out of scope for v0.0.7.

## Edge cases

- **Empty `argline`.** `parse()` runs `initDefaults` (so `store_true`
  and `count` flags appear in `ns` as 0) and `checkPositionals` (so
  any registered positional fires `MISSING-POSITIONAL`).
- **Extra positionals.** Tokens past the last registered positional
  are silently ignored at v0.0.7 — a future revision may add `nargs+`
  / `nargs*` semantics.
- **Mutually-exclusive groups.** Not modelled at v0.0.7. Callers
  enforce by inspecting `ns` after parse.
- **`-` as a value.** A bare `-` is treated as a positional (length
  ≤ 1 with leading `-` falls through the flag check).

## See also

- [`STDFMT`](stdfmt.md) for printf-style help-text formatting once a
  caller wants more than the default usage block.
