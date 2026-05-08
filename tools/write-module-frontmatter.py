#!/usr/bin/env python3
"""Backfill YAML frontmatter onto every docs/modules/std<name>.md.

Spec: docs/plans/discoverability-and-tooling-plan.md § 3.3
Tracker: docs/tracking/discoverability-tracker.md WA6

Reads:
  - dist/stdlib-manifest.json  (synopsis, labels, errors per module)
  - docs/modules/index.md      (phase + tag mapping, conformance corpora,
                                cross-module dependency map)

Writes:
  - docs/modules/std<name>.md  (prepends frontmatter if absent)

Idempotent. If a file already starts with `---` (frontmatter already present),
the file is skipped — re-running won't trample manual edits. Use `--force`
to overwrite an existing frontmatter block.

Frontmatter schema:
  module:        STDXXX
  tag:           vX.Y.Z (the release this module first shipped in)
  phase:         "Phase 1" / "Phase 1b" / "Phase 2" / "P4 wave" / "Phase 3 + post-P4 wave"
  stable:        "stable" (default; modules in a tagged release are stable)
  since:         vX.Y.Z (same as tag for now)
  synopsis:      one-line summary from the routine header
  errors:        list of U-STDxxx-NAME codes raised (from manifest)
  labels:        list of public label names (from manifest)
  conformance:   list of conformance-corpus paths (from index.md table) or []
  see_also:      list of related modules (from index.md cross-deps section) or []

Usage:
  python3 tools/write-module-frontmatter.py            # idempotent backfill
  python3 tools/write-module-frontmatter.py --force    # overwrite existing FM
  python3 tools/write-module-frontmatter.py --dry-run  # print what would change
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES_DIR = REPO_ROOT / "docs" / "modules"
INDEX_PATH = MODULES_DIR / "index.md"
MANIFEST_PATH = REPO_ROOT / "dist" / "stdlib-manifest.json"

# Match a phase section header: `## Phase 1 (v0.1.0)` etc.
PHASE_HEADER_RE = re.compile(r"^##\s+(?P<phase>[^(]+?)\s*\([^)]*\)\s*$")

# Match a module table row:
#   | [`STDJSON`](stdjson.md) | `v0.2.0` | ... |
MODULE_ROW_RE = re.compile(
    r"^\|\s*\[`(?P<name>STD[A-Z0-9]+)`\]\([^)]+\)\s*\|\s*`(?P<tag>v[^`]+)`"
)

# Match a conformance-corpora row:
#   | `tests/conformance/b64/` | RFC-4648 §10 ... | `STDB64` |
CONFORMANCE_ROW_RE = re.compile(
    r"^\|\s*`(?P<path>tests/conformance/[^`]+)`\s*\|.*\|\s*`(?P<module>STD[A-Z0-9]+)`\s*\|"
)

# Match a cross-dep bullet:
#   - **STDLOG → STDDATE** — ...
#   - **STDLOG `FORMAT="json"` → STDJSON** — ...
#   - **STDCSPRNG → STDB64 / STDHEX / STDUUID** — ...
CROSS_DEP_RE = re.compile(
    r"^\s*-\s+\*\*(?P<src>STD[A-Z0-9]+)[^→]*→\s*(?P<rest>[^*]+)\*\*"
)


def parse_index() -> tuple[dict[str, dict], dict[str, list[str]], dict[str, list[str]]]:
    """Walk docs/modules/index.md and extract metadata maps.

    Returns:
      modules:     {NAME: {"phase": str, "tag": str}}
      conformance: {NAME: [path, ...]}     (only for modules with corpora)
      see_also:    {NAME: [other_module, ...]}  (from cross-deps section)
    """
    text = INDEX_PATH.read_text(encoding="utf-8")
    modules: dict[str, dict] = {}
    conformance: dict[str, list[str]] = {}
    see_also: dict[str, list[str]] = {}
    current_phase: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()

        # Track which Phase section we're inside.
        m = PHASE_HEADER_RE.match(line)
        if m:
            current_phase = m.group("phase").strip()
            continue

        # Module row inside a phase table.
        m = MODULE_ROW_RE.match(line)
        if m and current_phase:
            name = m.group("name")
            tag = m.group("tag")
            # Don't overwrite a module's first appearance — that's the "since" tag.
            if name not in modules:
                modules[name] = {"phase": current_phase, "tag": tag}
            continue

        # Conformance corpora row.
        m = CONFORMANCE_ROW_RE.match(line)
        if m:
            name = m.group("module")
            path = m.group("path")
            conformance.setdefault(name, []).append(path)
            continue

        # Cross-dependency bullet.
        m = CROSS_DEP_RE.match(line)
        if m:
            src = m.group("src")
            rest = m.group("rest")
            # `rest` may contain inline code or " / " separators — pull every STDxxx token.
            for tok in re.findall(r"\bSTD[A-Z0-9]+\b", rest):
                if tok != src and tok not in see_also.setdefault(src, []):
                    see_also.setdefault(src, []).append(tok)
                # Reverse edge — if A depends on B, B's "see also" should mention A too.
                if src not in see_also.setdefault(tok, []):
                    see_also.setdefault(tok, []).append(src)

    return modules, conformance, see_also


def render_frontmatter(name: str, manifest: dict, modules_map: dict, conformance: dict, see_also: dict) -> str:
    """Render the YAML frontmatter block for one module."""
    mod = manifest["modules"].get(name, {})
    phase_tag = modules_map.get(name, {})

    synopsis = (mod.get("synopsis") or "").strip()
    # Strip the `m-stdlib — ` prefix for cleaner one-line synopsis values.
    if synopsis.startswith("m-stdlib — "):
        synopsis = synopsis[len("m-stdlib — "):]
    # Trim a trailing period — the field reads better without it.
    if synopsis.endswith("."):
        synopsis = synopsis[:-1]

    labels = sorted(mod.get("labels", {}).keys())
    errors = sorted(mod.get("errors", []) or [])
    conf = conformance.get(name, [])
    sees = sorted(set(see_also.get(name, [])))

    lines = [
        "---",
        f"module: {name}",
        f"tag: {phase_tag.get('tag', '')}",
        f"phase: {phase_tag.get('phase', '')}",
        "stable: stable",
        f"since: {phase_tag.get('tag', '')}",
        f"synopsis: {yaml_str(synopsis)}",
        f"labels: {yaml_list(labels)}",
        f"errors: {yaml_list(errors)}",
        f"conformance: {yaml_list(conf)}",
        f"see_also: {yaml_list(sees)}",
        "---",
        "",
        "",  # produces a blank line between frontmatter and prose
    ]
    return "\n".join(lines)


def yaml_str(s: str) -> str:
    """Render a string as a YAML scalar — quote if it would be ambiguous."""
    if not s:
        return '""'
    # Always single-quote to avoid surprises with colons, leading dashes, etc.
    # Escape any embedded single quotes by doubling them (YAML 1.1/1.2 rule).
    return "'" + s.replace("'", "''") + "'"


def yaml_list(items: list[str]) -> str:
    """Render a list as a YAML flow sequence."""
    if not items:
        return "[]"
    # Each item gets the same single-quote treatment as scalars.
    rendered = ", ".join(yaml_str(i) for i in items)
    return "[" + rendered + "]"


def write_one(path: Path, frontmatter: str, force: bool, dry_run: bool) -> str:
    """Apply (or simulate) the frontmatter prefix.

    Returns one of: "wrote", "force-replaced", "skip-has-fm", "skip-dry".
    """
    content = path.read_text(encoding="utf-8")
    has_fm = content.startswith("---\n")

    if has_fm and not force:
        return "skip-has-fm"

    if has_fm and force:
        # Strip the existing frontmatter block (everything up to the second `---\n`).
        end = content.find("\n---\n", 4)
        if end < 0:
            # Malformed — leave the file alone.
            return "skip-has-fm"
        content = content[end + len("\n---\n"):].lstrip("\n")
        new = frontmatter + content
        action = "force-replaced"
    else:
        new = frontmatter + content
        action = "wrote"

    if dry_run:
        return f"would {action}"

    path.write_text(new, encoding="utf-8")
    return action


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--force", action="store_true", help="Overwrite existing frontmatter blocks.")
    p.add_argument("--dry-run", action="store_true", help="Report what would change without writing.")
    args = p.parse_args(argv)

    if not MANIFEST_PATH.exists():
        print(f"manifest missing — run `make manifest` first ({MANIFEST_PATH})", file=sys.stderr)
        return 2

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    modules_map, conformance, see_also = parse_index()

    wrote = 0
    skipped = 0
    forced = 0
    missing_in_index = []

    for path in sorted(MODULES_DIR.glob("std*.md")):
        # Module name = "STD" + stem-uppercase-without-leading-std.
        name = "STD" + path.stem[3:].upper()
        if name not in manifest["modules"]:
            print(f"warning: {path.name} → {name} not in manifest; skipping", file=sys.stderr)
            continue
        if name not in modules_map:
            missing_in_index.append(name)

        fm = render_frontmatter(name, manifest, modules_map, conformance, see_also)
        action = write_one(path, fm, args.force, args.dry_run)
        if action.startswith("skip"):
            skipped += 1
        elif "force" in action:
            forced += 1
        else:
            wrote += 1
        if action != "skip-has-fm":
            print(f"  {action}: {path.relative_to(REPO_ROOT)}")

    print(f"\nwrote: {wrote}, force-replaced: {forced}, skipped (already had FM): {skipped}")
    if missing_in_index:
        print(f"warning: {len(missing_in_index)} module(s) not found in index.md tables: {', '.join(missing_in_index)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
