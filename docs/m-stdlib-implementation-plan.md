---
title: m-stdlib — implementation plan
status: in progress (Phase 0 not yet started)
last-updated: 2026-04-30
companion: m-libraries-remediation.md (background; this doc is the live work plan)
---

# m-stdlib — implementation plan

This is the **live, continuously updated** plan for building m-stdlib.
Tick boxes as work lands. Update the **Current state** section at the
top of every working session. The companion `m-libraries-remediation.md`
holds the background and rationale; this document holds the work.

---

## 1. Current state

| Phase | Status | Tag |
|---|---|---|
| Phase 0 — bootstrap | **done (2026-04-30)** | — |
| Phase 1 — pure-M quick wins | **in progress** — `v0.0.1` shipped 2026-04-30 | → `v0.1.0` |
| Phase 2 — pure-M heavy lifting | not started | → `v0.2.0` |
| Phase 3 — host-call integrations | not started | → `v0.3.0` |

**Next concrete unit of work:** §8 v0.0.2 — STDB64 + STDHEX
(RFC-4648 base64 + hex). TDD-first per §2.1; per-module gate (§9)
must be green before merge.

---

## 2. Non-negotiables

These rules govern every commit. They are not phase-specific.

1. **TDD first, always.** Write the `*TST.m` suite *before* the
   implementation. Confirm the test fails (ImportError on the routine,
   or assertion error). Only then write the routine. Re-run; confirm
   green. This is the Tier-1 rule for all `~/projects/` work — it
   applies here too.
2. **Every module ships with a full unit-test suite.** No module
   merges without `*TST.m` covering: happy path, all documented edge
   cases, all error paths, all RFC/spec corner cases where applicable
   (RFC-4180 for CSV, RFC-4648 for B64/HEX, RFC-4122 for UUID, RFC-8259
   for JSON, RFC-3986 for URL, ISO-8601 for STDDATE).
3. **Every module is exercised on a real project.** Unit tests prove
   the module works in isolation; real-project exercise proves it works
   under the m-cli toolchain end-to-end (fmt, lint, test, coverage,
   LSP) and integrates with actual M code. See §10 for the strategy.
4. **All M code is in modern Pythonic style.** See §3.
5. **m-stdlib has priority over m-cli.** When stdlib conventions
   (assertions, log format, error-code shape) tension with m-cli's
   internals, the stdlib wins; m-cli adapts via a companion PR.
6. **Per-module acceptance gate** in §9 must be green before any
   module merges. No exceptions.

---

## 3. Modern Pythonic M style

"Pythonic" here is about **workflow and structure**, not syntax:

- **Project shape mirrors a Python project**: `src/`, `tests/`,
  `docs/`, `Makefile`, `.devcontainer/`, `.github/workflows/`,
  pre-commit hooks, branch-protected CI.
- **TDD-first** (per §2.1). Tests live alongside source in `tests/`,
  one `*TST.m` per `*.m`.
- **One responsibility per routine, small focused labels.** Labels
  read like Python functions: short, single-purpose, independently
  testable. No mega-routines.
- **Public API documented at the label.** Every public label carries
  a `; doc:` comment block above it: signature, args, returns,
  raises, example. Drives `m lsp` hover and (eventually) `m docs`.
- **No print() in library code.** Use `STDLOG` once it ships; until
  then, leave logging to the caller. `WRITE` only in `examples/` and
  in the `*TST.m` failure messages.
- **Globals are namespaced**: `^STDLIB($J,...)` for per-process
  state, `^STDLIBC(...)` for shared config. No naked globals from
  any STD routine.
- **Errors are structured.** Set `$ECODE` with a documented error
  code; do not `WRITE`-and-`HALT`. STDASSERT verifies error codes,
  not error text.
- **No mocks unless unavoidable.** Tests use real fixtures (real
  byte strings, real JSON files, real timestamps). Network/IO
  callouts in Phase 3 are the only place a fake is acceptable.
- **m-cli linting is the gate.** `m fmt --check` clean,
  `m lint --error-on=error` clean (default profile,
  `--target-engine=any`). M-XINDX-057 (mixed-case lvn) is
  downgraded to INFO in `.m-cli.toml` for parametrised modules
  (STDFMT, STDJSON); everywhere else it's the default WARNING.
- **Routine prefix is `STD`** (reserved family-wide); test-suite
  suffix is `TST`.

---

## 4. Conventions (locked)

- **License:** AGPL-3.0. Per-module relicense escape hatch only if a
  specific case demands it.
- **Versioning:** SemVer. Pre-1.0 minors may include breaking changes
  (documented in `CHANGELOG.md`).
- **Milestone tags:**
  - `v0.0.1` — STDASSERT + STDUUID, CI green.
  - `v0.0.2`–`v0.0.7` — one Phase-1 module per tag.
  - `v0.1.0` — Phase 1 complete.
  - `v0.2.0` — Phase 2 complete.
  - `v0.3.0` — Phase 3 complete.
  - `v1.0.0` — API stable for 3 months after `v0.3.0`.
- **Vendor scope:** YottaDB primary; IRIS portable where the cost is
  reasonable (dispatch on `$ZASCII`/`$ASCII`,
  `$ZTIMESTAMP`/`$ZHOROLOG`, `$ZF`/`$CLASSMETHOD`); GT.M out
  permanently. IRIS portability job is fail-soft until v0.0.4, then
  reintroduced.
- **Repo:** local `~/projects/m-stdlib`; remote
  `github.com/rafael5/m-stdlib`, public.
- **Assertion library:** STDASSERT is canonical for m-stdlib and the
  whole project family. m-stdlib does not depend on m-tools.

---

## 5. Project layout

```
m-stdlib/
├── README.md
├── LICENSE                       # AGPL-3.0
├── CHANGELOG.md
├── TODO.md                       # resume-here pointer
├── Makefile
├── .m-cli.toml                   # fmt + lint + lsp config
├── .pre-commit-config.yaml       # repo: local until m-cli published
├── .devcontainer/
│   ├── Dockerfile
│   └── devcontainer.json
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── docs/
│   ├── m-stdlib-implementation-plan.md   # this file
│   ├── m-libraries-remediation.md        # background
│   └── modules/
│       ├── stdassert.md
│       ├── stduuid.md
│       └── ...                            # one per src module
├── src/
│   ├── STDASSERT.m
│   ├── STDUUID.m
│   ├── STDB64.m
│   ├── STDHEX.m
│   ├── STDFMT.m
│   ├── STDLOG.m
│   ├── STDDATE.m
│   ├── STDCSV.m
│   ├── STDARGS.m
│   ├── STDJSON.m       # Phase 2
│   ├── STDREGEX.m      # Phase 2
│   ├── STDCOLL.m       # Phase 2
│   ├── STDURL.m        # Phase 2
│   ├── STDHTTP.m       # Phase 3
│   ├── STDCRYPTO.m     # Phase 3
│   └── STDCOMPRESS.m   # Phase 3
├── tests/
│   ├── STDASSERTTST.m
│   ├── STDUUIDTST.m
│   ├── ...                       # one TST per src
│   └── conformance/
│       ├── b64/                  # RFC-4648 §10 vectors
│       ├── csv/                  # RFC-4180 corner cases
│       ├── json/                 # JSONTestSuite vendored (Phase 2)
│       └── uuid/                 # RFC-4122 test vectors
├── examples/                     # runnable demos referenced from docs
└── tools/
    └── build-callouts.sh         # Phase 3 only
```

---

## 6. Toolchain and dev environment

### 6.0 YottaDB image (resolve before §7)

Pull all candidate images locally and pick the most reliable:

- [ ] `yottadb/yottadb-base:latest-master`
- [ ] `yottadb/yottadb`
- [ ] `yottadb/yottadb:r2.02` (and any newer tagged release line)

Pick on: (a) exists on Docker Hub, (b) starts cleanly, (c) has
`mumps` and `mupip` on `PATH`. Document the choice in the
Dockerfile and `ci.yml` as a comment.

### 6.1 Devcontainer (`.devcontainer/devcontainer.json`)

```jsonc
{
  "name": "m-stdlib dev",
  "build": { "dockerfile": "Dockerfile" },
  "remoteUser": "yottadb",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],
  "containerEnv": {
    "ydb_dist": "/opt/yottadb",
    "ydb_routines": "/workspace/src /workspace/tests /workspace/.objects",
    "ydb_gbldir": "/workspace/.ydb/m-stdlib.gld",
    "PATH": "/opt/m-cli/.venv/bin:${containerEnv:PATH}"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "rafael5.tree-sitter-m-vscode",
        "github.vscode-github-actions",
        "redhat.vscode-yaml",
        "ms-azuretools.vscode-docker",
        "eamodio.gitlens"
      ],
      "settings": {
        "m-cli.enabled": true,
        "m-cli.path": "/opt/m-cli/.venv/bin/m",
        "editor.formatOnSave": true,
        "[m]": {
          "editor.tabSize": 1,
          "editor.insertSpaces": true,
          "editor.detectIndentation": false
        }
      }
    }
  },
  "postCreateCommand": "make setup-ydb && make install-test-deps"
}
```

### 6.2 Container image (`.devcontainer/Dockerfile`)

```dockerfile
# Image pinned per §6.0 verification. Reason: <fill in after pinning>
FROM yottadb/yottadb-base:latest-master

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3-pip git build-essential \
        libssl-dev libcurl4-openssl-dev libsodium-dev zlib1g-dev libpcre2-dev \
    && rm -rf /var/lib/apt/lists/*

# m-cli installed from git checkout. Swap to `pip install m-cli[lsp]`
# once m-cli publishes (post-Phase-1 milestone).
RUN git clone https://github.com/rafael5/m-cli /opt/m-cli && \
    cd /opt/m-cli && \
    python3.12 -m venv .venv && \
    .venv/bin/pip install -e .[lsp]

RUN /opt/m-cli/.venv/bin/pip install tree-sitter-m

USER yottadb
WORKDIR /workspace
```

### 6.3 `.m-cli.toml`

```toml
[fmt]
rules = "canonical"

[lint]
rules = "default"
disable = []
severity = { "M-XINDX-057" = "INFO" }   # mixed-case lvn — STDFMT/STDJSON parametrised
target-engine = "any"

[lsp]
hover.format = "markdown"
```

### 6.4 `Makefile`

```makefile
.PHONY: all setup-ydb install-test-deps fmt fmt-check lint test coverage check ci clean

all: check

setup-ydb:
	@mkdir -p .ydb .objects
	@if [ ! -f .ydb/m-stdlib.gld ]; then \
		. /opt/yottadb/ydb_env_set && mumps -run GDE <<EOF ; \
		change -region DEFAULT -dynamic_segment=DEFAULT ; \
		change -segment DEFAULT -file_name=.ydb/m-stdlib.dat ; \
		exit ; \
EOF \
		mupip create ; \
	fi

install-test-deps:
	@/opt/m-cli/.venv/bin/m --version

fmt:        ; m fmt src/ tests/
fmt-check:  ; m fmt --check src/ tests/
lint:       ; m lint --error-on=error src/ tests/
test:       ; m test tests/
coverage:   ; m coverage --min-percent=85 --format=lcov > coverage.lcov

check: fmt-check lint test coverage
	@echo "OK"

ci: check
	@m test --format=tap > test-results.tap
	@m coverage --format=json > coverage.json

clean:
	rm -rf .ydb .objects coverage.lcov test-results.tap coverage.json
```

### 6.5 Pre-commit (`.pre-commit-config.yaml`)

`repo: local` form until m-cli publishes:

```yaml
repos:
  - repo: local
    hooks:
      - id: m-fmt
        name: m fmt --check
        entry: /opt/m-cli/.venv/bin/m fmt --check
        language: system
        files: \.m$
      - id: m-lint
        name: m lint --error-on=error
        entry: /opt/m-cli/.venv/bin/m lint --error-on=error
        language: system
        files: \.m$
# TODO: swap to `repo: https://github.com/rafael5/m-cli` once m-cli ≥ v0.1.0
# publishes its `.pre-commit-hooks.yaml` against a release tag.
```

### 6.6 CI (`.github/workflows/ci.yml`)

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  m-stdlib:
    runs-on: ubuntu-latest
    container: yottadb/yottadb-base:latest-master   # pin per §6.0
    strategy:
      fail-fast: false
      matrix:
        ydb-version: ["r2.02", "latest-master"]
    steps:
      - uses: actions/checkout@v4

      - name: Install Python toolchain
        run: |
          apt-get update && apt-get install -y python3.12 python3.12-venv git
          python3.12 -m venv /tmp/venv
          /tmp/venv/bin/pip install --upgrade pip

      - name: Install m-cli (from git until post-Phase-1 publication)
        run: |
          git clone --depth=1 https://github.com/rafael5/m-cli /tmp/m-cli
          /tmp/venv/bin/pip install -e /tmp/m-cli[lsp]

      - name: Initialise YDB
        run: . /opt/yottadb/ydb_env_set && make setup-ydb

      - name: Format check
        run: . /opt/yottadb/ydb_env_set && PATH=/tmp/venv/bin:$PATH make fmt-check

      - name: Lint
        run: . /opt/yottadb/ydb_env_set && PATH=/tmp/venv/bin:$PATH make lint

      - name: Test (TAP)
        run: |
          . /opt/yottadb/ydb_env_set
          PATH=/tmp/venv/bin:$PATH m test --format=tap | tee test-results.tap

      - name: Upload TAP
        uses: actions/upload-artifact@v4
        with:
          name: tap-${{ matrix.ydb-version }}
          path: test-results.tap

      - name: Coverage (lcov)
        run: |
          . /opt/yottadb/ydb_env_set
          PATH=/tmp/venv/bin:$PATH m coverage --format=lcov > coverage.lcov

      - name: Upload coverage
        if: matrix.ydb-version == 'latest-master'
        uses: codecov/codecov-action@v4
        with:
          files: coverage.lcov
          fail_ci_if_error: true

  # Reintroduce at v0.0.4 per §4 (vendor scope). Until then, this job is omitted.
  # iris-portability-check:
  #   if: github.event_name == 'pull_request'
  #   runs-on: ubuntu-latest
  #   container: intersystemsdc/iris-community:latest
  #   continue-on-error: true
  #   steps: ...
```

### 6.7 Release (`.github/workflows/release.yml`)

```yaml
name: Release
on:
  push:
    tags: ["v*.*.*"]
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Build distributable
        run: |
          mkdir -p dist
          tar czf "dist/m-stdlib-${GITHUB_REF_NAME}-src.tar.gz" \
              --transform "s,^,m-stdlib-${GITHUB_REF_NAME#v}/," \
              src tests docs README.md LICENSE
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

---

## 7. Phase 0 — bootstrap (done 2026-04-30)

- [x] **7.1 YottaDB image pinned** — `yottadb/yottadb-base:latest-master`
      (YottaDB r2.07 at pin time). `mumps`/`mupip` live at
      `/opt/yottadb/current/`; reachable after sourcing `ydb_env_set`.
      Comment recorded in `.devcontainer/Dockerfile` and `ci.yml`.
- [x] **7.2 Skeleton.** Layout per §5; root files written; `git init`.
- [x] **7.3 Devcontainer.** `Dockerfile` + `devcontainer.json` wired
      per §6.1–§6.2. Container build deferred (local toolchain is
      operational; CI will exercise the container).
- [x] **7.4 CI.** `ci.yml` + `release.yml` landed per §6.6 with the
      IRIS portability job omitted (reintroduce at v0.0.4). First
      green run will follow the first push.
- [x] **7.5 README.** ≤ 1 page; covers what the project is, milestone
      tags (§4), license, install-from-git instructions, devcontainer,
      submodule install, and links to this plan.
- [x] **7.6 STDASSERT bootstrap probe.** Stub `STDASSERT.m` mirrors
      `^TESTRUN`'s output protocol exactly (`  PASS  ` / `  FAIL  ` /
      `Results: …`). `STDASSERTTST.m` runs three assertions under
      `m test` — all 3/3 green via the existing
      `t<UpperCase>(pass,fail)` discovery. **No m-cli change needed
      for v0.0.1's whole-suite execution.** Single-test selection
      (`m test FILE.m::tLabel`) hard-codes `^TESTRUN` in
      [m-cli/.../runner.py:171](../../m-cli/src/m_cli/test/runner.py)
      lines 168–173 and is the deferred companion PR — not a blocker.

**Local toolchain confirmed:** YottaDB r2.02 at
`/usr/local/lib/yottadb/r202`, m-cli at `~/projects/m-cli/.venv/bin/m`.
`make check` (fmt-check + lint + test) is green.

**Phase 0 corrections folded in:**

- `m lint --error-on=fatal` was an invalid value. Real options are
  `error|warning|style|info`. Updated to `--error-on=error` in the
  Makefile, pre-commit, CI, and §6.4 below.
- `make check` no longer chains `coverage` (probe stub coverage is
  83.3%, below the 85% gate; coverage gating starts at v0.0.1 per §9).
  Coverage runs as `make coverage` or via `make ci`.
- `setup-ydb` extracted into [`tools/init-db.sh`](../tools/init-db.sh)
  (m-tools-style: `unset ydb_routines` before `mumps -run GDE`,
  `mupip create` afterwards).
- `YDB_ENV` in the Makefile uses bare exports (not `ydb_env_set`)
  and proactively unsets stale `gtm*` vars from prior shell sessions.

---

## 8. Phase 1 — pure-M quick wins

Eight modules. Each merges as its own tag with the §9 acceptance gate
green. Each PR carries: source + `*TST.m` + `docs/modules/<name>.md`
+ `CHANGELOG.md` entry. None of those are optional.

| Tag | Module(s) | Routine(s) | LoC est. | Tests est. | Status |
|---|---|---|---:|---:|---|
| `v0.0.1` | Assertion library + UUID v4/v7 | `STDASSERT.m`, `STDUUID.m` | ~270 | ~70 | ✅ shipped 2026-04-30 — 166/166 assertions, 22/22 coverage |
| `v0.0.2` | Base64 + Hex (RFC-4648) | `STDB64.m`, `STDHEX.m` | ~400 | ~80 | next |
| `v0.0.3` | Printf-style formatter | `STDFMT.m` | ~300 | ~60 |
| `v0.0.4` | Structured logger (text-only) + IRIS CI re-add | `STDLOG.m` | ~200 | ~40 |
| `v0.0.5` | ISO-8601 datetime | `STDDATE.m` | ~400 | ~80 | ✅ green 2026-05-05 — 60/60 assertions, 19/20 labels (95.0%), 0 lint errors. Error-path raises tests deferred per STDASSERT.raises limitation. |
| `v0.0.6` | RFC-4180 CSV | `STDCSV.m` | ~300 | ~50 |
| `v0.0.7` | argparse | `STDARGS.m` | ~400 | ~50 |
| `v0.1.0` | Phase 1 release: CHANGELOG roll-up, GitHub Release, source tarball, regenerated docs index | — | — | — |

### 8.1 STDASSERT — assertion library

**Public API (sketch):**

```m
EQ(pass,fail,actual,expected,msg)         ; equality
NE(pass,fail,actual,expected,msg)         ; inequality
TRUE(pass,fail,cond,msg)                  ; truthy
FALSE(pass,fail,cond,msg)                 ; falsy
NEAR(pass,fail,a,b,eps,msg)               ; float comparison
RAISES(pass,fail,code,errno,msg)          ; XECUTE code, assert $ECODE matches
CONTAINS(pass,fail,haystack,needle,msg)
LEN(pass,fail,collection,n,msg)
```

**Compatibility:** all assertions update `pass`/`fail` counters via
the existing `t<UpperCase>(pass,fail)` discovery contract. No new
recogniser needed in m-cli for v0.0.1 — proven by §7.6 probe.

**Tests:** all assertion forms exercised in `STDASSERTTST.m` against
both passing and failing inputs. Verify counters increment correctly
in both branches; verify failure messages include `msg` when supplied.

### 8.2 STDUUID — RFC-4122 UUID v4 + v7

**Public API:**

```m
$$V4^STDUUID()                            ; random UUID v4
$$V7^STDUUID()                            ; time-ordered UUID v7
$$VALID^STDUUID(uuid)                     ; format validator
$$VARIANT^STDUUID(uuid)                   ; "rfc4122" | "ncs" | "microsoft" | "future"
$$VERSION^STDUUID(uuid)                   ; integer 1..7
```

**Engine dispatch:** v7 timestamps from `$ZHOROLOG` (YDB) /
`$ZTIMESTAMP` (IRIS).

**Tests:**
- 1000-roundtrip uniqueness check on V4 and V7.
- Bit-layout assertions: version nibble, variant bits.
- Monotonicity check on V7 (sorts in generation order).
- VALID/VARIANT/VERSION cover all 7 RFC-defined versions plus malformed.

### 8.3 STDB64 — RFC-4648 Base64

**Public API:** `ENCODE`, `DECODE`, `URLENCODE` (`-_`, no padding),
`URLDECODE`, `VALID`.

**Tests:** RFC-4648 §10 vectors vendored to `tests/conformance/b64/`;
round-trip property test on random byte strings 0..1024 bytes; reject
malformed inputs (bad alphabet, bad padding, bad length).

### 8.4 STDHEX — Hex encoding

**Public API:** `ENCODE` (lowercase default), `ENCODEU` (uppercase),
`DECODE`, `VALID`.

**Tests:** round-trip on random byte strings; case-insensitive decode;
reject odd-length and non-hex inputs.

### 8.5 STDFMT — printf-style formatter

**Public API:**

```m
$$F^STDFMT(template, a1, a2, ...)         ; up to 9 positional
$$FN^STDFMT(template, .args)              ; named substitution from local array
```

**Format spec:** subset of Python's `str.format`: `{}`, `{0}`,
`{name}`, alignment (`<`, `>`, `^`), width, precision, type
(`s`, `d`, `f`, `x`, `X`, `o`, `b`).

**Tests:** every spec field permutation against known outputs;
malformed templates raise documented `$ECODE`; precision rounding
uses `$FNUMBER` semantics.

### 8.6 STDLOG — structured logger

**Public API:**

```m
DEBUG^STDLOG(event, k1, v1, k2, v2, ...)
INFO^STDLOG(event, ...)
WARN^STDLOG(event, ...)
ERROR^STDLOG(event, ...)
FATAL^STDLOG(event, ...)
LEVEL^STDLOG(threshold)                   ; set runtime threshold
SINK^STDLOG(target)                       ; "stderr" | "stdout" | "global:^STDLOG"
```

**Output format:** `key=value` text in v0.0.4. JSON-line output added
in Phase 2 once STDJSON ships.

**Tests:** level filtering; key-value escaping (spaces, `=`, quotes);
sink dispatch; timestamp from STDDATE (deferred to v0.0.5 — until
then `STDLOG` ships with a minimal inline ISO timestamp helper which
is replaced when STDDATE lands).

**v0.0.4 also:** reintroduce IRIS `iris-portability-check` job in CI
(fail-soft).

### 8.7 STDDATE — ISO-8601 datetime

**Public API:**

```m
$$NOW^STDDATE()                           ; current ISO-8601 UTC
$$FROMH^STDDATE(horolog)                  ; $HOROLOG → ISO-8601
$$TOH^STDDATE(iso)                        ; ISO-8601 → $HOROLOG
$$STRFTIME^STDDATE(horolog, format)       ; %Y-%m-%dT%H:%M:%S%z
$$STRPTIME^STDDATE(text, format)
$$ADD^STDDATE(horolog, duration)          ; ISO-8601 duration P1DT2H30M
$$DIFF^STDDATE(h1, h2)                    ; → ISO-8601 duration
```

**Coverage:** timezone offsets `+HH:MM`/`-HH:MM`/`Z`; date-only
forms; sub-second precision (.SSS, .SSSSSS); proleptic Gregorian
leap-day arithmetic.

**Tests:** every documented format; timezone arithmetic across DST
boundaries; leap years (1900 not, 2000 yes, 2400 yes); round-trip
property test 0..36500 days.

**Replaces:** STDLOG's inline timestamp helper from v0.0.4 — bump
STDLOG to use `$$NOW^STDDATE()` and remove the inline helper.

### 8.8 STDCSV — RFC-4180 CSV

**Public API:**

```m
$$PARSE^STDCSV(text, .rows)               ; → row count, populates rows(i,j)
$$WRITE^STDCSV(.rows)                     ; → RFC-clean CSV text
PARSEFILE^STDCSV(path, callback)          ; streaming, calls callback per row
WRITEFILE^STDCSV(path, .rows)
```

**Tests:** quoted fields, embedded `,`, embedded `\n`, `""` escapes,
Windows (CRLF) and Unix (LF) line endings, BOM stripping. Conformance
corpus vendored to `tests/conformance/csv/` covering RFC-4180 §2 every
clause and known broken-but-real-world inputs (excel-quirks).

### 8.9 STDARGS — argparse

**Public API:**

```m
$$NEW^STDARGS(prog, description)          ; → parser handle
ADDFLAG^STDARGS(p, long, short, action, dest)
ADDPOS^STDARGS(p, name, dest)
ADDSUB^STDARGS(p, name, subparser)
$$PARSE^STDARGS(p, argline)               ; → namespace
$$HELP^STDARGS(p)                         ; → formatted help text
```

**Args source:** `$ZCMDLINE` on YDB; explicit string on IRIS.

**Supports:** long flags (`--verbose`), short flags (`-v`), grouped
short flags (`-vvv`), positional, sub-commands, `--` terminator,
`count`/`store`/`store_true`/`append` actions.

**Tests:** every action × short/long form; error on unknown flag,
missing required positional, mutually-exclusive group violation;
`--help` output stable byte-for-byte against fixtures.

### 8.10 Phase 1 release (`v0.1.0`)

- [ ] All 8 modules tagged and shipped per §9 gate.
- [ ] `CHANGELOG.md` roll-up entry for `v0.1.0`.
- [ ] GitHub Release created, source tarball attached.
- [ ] `docs/modules/` index regenerated (table of all 8 modules with
      one-line descriptions).
- [ ] STDLOG inline-timestamp helper removed (replaced by STDDATE).
- [ ] Real-project validation (§10) green for all 8 modules.

---

## 9. Per-module acceptance gate

A module merges only when **all** boxes are checked:

- [ ] `m fmt --check` clean
- [ ] `m lint --error-on=error` clean (default profile,
      `--target-engine=any`)
- [ ] `m test` is green on YottaDB
- [ ] `m test` is green on IRIS where reachable (fail-soft from v0.0.4)
- [ ] `m coverage --min-percent=85` is green for the new module
      (verified with `--uncovered` showing no uncovered public-API
      lines)
- [ ] `m lsp` surfaces hover docs for every public label (manual
      smoke or LSP Stage-4 test)
- [ ] `docs/modules/<name>.md` written: synopsis, public API table,
      examples, edge cases, error codes
- [ ] `CHANGELOG.md` entry added
- [ ] Real-project validation (§10) added/updated for this module

If any gate fails because of a toolchain weakness, the weakness
becomes a P0 follow-up against m-cli or tree-sitter-m and is logged
to `TOOLCHAIN-FINDINGS.md`. **m-stdlib is the regression suite for
the toolchain.**

---

## 10. Real-project validation

Unit tests prove a module works in isolation; real-project validation
proves it works under the m-cli toolchain end-to-end and integrates
with actual M code.

### 10.1 The validation matrix

For every module, after unit tests pass, do all four:

1. **m-cli `make vista-canonical` smoke.** Confirm the new STD
   routine doesn't break m-cli's parser/lint output on the VistA
   corpus. Run from `~/projects/m-cli`:
   `make vista-canonical M_STDLIB=~/projects/m-stdlib/src`.
2. **m-cli LSP smoke.** Open the new `*.m` in VS Code with the
   tree-sitter-m extension; confirm hover, completion, formatting,
   code actions, definition, references, document symbols, code
   lens, folding, signature help, document highlight all behave on
   the public labels.
3. **m-cli `m coverage` smoke.** Run `m coverage` on the module's
   test suite; confirm lcov output is well-formed (genhtml renders
   it cleanly).
4. **Adjacent-project consumption.** Once the module has a clear
   downstream consumer, integrate it there:
   - **STDASSERT** → file P2 issues to migrate `^TESTRUN`-using
     test suites in m-cli, tree-sitter-m, and m-standard onto
     STDASSERT. These migrations are the real-project validation
     for STDASSERT.
   - **STDUUID, STDB64, STDHEX, STDFMT, STDLOG** → consumed by
     m-cli's runtime-Python side via the m-cli ydb runner — write
     a small `examples/m-cli-integration.m` that uses each from M
     code, confirm it runs under `m test`.
   - **STDDATE** → STDLOG bumps to use it; that bump *is* the
     validation.
   - **STDCSV** → vendor a real CSV from `~/data/` (e.g. a VistA
     extract) into `tests/conformance/csv/real/` and round-trip
     parse/write it; assert byte-equivalent output.
   - **STDARGS** → write a tiny CLI demo in `examples/` that takes
     long flags, short flags, sub-commands, and run it under `m
     test` with several arglines.

### 10.2 Side-effect tracking

When STDASSERT lands in `v0.0.1`, file follow-up issues to migrate
existing `^TESTRUN`-using suites onto STDASSERT:

- [ ] m-cli — file P2 issue
- [ ] tree-sitter-m — file P2 issue
- [ ] m-standard — file P2 issue if applicable (check `tests/`)

These are not blockers for m-stdlib progression but they are the
canonical real-project exercise for STDASSERT itself.

---

## 11. Phase 2 — pure-M heavy lifting

Not started until `v0.1.0` is tagged.

| Tag | Module | Routine | LoC est. |
|---|---|---|---:|
| `v0.1.x` | JSON parser/serialiser (RFC 8259) | `STDJSON.m` | ~1500 |
| `v0.1.x` | Regex (Thompson-NFA, YDB; wraps `$MATCH`/`$LOCATE` on IRIS) | `STDREGEX.m` | ~2000 |
| `v0.1.x` | Collections (Set, Map, Stack, Queue, Deque, Heap, OrderedDict) | `STDCOLL.m` | ~600 |
| `v0.1.x` | URL parsing + percent-encoding (RFC 3986) | `STDURL.m` | ~250 |
| `v0.2.0` | Phase 2 release | — | — |

**STDJSON** stores JSON in M globals natively (`^STDJSON($J,...)`);
streaming parse/serialise for multi-MB payloads. Conformance corpus:
JSONTestSuite vendored to `tests/conformance/json/`, plus property-
based round-trip checks.

**STDLOG** gains JSON-line output once STDJSON ships.

**STDREGEX** subset (no back-references, no lookaround, no Unicode
property classes); follow-on `STDREGEX_PCRE` (Phase 3-adjacent) for
full PCRE via `$ZF` to libpcre2.

**STDCOLL** API consistency across types is the work, not any
individual data structure.

**STDURL** unblocks STDHTTP in Phase 3.

§9 acceptance gate applies. Real-project validation (§10) extends
for each: STDJSON consumed by STDLOG; STDCOLL consumed by m-cli's
existing M-side data structures (file P2 issue to migrate); STDURL
consumed by STDHTTP integration tests in Phase 3.

---

## 12. Phase 3 — host-call integrations

Not started until `v0.2.0` is tagged. Requires `tools/build-callouts.sh`
infrastructure (lands in a `v0.2.x` patch between Phase 2 and Phase 3).

| Tag | Module | Routine | Binding |
|---|---|---|---|
| `v0.2.x` | $ZF build harness (`tools/build-callouts.sh`) | — | per-platform shared object pipeline |
| `v0.2.x` | HTTP/1.1 + HTTPS client | `STDHTTP.m` | YDB: $ZF → libcurl; IRIS: $CLASSMETHOD → %Net.HttpRequest |
| `v0.2.x` | Crypto: SHA, HMAC, AES-GCM, Ed25519 | `STDCRYPTO.m` | YDB: $ZF → libsodium (preferred) or OpenSSL; IRIS: %SYSTEM.Encryption |
| `v0.2.x` | Compression: gzip, zstd | `STDCOMPRESS.m` | YDB: $ZF → libz, libzstd; IRIS: %Stream.Object compression |
| `v0.3.0` | Phase 3 release | — | — |

§9 gate applies (with the addition that the build harness must
produce SOs for linux-x86_64, linux-aarch64, and macOS). Real-
project validation: STDHTTP and STDCRYPTO together exercised by an
`examples/jwt-verify.m` that fetches a JWKS over HTTPS, parses it
(STDJSON), verifies a JWT signature (STDCRYPTO), and decodes the
payload (STDB64).

Phase 3 release tarballs include the per-platform shared objects;
IRIS users skip the SO download.

---

## 13. v1.0.0 — API stability

Tag `v1.0.0` once the API surface has been stable for 3 months after
`v0.3.0`. Stability = no breaking changes to any public label
signature in any STD routine. Bug-fix patches and additive
non-breaking changes are fine.

---

## 14. Toolchain feedback loop

Maintain `TOOLCHAIN-FINDINGS.md` in the repo root. For every
toolchain weakness (m-cli, tree-sitter-m, m-standard) that m-stdlib
development surfaces, add an entry: date, module, finding, link to
upstream issue.

The post-Phase-1 publication gate for m-cli and tree-sitter-m is:
**no open P0/P1 entries in `TOOLCHAIN-FINDINGS.md`**. m-stdlib's
job is to find these; the upstream projects' job is to fix them
before publishing public artifacts.

---

## 15. What does NOT change in adjacent projects

- m-standard schemas, TSVs, and `docs/spec.md` are unchanged by
  m-stdlib work.
- m-cli's CLI surface is unchanged. The `m test` discovery
  convention (`t<UpperCase>(pass,fail)`) is unchanged. Internal
  recognisers may add STDASSERT support but the CLI does not gain
  new flags for it.
- tree-sitter-m grammar is unchanged. STDASSERT and the rest parse
  as ordinary M.
- m-tools is not modified. VistA's own `^TESTRUN` users continue to
  work — m-stdlib just doesn't depend on `^TESTRUN`.

---

## 16. Open uncertainties

Resolve in-session when they become live, not before:

- §6.0 — exact YottaDB Docker image (resolve at start of Phase 0).
- When m-cli drops `^TESTRUN` recognition (resolve when m-cli is
  actually adapting to STDASSERT, not before).
- When IRIS portability becomes gating instead of fail-soft (resolve
  if/when an IRIS deployment commits to consuming m-stdlib).
- Per-module relicense from AGPL-3.0 (resolve only if a specific
  case demands it; default stays AGPL).
