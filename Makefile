# m-stdlib Makefile.
#
# Engine: the shared vista-meta YottaDB container (no host YDB).
# `make test` and `make coverage` go through `m test` / `m coverage`
# which talk to vista-meta over SSH via ~/data/vista-meta/conn.env.

SHELL := /bin/bash

# m-cli venv — Python entry point for `m fmt` / `m lint` / `m test` / `m coverage`.
M ?= $(HOME)/projects/m-cli/.venv/bin/m

.PHONY: all fmt fmt-check lint test coverage check ci clean print-env seed unseed

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

coverage:
	$(M) coverage --min-percent=85 --format=lcov > coverage.lcov

# `check` is the fast dev loop (fmt-check + lint + test). Coverage is gated
# per-module starting v0.0.1 — run it as `make coverage` or via `make ci`.
check: fmt-check lint test
	@echo "OK"

ci: check
	$(M) test --format=tap tests/ > test-results.tap
	$(M) coverage --routines src --tests tests --format=json > coverage.json

clean:
	rm -rf coverage.lcov test-results.tap coverage.json
