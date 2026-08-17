# Homelab repository operations.
#
# Deployment operations build on and optionally activate the physical NAS.
# Testing operations keep validation, disposable VM tests, and deployed checks
# distinct. Run `make help` for the documented operation surface.

OPERATIONS := deploy boot try dry build lint test verify
NON_LIVE_PHASES := harness tooling agents current-bindings vm

HOST    ?= nas
TARGET  ?= operator@10.10.10.11
# NOTE: the '#' must be escaped as '\#' — in Make a bare '#' starts a comment.
FLAKE   ?= .\#$(HOST)

# operator is non-root: escalate (passwordless sudo) for activation.
# ng nixos-rebuild uses `--sudo`; legacy perl used `--use-remote-sudo`.
SUDO    ?= --sudo

# Nix is the bootstrap command. Repository-owned tools run through local,
# lock-pinned flake apps unless a controlled fixture overrides them.
NIX      ?= nix
NRB      ?= $(NIX) run .\#nixos-rebuild --
SPECBASE ?= $(NIX) run .\#specbase --

# SSH identity used by deployment and by the default remote test store.
KEY     ?= $(HOME)/.ssh/id_ed25519
export NIX_SSHOPTS ?= -i $(KEY)
# Enable flakes even when nix.conf does not enable them globally.
export NIX_CONFIG = extra-experimental-features = nix-command flakes

# The test command targets the remote store directly because macOS blocks
# daemon-owned SSH connections used by --builders. Override this one URI to move
# Linux/KVM execution; the selected derivations remain fixed.
TEST_STORE ?= ssh-ng://operator@10.10.10.11?ssh-key=$(KEY)&system-features=kvm%20nixos-test

# Optional Bats paths or flags forwarded after the packaged verify runner.
VERIFY_ARGS ?=

REBUILD = $(NRB) --flake $(FLAKE) --target-host $(TARGET) --build-host $(TARGET) $(SUDO)
RUN_VERIFY = $(NIX) run .\#verify --
RUN_SELECTED_VERIFY = $(RUN_VERIFY) $(VERIFY_ARGS)

.DEFAULT_GOAL := help
.PHONY: help $(OPERATIONS) $(addprefix test-,$(NON_LIVE_PHASES))

help: ## List documented repository operations
	@printf '%s\n' \
		'Usage: make <operation> [VARIABLE=value]' \
		'' \
		'Operations:' \
		'  deploy     Activate persistently, then verify the deployed homelab' \
		'  boot       Build on NAS and select the next-boot generation' \
		'  try        Activate temporarily, then verify the deployed homelab' \
		'  dry        Preview activation without applying it' \
		'  build      Build the NAS configuration without activation' \
		'  lint       Validate current specs and evaluate flake checks' \
		'  test       Run every safe non-live test phase' \
		'  verify     Run checks against the deployed homelab'

deploy: ## Build on NAS, activate persistently, then verify
	$(REBUILD) switch
	@printf '%s\n' 'Activation succeeded. Running deployed verification.'
	@$(RUN_VERIFY) || { status=$$?; printf '%s\n' 'Activation succeeded, but deployed verification failed. No rollback was attempted.' >&2; exit $$status; }

boot: ## Build on NAS and set the next-boot default without activating
	$(REBUILD) boot

try: ## Build on NAS, activate temporarily, then verify
	$(REBUILD) test
	@printf '%s\n' 'Activation succeeded. Running deployed verification.'
	@$(RUN_VERIFY) || { status=$$?; printf '%s\n' 'Activation succeeded, but deployed verification failed. No rollback was attempted.' >&2; exit $$status; }

dry: ## Preview the NAS activation without applying it
	$(REBUILD) dry-activate

build: ## Build the NAS configuration without activating it
	$(NRB) --flake $(FLAKE) --build-host $(TARGET) build

lint: ## Strictly validate current specs, then evaluate all flake checks
	$(SPECBASE) validate --specs --strict
	$(NIX) flake check --all-systems --no-build

test: lint ## Run every registered non-live phase
	@for phase in $(NON_LIVE_PHASES); do \
		printf 'test phase %s...\n' "$$phase"; \
		$(MAKE) --no-print-directory "test-$$phase" || exit $$?; \
	done

test-harness:
	$(NIX) run .\#harness

test-tooling:
	$(NIX) develop --command env "TEST_STORE=$(TEST_STORE)" bats tests/tooling/environment.bats

test-agents:
	$(NIX) develop --command tests/agents/specbase-instruments.sh all

test-current-bindings:
	$(NIX) develop --command tests/specbase/current-bindings.sh all-local

test-vm:
	$(NIX) build --store "$(TEST_STORE)" --eval-store auto --no-link .\#checks.x86_64-linux.vm-tests

verify: ## Run selected Bats checks against the deployed homelab
	$(RUN_SELECTED_VERIFY)
