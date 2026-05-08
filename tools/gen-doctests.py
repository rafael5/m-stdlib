#!/usr/bin/env python3
"""WD2: doctest generator.

Reads dist/stdlib-manifest.json, emits one tests/STD<MOD>DOCTST.m per
module that carries at least one doctest-eligible @example. Each
eligible example becomes a single-assertion test routine in the
emitted suite, runnable via the standard `m test` runner.

Eligible shapes (others are skipped — see --verbose for the list):

  Pattern A (exact-equal, string):
      write <expr>  ; "<expected>"
        => do eq^STDASSERT(.pass,.fail,<expr>,"<expected>","doctest: <label>")

  Pattern A-prefix (contains substring):
      write <expr>  ; "<prefix>..."
        => do contains^STDASSERT(.pass,.fail,<expr>,"<prefix>","doctest: <label>")

  Pattern A-num (exact-equal, numeric literal):
      write <expr>  ; <number>            (e.g. "; 1", "; -1", "; 3.14")
        => do eq^STDASSERT(.pass,.fail,<expr>,<number>,"doctest: <label>")

Anything else (bare set/do, multi-statement, $stack-dependent fragments)
is non-doctestable in the manifest sense — those examples reference
unbound state (parser handles, missing files, free variables) and would
produce false positives. They stay as illustrative documentation and
are silently skipped here.

Modes:
  default      regenerate tests/STD<MOD>DOCTST.m (overwrite)
  --check      drift check: regenerate + diff against committed copies;
               exit non-zero if any DOCTST file would change
  --verbose    print per-example accept/skip decisions to stderr

Determinism: examples are sorted by (module, label, example-index);
no timestamps in output.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST = REPO_ROOT / "dist" / "stdlib-manifest.json"
TESTS_DIR = REPO_ROOT / "tests"

# Source-side reformulation of the original 6 illustrative labels (commit
# `<follow-on>`) replaced their `; "<placeholder>"` `@example` lines with a
# pair: a host/state-dependent prose example (no quoted value, so the
# Pattern-A regex skips it silently) plus a self-contained Pattern-A
# example that doctests cleanly. As a result this skiplist is now empty
# — kept as a hook in case future modules need the same escape valve.
ILLUSTRATIVE_LABELS: dict[str, str] = {}

# Pattern A (string): write <expr>  ; "<expected>"
PAT_WRITE_EXPECT_STR = re.compile(r'^\s*(?:write|w)\s+(.+?)\s+;\s*"((?:[^"\\]|\\.)*)"\s*$')
# Pattern A-num: write <expr>  ; <number>           (signed int or decimal)
PAT_WRITE_EXPECT_NUM = re.compile(r'^\s*(?:write|w)\s+(.+?)\s+;\s*(-?\d+(?:\.\d+)?)\s*$')


def expression_is_self_contained(expr: str) -> bool:
    """True if expr only references string/numeric literals and routine calls.

    A self-contained expression has no free variables — running it as
    `do eq^STDASSERT(.pass,.fail,<expr>,<expected>,...)` won't trip
    M-MOD-024 (read-before-define) at lint time or `<UNDEF>` at run
    time. Free-variable examples like `write $$size^STDFS(path)` are
    illustrative documentation, not executable assertions, and must be
    skipped.

    Strategy: blank out the things that ARE allowed (strings, numbers,
    routine references like ``$$enc^STDB64(`` and ``^STDB64``); whatever
    identifier-shaped token remains is a free variable, and we skip.
    """
    s = expr
    # 1. Remove M string literals (handle "" as embedded quote).
    s = re.sub(r'"(?:[^"]|"")*"', "", s)
    # 2. Remove $$label^MODULE function-call openings.
    s = re.sub(r"\$\$[A-Za-z%][A-Za-z0-9]*\^[A-Za-z%][A-Za-z0-9]*", "", s)
    # 3. Remove $intrinsics ($extract, $length, $piece, $get, $data, ...).
    s = re.sub(r"\$[A-Za-z]+", "", s)
    # 4. Remove ^GLOBAL / ^ROUTINE references.
    s = re.sub(r"\^[A-Za-z%][A-Za-z0-9]*", "", s)
    # 5. Remove numeric literals.
    s = re.sub(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?", "", s)
    # 6. Anything left that looks like a bare identifier is a free var.
    return re.search(r"[A-Za-z]", s) is None


@dataclass(frozen=True)
class Doctest:
    module: str
    label: str
    expr: str
    expected: str
    is_prefix: bool
    is_numeric: bool = False  # if True, emit expected as a bare M numeric literal

    @property
    def routine_name(self) -> str:
        # M label names must be alpha-prefixed alnum — NO underscores
        # (underscore is the concatenation operator in M, so an
        # underscore in a label name is a parse error). Capitalize the
        # first character of `label` so `tDoctest` + `Decode` reads
        # camelCase, mirroring the project's hand-written test labels
        # (e.g. tEncodeRfcVectors).
        safe = re.sub(r"[^A-Za-z0-9]", "", self.label)
        if not safe:
            safe = "x"
        return "tDoctest" + safe[:1].upper() + safe[1:]

    @property
    def description(self) -> str:
        return f"doctest: {self.module}.{self.label}"


def classify(example: str) -> tuple[str, str, bool, bool] | None:
    """Return (expr, expected, is_prefix, is_numeric) if eligible, else None.

    An example is eligible only if it shape-matches Pattern A/A-num/A-prefix
    AND the expression is self-contained (no free variables). Examples
    that reference unbound state (`write $$size^STDFS(path)`) are
    skipped — see expression_is_self_contained.
    """
    s = example.strip()
    m = PAT_WRITE_EXPECT_STR.match(s)
    if m:
        expr = m.group(1).strip()
        if not expression_is_self_contained(expr):
            return None
        expected = m.group(2)
        is_prefix = expected.endswith("...")
        if is_prefix:
            expected = expected[:-3]
        return expr, expected, is_prefix, False
    m = PAT_WRITE_EXPECT_NUM.match(s)
    if m:
        expr = m.group(1).strip()
        if not expression_is_self_contained(expr):
            return None
        return expr, m.group(2), False, True
    return None


def collect(manifest: dict, *, verbose: bool = False) -> dict[str, list[Doctest]]:
    """Return {module: [Doctest, ...]}, sorted, only modules with hits."""
    by_module: dict[str, list[Doctest]] = {}
    accepted = skipped = 0
    for module_name in sorted(manifest.get("modules", {})):
        mod = manifest["modules"][module_name]
        labels = mod.get("labels", {})
        for label_name in sorted(labels):
            full = f"{module_name}.{label_name}"
            if full in ILLUSTRATIVE_LABELS:
                if verbose:
                    print(
                        f"  illust [{full}] (illustrative-only — {ILLUSTRATIVE_LABELS[full]})",
                        file=sys.stderr,
                    )
                skipped += len(labels[label_name].get("examples", []))
                continue
            for ex in labels[label_name].get("examples", []):
                cls = classify(ex)
                if cls is None:
                    skipped += 1
                    if verbose:
                        print(
                            f"  skip   [{module_name}.{label_name}] {ex.strip()}",
                            file=sys.stderr,
                        )
                    continue
                expr, expected, is_prefix, is_numeric = cls
                by_module.setdefault(module_name, []).append(
                    Doctest(
                        module=module_name,
                        label=label_name,
                        expr=expr,
                        expected=expected,
                        is_prefix=is_prefix,
                        is_numeric=is_numeric,
                    )
                )
                accepted += 1
                if verbose:
                    kind = "prefix" if is_prefix else ("numeric" if is_numeric else "exact  ")
                    print(
                        f"  {kind} [{module_name}.{label_name}] {ex.strip()}",
                        file=sys.stderr,
                    )
    if verbose:
        print(
            f"-- accepted={accepted}  skipped={skipped}  modules={len(by_module)}",
            file=sys.stderr,
        )
    return by_module


def m_string_literal(s: str) -> str:
    """Quote s as an M string literal (double-up internal quotes)."""
    return '"' + s.replace('"', '""') + '"'


def render_suite(module: str, doctests: list[Doctest]) -> str:
    """Emit M source. Indent is 8 spaces (matches project hand-written style;
    the tree-sitter-m parser rejects leading tabs)."""
    routine = f"STD{module[3:]}DOCTST" if module.startswith("STD") else f"{module}DOCTST"
    indent = " " * 8

    def label_header(label: str, comment: str) -> str:
        # Pad label out to the 8-column body column with spaces.
        pad = max(1, 8 - len(label))
        return f"{label}{' ' * pad}{comment}"

    lines: list[str] = []
    lines.append(label_header(routine, f"; Doctest suite for {module} — generated from @example tags."))
    lines.append(f"{indent}; Generated by tools/gen-doctests.py — DO NOT EDIT BY HAND.")
    lines.append(f"{indent}; Source: dist/stdlib-manifest.json (label @example tags in src/{module}.m).")
    lines.append(f"{indent}; Regenerate with `make doctest`.")
    # M-MOD-020: long-routine — generated suites can be large.
    # M-MOD-001: line-length    — assertion lines bake in literal arguments.
    # M-MOD-031: magic-literal  — expected values come straight from @example.
    lines.append(f"{indent}; m-lint: disable-file=M-MOD-020,M-MOD-001,M-MOD-031")
    lines.append(f"{indent}new pass,fail")
    lines.append(f"{indent}do start^STDASSERT(.pass,.fail)")
    lines.append(f"{indent};")
    for dt in doctests:
        lines.append(f"{indent}do {dt.routine_name}(.pass,.fail)")
    lines.append(f"{indent};")
    lines.append(f"{indent}do report^STDASSERT(pass,fail)")
    lines.append(f"{indent}quit")
    lines.append(f"{indent};")
    for dt in doctests:
        desc_quoted = m_string_literal(dt.description)
        header = f"{dt.routine_name}(pass,fail)"
        # Same column alignment as STDB64TST — pad to a common boundary.
        pad = max(1, 32 - len(header))
        lines.append(f"{header}{' ' * pad};@TEST {desc_quoted}")
        helper = "contains" if dt.is_prefix else "eq"
        if dt.is_numeric:
            expected_arg = dt.expected  # bare numeric literal, no quotes
        else:
            expected_arg = m_string_literal(dt.expected)
        lines.append(
            f"{indent}do {helper}^STDASSERT(.pass,.fail,{dt.expr},{expected_arg},{desc_quoted})"
        )
        lines.append(f"{indent}quit")
        lines.append(f"{indent};")
    return "\n".join(lines) + "\n"


def write_or_check(path: Path, content: str, *, check: bool) -> bool:
    """Return True if content matches (clean), False if drift/written."""
    if check:
        if not path.exists():
            print(f"DRIFT: missing {path.relative_to(REPO_ROOT)}", file=sys.stderr)
            return False
        existing = path.read_text(encoding="utf-8")
        if existing != content:
            print(f"DRIFT: {path.relative_to(REPO_ROOT)} differs", file=sys.stderr)
            return False
        return True
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def list_existing_doctest_files() -> set[Path]:
    return {p for p in TESTS_DIR.glob("STD*DOCTST.m")}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--check", action="store_true", help="drift check (no writes)")
    ap.add_argument("--verbose", action="store_true", help="trace classification decisions")
    args = ap.parse_args()

    if not MANIFEST.exists():
        print(
            f"ERROR: {MANIFEST.relative_to(REPO_ROOT)} not found — run `make manifest` first.",
            file=sys.stderr,
        )
        return 2

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    by_module = collect(manifest, verbose=args.verbose)

    expected_paths: set[Path] = set()
    clean = True
    for module in sorted(by_module):
        suite = render_suite(module, by_module[module])
        suffix = module[3:] if module.startswith("STD") else module
        path = TESTS_DIR / f"STD{suffix}DOCTST.m"
        expected_paths.add(path)
        ok = write_or_check(path, suite, check=args.check)
        clean = clean and ok

    # Detect orphaned DOCTST files (modules that lost all eligible examples).
    for stale in list_existing_doctest_files() - expected_paths:
        if args.check:
            print(
                f"DRIFT: orphan {stale.relative_to(REPO_ROOT)} (no eligible examples)",
                file=sys.stderr,
            )
            clean = False
        else:
            stale.unlink()
            print(
                f"  removed orphan {stale.relative_to(REPO_ROOT)}",
                file=sys.stderr,
            )

    if not args.check:
        total = sum(len(v) for v in by_module.values())
        print(
            f"doctest: wrote {len(by_module)} suite(s), {total} doctest(s)",
            file=sys.stderr,
        )

    return 0 if clean else 1


if __name__ == "__main__":
    sys.exit(main())
