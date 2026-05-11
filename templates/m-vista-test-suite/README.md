# `m-vista-test-suite` — STDASSERT-shaped tests for VistA modules

Template skeleton for writing **STDASSERT-shaped tests against VistA
package APIs**. Replaces the legacy `^TESTRUN` / `^%ut` style — those
runners are retired experimental scaffolding (see
`m-stdlib/CLAUDE.md`'s architectural note); STDASSERT is the
canonical and only test basis going forward.

## What you get

```
m-vista-test-suite/
├── routines/
│   ├── PXXTST.m            # one suite per VistA package — STDASSERT-driven
│   └── tests/
│       └── PXXTST.m         # alternate location if your project nests tests
├── fixtures/
│   ├── patients.tsv         # STDSEED TSV manifest (legacy + simple)
│   └── patients.json        # STDSEED JSON manifest (loaded via $$loadJson^STDSEED)
├── Makefile                 # `make test` / `make coverage`
└── .m-cli.toml              # opts the suite into VistA-aware lint rules
```

## How a VistA test reads under STDASSERT

```m
PXXTST  ; STDASSERT-driven test suite for the PXX package.
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tDemographicsLookupReturnsName(.pass,.fail)
        do tDemographicsLookupOnUnknownReturnsEmpty(.pass,.fail)
        do tInsertPatientFires^DD0Trigger(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tDemographicsLookupReturnsName(pass,fail) ;@TEST "$$DEM^VADPT(known DUZ) returns the patient's name"
        new dem
        do invoke^STDFIX("vista-test",
                . "do load^STDSEED($get(^|""TEMP""|),""fixtures/patients.tsv"",""capture^PXXTST"")"_
                . " new dem set dem=$$DEM^VADPT(.test_duz)"_
                . " do eq^STDASSERT(.pass,.fail,$piece(dem,$char(94)),""SMITH,JOHN"",""name field"")")
        quit
        ;
tDemographicsLookupOnUnknownReturnsEmpty(pass,fail) ;@TEST "$$DEM^VADPT(0) returns empty"
        do eq^STDASSERT(.pass,.fail,$$DEM^VADPT(0),"","empty on unknown DUZ")
        quit
        ;
tInsertPatientFires^DD0Trigger(pass,fail) ;@TEST "FILE^DIE on a NEW patient triggers the .01 cross-reference"
        ; Wrap the whole thing in a STDFIX transactional scope so the
        ; insert rolls back at the end of the test — fixture-data
        ; isolation per the m-stdlib STDFIX contract.
        do with^STDFIX("vista-test",
                . "do filePatient^PXX(""DOE,JANE"",""F"",""123456789"")"_
                . " do true^STDASSERT(.pass,.fail,$d(^DPT(""B"",""DOE,JANE"")),""B-xref written"")")
        quit
```

The pattern leans on three m-stdlib modules:

- **`STDASSERT`** drives all assertions (`eq`, `true`, `near`, `raises`, `contains`, ...).
- **`STDFIX`** wraps each test in a YDB transaction so fixture writes
  roll back per-test (`with` for one-shot, `invoke` if you need
  setup hooks).
- **`STDSEED`** loads test fixture data via FileMan FILE^DIE
  (`fileViaDie` filer) or via JSON (`$$loadJson` for in-memory
  records).

## Discovery and run

`m test` discovers `t<UpperCase>(pass,fail)` labels — same contract
as any other STDASSERT suite. Run from the project root:

```bash
m test routines/                 # whole suite
m test routines/PXXTST.m         # one file
m test routines/PXXTST.m::tDemographicsLookupReturnsName  # one test
m coverage --routines src --tests routines  # label-level coverage
```

Per-test isolation is on by default (the runner wraps each test in
a STDFIX transaction). For high-volume suites that don't need
isolation, pass `--no-isolation`.

## Lint config — `.m-cli.toml`

```toml
[lint]
rules = "vista-full"
target_engine = "yottadb"

[lint.vista]
kernel_locals = "default"
trusted_routines = "default"
```

The vista-full profile + the two allowlists turn off the M-MOD-024
and M-XINDX-007 false positives that hand-rolled VistA always
trips. See `m-cli/examples/vista-lint-presets/` for the rationale.

## What this template is NOT

- **Not a runtime substitute for KIDS pre/post-install validators.**
  KIDS scripts run at install time inside the package's namespace;
  STDASSERT tests run any time, against any DUZ, with explicit
  fixtures.
- **Not a substitute for FileMan integrity checks.** FileMan's own
  `^DIK1` / cross-reference validators are still the right tool for
  DD-level integrity. STDASSERT tests cover *behaviour through the
  package's public APIs*, not data-integrity invariants.
- **Not a vehicle for `^TESTRUN` / `^%ut` migration.** Files using
  those retired runners get rewritten in STDASSERT shape (see the
  example above), not bridged. Per `m-stdlib/CLAUDE.md`: "STDASSERT
  is the only canonical test basis going forward."

## References

- `m-stdlib/docs/users-guide.md` — m-stdlib overview, all 16 modules.
- `m-stdlib/docs/modules/stdfix.md` — transactional fixture wrappers.
- `m-stdlib/docs/modules/stdseed.md` — declarative test data loading.
- `m-stdlib/docs/modules/stdassert.md` — assertion API.
- `m-cli/examples/vista-lint-presets/` — VistA lint profile setup.
