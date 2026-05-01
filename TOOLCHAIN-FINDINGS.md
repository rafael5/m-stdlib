# Toolchain findings — m-stdlib regression log

Per the implementation plan §14: every toolchain weakness that
m-stdlib development surfaces is logged here, against m-cli,
tree-sitter-m, or m-standard. The post-Phase-1 publication gate for
m-cli and tree-sitter-m is "no open P0/P1 entries in this file."

| Date | Severity | Project | Module | Finding | Status |
|---|---|---|---|---|---|
| 2026-04-30 | P1 | m-cli | `src/m_cli/test/runner.py` | `run_case` (single-test selection via `m test FILE.m::tLabel`) hard-codes `do start^TESTRUN(.pass,.fail)` and `do report^TESTRUN(pass,fail)` (lines 168–173). Whole-suite execution works against STDASSERT-driven suites because the output-protocol parser is shape-based, but per-case selection breaks. | open — companion PR scheduled when m-cli adapts to STDASSERT (plan §13.5). m-stdlib v0.0.1 only uses whole-suite mode, so non-blocking. |
| 2026-04-30 | P3 | m-cli | `M-MOD-020` (by-reference args) | False positive when label name shadows formal parameter name (e.g. `pass(pass,desc)` inherited from `^TESTRUN` style). Lint-time analysis treats writes-to-formal as writes-to-local-of-same-name. Fires on the probe-stub STDASSERT — to be dissolved in v0.0.1 by renaming the inner labels (e.g. `recordPass` / `recordFail`). | open — fix at v0.0.1 by avoiding the shadowed-name pattern entirely; no m-cli change needed. |
