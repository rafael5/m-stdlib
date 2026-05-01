# m-stdlib Makefile.
#
# Local-dev path uses the system YottaDB (/usr/local/lib/yottadb/r*)
# and the m-cli venv at ~/projects/m-cli/.venv. CI overrides PATH to
# point at the in-container install.

SHELL := /bin/bash

# YottaDB discovery — newest installed release line wins (local dev).
# CI sets ydb_dist via the canonical /opt/yottadb/current/ydb_env_set.
YDB_DIST ?= $(shell ls -d /usr/local/lib/yottadb/r* 2>/dev/null | sort -V | tail -1)

# m-cli venv — local dev default; CI sets M to /tmp/venv/bin/m.
M ?= $(HOME)/projects/m-cli/.venv/bin/m

# YottaDB env — bare exports (don't source ydb_env_set: it refuses to start
# if a previously-sourced gtmdir/gtm_dist disagrees with our project dirs).
# Mirrors the m-tools/scripts/ydb-env.sh pattern.
YDB_ENV := unset gtmdir gtm_dist gtmgbldir gtmroutines ; \
           export ydb_dist="$(YDB_DIST)" \
                  ydb_dir="$(CURDIR)/.ydb" \
                  ydb_gbldir="$(CURDIR)/.ydb/m-stdlib.gld" \
                  ydb_routines="$(CURDIR)/src $(CURDIR)/tests $(CURDIR)/.objects $(YDB_DIST)" \
                  PATH="$(YDB_DIST):$$PATH"

.PHONY: all setup-ydb fmt fmt-check lint test coverage check ci clean print-env

all: check

print-env:
	@echo "YDB_DIST = $(YDB_DIST)"
	@echo "M        = $(M)"

setup-ydb:
	@if [ -z "$(YDB_DIST)" ]; then echo "ERROR: YottaDB not found under /usr/local/lib/yottadb/" >&2; exit 1; fi
	@mkdir -p .objects
	@bash tools/init-db.sh

fmt:
	$(M) fmt src/ tests/

fmt-check:
	$(M) fmt --check src/ tests/

lint:
	$(M) lint --error-on=error src/ tests/

test: setup-ydb
	@$(YDB_ENV) && $(M) test tests/

coverage: setup-ydb
	@$(YDB_ENV) && $(M) coverage --min-percent=85 --format=lcov > coverage.lcov

# `check` is the fast dev loop (fmt-check + lint + test). Coverage is gated
# per-module starting v0.0.1 — run it as `make coverage` or via `make ci`.
check: fmt-check lint test
	@echo "OK"

ci: check
	@$(YDB_ENV) && $(M) test --format=tap > test-results.tap
	@$(YDB_ENV) && $(M) coverage --format=json > coverage.json

clean:
	rm -rf .ydb .objects coverage.lcov test-results.tap coverage.json
