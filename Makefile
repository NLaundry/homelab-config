HOST   ?= nas
TARGET ?= operator@10.10.10.11
KEY    ?= $(HOME)/.ssh/id_ed25519
# Escape '#' so Make does not treat it as a comment.
FLAKE  ?= .\#$(HOST)

export NIX_SSHOPTS ?= -i $(KEY)
export NIX_CONFIG = extra-experimental-features = nix-command flakes

TEST_STORE ?= ssh-ng://operator@10.10.10.11?ssh-key=$(KEY)&system-features=kvm%20nixos-test

REBUILD = nix run .\#nixos-rebuild -- --flake $(FLAKE) --build-host $(TARGET)
ACTIVATE = $(REBUILD) --target-host $(TARGET) --sudo
VERIFY = env HOMELAB_NAS_ADDRESS="$(lastword $(subst @, ,$(TARGET)))" \
	HOMELAB_DEPLOYMENT_TARGET="$(TARGET)" HOMELAB_DEPLOYMENT_SSH_IDENTITY="$(KEY)" \
	nix run .\#verify --

.DEFAULT_GOAL := help
.PHONY: help check test-vm verify build preview try boot deploy

help:
	@printf '%s\n' \
		'Usage: make <command> [VARIABLE=value]' \
		'' \
		'Checks:' \
		'  check     Validate Nix configuration; no builds or live probes' \
		'  test-vm   Run Samba tests in disposable VMs on TEST_STORE' \
		'  verify    Check the live NAS; create and remove SMB test files' \
		'' \
		'Deployment:' \
		'  build     Build the NAS configuration without activation' \
		'  preview   Show activation changes without applying them' \
		'  try       Activate temporarily, then verify; keep the boot default' \
		'  boot      Select a configuration for the next boot; do not activate' \
		'  deploy    Activate now, make persistent, then verify' \
		'' \
		'Failed verification does not roll back an activation.' \
		'See README.md for prerequisites and overrides.'

check:
	nix flake check --no-update-lock-file --all-systems --no-build

# Use separate test guests to avoid changing the live NAS.
test-vm: check
	nix build --no-update-lock-file --store "$(TEST_STORE)" --eval-store auto --no-link .\#checks.x86_64-linux.nas-samba

verify:
	$(VERIFY) $(VERIFY_ARGS)

build:
	$(REBUILD) build

preview:
	$(ACTIVATE) dry-activate

boot:
	$(ACTIVATE) boot

# Keep a failed candidate active so the operator can inspect it.
try:
	$(VERIFY) --preflight $(VERIFY_ARGS)
	$(ACTIVATE) test
	@$(VERIFY) $(VERIFY_ARGS) || { status=$$?; printf '%s\n' 'Activation succeeded, but verification failed. No rollback was attempted.' >&2; exit $$status; }

deploy:
	$(VERIFY) --preflight $(VERIFY_ARGS)
	$(ACTIVATE) switch
	@$(VERIFY) $(VERIFY_ARGS) || { status=$$?; printf '%s\n' 'Activation succeeded, but verification failed. No rollback was attempted.' >&2; exit $$status; }
