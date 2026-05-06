SHELL := /bin/bash

# m-cli is the canonical CLI; .venv path is the Python install.
M ?= $(HOME)/projects/m-cli/.venv/bin/m

# vista-meta connection contract (must be running for `make test` /
# `make coverage` — see ~/projects/vista-meta/README.md).
VISTA_CONN := $(HOME)/data/vista-meta/conn.env
ifeq ($(wildcard $(VISTA_CONN)),)
$(error vista-meta connection not configured: $(VISTA_CONN) missing — run: cd ~/projects/vista-meta && make run)
endif
include $(VISTA_CONN)
export VISTA_HOST VISTA_SSH_PORT VISTA_SSH_USER

.PHONY: all fmt lint test coverage check clean

all: check

fmt:
	$(M) fmt routines/

lint:
	$(M) lint --error-on=error routines/

test:
	$(M) test routines/

# Coverage: 80 % per-package label-level is the practical first
# target for any modernization-grade VistA test suite. Tighten as
# the suite matures.
coverage:
	$(M) coverage --min-percent=80 --routines routines --tests routines

# Fast dev loop: format + lint + test. Use `make coverage` separately
# at PR-readiness time.
check: lint test

clean:
	rm -rf .coverage coverage.lcov coverage.json
