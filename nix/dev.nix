{ pkgs }:

let
  darwinSsh = pkgs.writeShellApplication {
    name = "ssh";
    text = ''
      if [[ ! -x /usr/bin/ssh ]]; then
        printf 'required macOS SSH transport is unavailable: /usr/bin/ssh\n' >&2
        exit 127
      fi
      exec /usr/bin/ssh "$@"
    '';
  };

  ssh = if pkgs.stdenv.hostPlatform.isDarwin then darwinSsh else pkgs.openssh;
in
{
  inherit ssh;

  packages = with pkgs; [
    age
    ansible
    bats
    git
    gnumake
    jq
    neovim
    nixos-rebuild
    opentofu
    shellcheck
    shfmt
    sops
    ssh
    yq-go
  ];
}
