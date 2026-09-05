HOST   ?= nas
TARGET ?= operator@10.10.10.11
KEY    ?= $(HOME)/.ssh/id_ed25519
# Escape '#' because Make treats it as a comment delimiter.
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
.PHONY: help lint test verify build dry try boot deploy

help:
	@printf '%s\n' \
		'Checks:      lint (evaluate)  test (remote VM)  verify (live NAS)' \
		'Deployment:  build  dry  try  boot  deploy' \
		'See README.md for behavior, prerequisites, and overrides.'

lint:
	nix flake check --no-update-lock-file --all-systems --no-build

# Runs disposable guests on TEST_STORE, not the live NAS configuration.
test: lint
	nix build --no-update-lock-file --store "$(TEST_STORE)" --eval-store auto --no-link .\#checks.x86_64-linux.nas-samba

verify:
	$(VERIFY) $(VERIFY_ARGS)

build:
	$(REBUILD) build

dry:
	$(ACTIVATE) dry-activate

boot:
	$(ACTIVATE) boot

# Both activations verify afterwards. A failed check leaves the candidate active.
try:
	$(ACTIVATE) test
	@$(VERIFY) || { status=$$?; printf '%s\n' 'Activation succeeded, but verification failed. No rollback was attempted.' >&2; exit $$status; }

deploy:
	$(ACTIVATE) switch
	@$(VERIFY) || { status=$$?; printf '%s\n' 'Activation succeeded, but verification failed. No rollback was attempted.' >&2; exit $$status; }
