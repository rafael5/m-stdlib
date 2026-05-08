# m-stdlib Makefile.
#
# Engine: the shared vista-meta YottaDB container (no host YDB).
# `make test` and `make coverage` go through `m test` / `m coverage`
# which talk to vista-meta over SSH via ~/data/vista-meta/conn.env.

SHELL := /bin/bash

# m-cli venv — Python entry point for `m fmt` / `m lint` / `m test` / `m coverage`.
M ?= $(HOME)/projects/m-cli/.venv/bin/m

.PHONY: all fmt fmt-check lint test safe-test coverage check ci clean print-env seed unseed manifest manifest-check

# vista-meta connection contract — published by `vista-meta: make run`.
VISTA_CONN := $(HOME)/data/vista-meta/conn.env
ifeq ($(wildcard $(VISTA_CONN)),)
$(error vista-meta connection not configured: $(VISTA_CONN) missing — run: cd ~/projects/vista-meta && make run)
endif
include $(VISTA_CONN)
export VISTA_HOST VISTA_SSH_PORT VISTA_SSH_USER

all: check

print-env:
	@echo "M           = $(M)"
	@echo "VISTA_HOST  = $(VISTA_HOST)"
	@echo "VISTA_PORT  = $(VISTA_SSH_PORT)"

# ── Source-only ─────────────────────────────────────────────────────

fmt:
	$(M) fmt src/ tests/

fmt-check:
	$(M) fmt --check src/ tests/

lint:
	$(M) lint --error-on=error src/ tests/

# ── Engine-bound (m test / m coverage seed vista-meta automatically) ──

seed:
	@./scripts/seed-vista.sh

unseed:
	@./scripts/unseed-vista.sh

test:
	$(M) test tests/

# `safe-test` runs the same suites through scripts/safe-test.sh, which
# auto-recovers from the documented vista-meta container failure modes
# (stuck `mumps` processes, SSH MaxSessions exhaustion). Use this when
# a previous run crashed and `make test` is now hanging on the leak.
# Logs every attempt + recovery step to ~/data/m-stdlib/test-runs.log.
safe-test:
	@./scripts/safe-test.sh tests/

coverage:
	$(M) coverage --min-percent=85 --format=lcov > coverage.lcov

# `check` is the fast dev loop (fmt-check + lint + test). Coverage is gated
# per-module starting v0.0.1 — run it as `make coverage` or via `make ci`.
check: fmt-check lint test
	@echo "OK"

ci: check
	$(M) test --format=tap tests/ > test-results.tap
	$(M) coverage --routines src --tests tests --format=json > coverage.json

# ── Manifest generation (WA4: discoverability + tooling plan) ─────────
#
# `make manifest` regenerates dist/stdlib-manifest.json + dist/errors.json
# from src/STD*.m via the doc-comment grammar in
# docs/guides/m-doc-grammar.md. The manifest is the canonical
# machine-readable surface consumed by m-cli `m doc`, the VS Code
# extension, and the AI skill (Wave A → B/C/D).
#
# `make manifest-check` (WA5) re-runs the generator and fails on diff
# against the committed dist/ files — same model as `m fmt --check`.

manifest:
	python3 tools/gen-manifest.py

manifest-check: manifest
	@git diff --exit-code dist/stdlib-manifest.json dist/errors.json \
		|| { echo "ERROR: dist/ manifest is out of date — run 'make manifest' and commit."; exit 1; }
	@echo "manifest: clean"

clean:
	rm -rf coverage.lcov test-results.tap coverage.json
