# Homelab NixOS deploy.
# Builds ON the NAS (this workstation is macOS/aarch64 and can't build Linux
# locally), then activates there.
#
# Override on the command line, e.g.:  make deploy TARGET=root@10.10.10.11

HOST    ?= nas
TARGET  ?= operator@10.10.10.11
# NOTE: the '#' must be escaped as '\#' — in Make a bare '#' starts a comment.
FLAKE   ?= .\#$(HOST)

# operator is non-root: escalate (passwordless sudo) for activation.
# ng nixos-rebuild uses `--sudo`; legacy perl used `--use-remote-sudo`.
SUDO    ?= --sudo

# nixos-rebuild is often not on PATH on macOS. Default to `nix run`; override
# with a real binary if you have one:  make deploy NRB=nixos-rebuild
NRB     ?= nix run nixpkgs\#nixos-rebuild --

# SSH identity that matches operator's authorized key (the ed25519 key —
# NOT the root/ansible_homelab key). Override if yours lives elsewhere:
#   make deploy KEY=~/.ssh/your_key
KEY     ?= ~/.ssh/id_ed25519
export NIX_SSHOPTS ?= -i $(KEY)
# Enable flakes even when nix.conf doesn't globally.
export NIX_CONFIG = extra-experimental-features = nix-command flakes

REBUILD = $(NRB) --flake $(FLAKE) --target-host $(TARGET) --build-host $(TARGET) $(SUDO)

.PHONY: deploy boot test dry build check

deploy: ## Build on NAS + activate now (switch) + set as boot default
	$(REBUILD) switch

boot: ## Build on NAS + set for next boot, no activation now
	$(REBUILD) boot

test: ## Build on NAS + activate now, do NOT persist to bootloader (reverts on reboot)
	$(REBUILD) test

dry: ## Show what would change without applying
	$(REBUILD) dry-activate

build: ## Build on NAS only, no activation (sanity check)
	$(NRB) --flake $(FLAKE) --build-host $(TARGET) build

check: ## Evaluate the flake locally
	nix flake check
