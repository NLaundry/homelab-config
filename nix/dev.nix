{ pkgs, secretspec }:

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

  ansible = pkgs.ansible.override {
    extraPackages = pythonPackages: [ pythonPackages.httpx ];
  };

  starshipConfig = pkgs.writeText "homelab-starship.toml" ''
    add_newline = true
    palette = "catppuccin_mocha"
    format = """$directory$git_branch$git_status$nix_shell$cmd_duration
    $character"""

    [character]
    success_symbol = "[❯](bold green)"
    error_symbol = "[❯](bold red)"
    vimcmd_symbol = "[❮](bold mauve)"

    [directory]
    style = "bold blue"
    truncation_length = 4
    truncate_to_repo = false

    [git_branch]
    format = " on [$symbol$branch]($style)"
    style = "bold mauve"
    symbol = "git:"

    [git_status]
    format = "([$all_status$ahead_behind]($style))"
    style = "bold yellow"

    [nix_shell]
    format = " via [$symbol$name]($style)"
    style = "bold sapphire"
    symbol = "nix:"

    [cmd_duration]
    min_time = 1000
    format = " took [$duration]($style)"
    style = "bold peach"

    [palettes.catppuccin_mocha]
    rosewater = "#f5e0dc"
    flamingo = "#f2cdcd"
    pink = "#f5c2e7"
    mauve = "#cba6f7"
    red = "#f38ba8"
    maroon = "#eba0ac"
    peach = "#fab387"
    yellow = "#f9e2af"
    green = "#a6e3a1"
    teal = "#94e2d5"
    sky = "#89dceb"
    sapphire = "#74c7ec"
    blue = "#89b4fa"
    lavender = "#b4befe"
    text = "#cdd6f4"
    subtext1 = "#bac2de"
    subtext0 = "#a6adc8"
    overlay2 = "#9399b2"
    overlay1 = "#7f849c"
    overlay0 = "#6c7086"
    surface2 = "#585b70"
    surface1 = "#45475a"
    surface0 = "#313244"
    base = "#1e1e2e"
    mantle = "#181825"
    crust = "#11111b"
  '';

  lazyVimInit = pkgs.writeText "homelab-lazyvim-init.lua" ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}")

    require("lazy").setup({
      spec = {
        {
          dir = "${pkgs.vimPlugins.LazyVim}",
          name = "LazyVim",
          import = "lazyvim.plugins",
        },
        { import = "lazyvim.plugins.extras.lang.ansible" },
        { import = "lazyvim.plugins.extras.lang.git" },
        { import = "lazyvim.plugins.extras.lang.markdown" },
        { import = "lazyvim.plugins.extras.lang.nix" },
        { import = "lazyvim.plugins.extras.lang.terraform" },
        { import = "lazyvim.plugins.extras.lang.yaml" },
      },
      defaults = {
        lazy = false,
        version = false,
      },
      install = { colorscheme = { "tokyonight", "habamax" } },
      checker = { enabled = false },
      change_detection = { notify = false },
      lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
      performance = {
        rtp = {
          disabled_plugins = {
            "gzip",
            "netrwPlugin",
            "tarPlugin",
            "tohtml",
            "tutor",
            "zipPlugin",
          },
        },
      },
    })
  '';

  lazyvim = pkgs.writeShellApplication {
    name = "lazyvim";
    runtimeInputs = with pkgs; [
      curl
      gcc
      git
      gnumake
      neovim
      unzip
    ];
    text = ''
      export NVIM_APPNAME=homelab-lazyvim
      exec ${pkgs.neovim}/bin/nvim -u ${lazyVimInit} "$@"
    '';
  };
in
{
  inherit ssh;

  packages = with pkgs; [
    # Homelab operations.
    age
    ansible
    bats
    curl
    dig
    git
    gnumake
    go_1_25 # Local PKI tests require Go >= 1.24.
    jq
    nixos-rebuild
    openssl
    opentofu
    python3
    shellcheck
    shfmt
    sops
    secretspec
    step-cli
    ssh
    yq-go

    # Interactive terminal experience.
    bat
    delta
    eza
    fd
    fzf
    lazygit
    ripgrep
    starship
    tree-sitter
    vivid
    zoxide

    # Editor and repository language tooling.
    ansible-language-server
    deadnix
    lazyvim
    lua-language-server
    marksman
    neovim
    nixd
    nixfmt
    statix
    stylua
    terraform-ls
    yaml-language-server
  ];

  shellHook = ''
    export BAT_THEME="Catppuccin Mocha"
    export CLICOLOR=1
    export COLORTERM=truecolor
    export EDITOR=nvim
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border rounded --info inline --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8'
    export GIT_PAGER='delta --line-numbers'
    export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate catppuccin-mocha)"
    export STARSHIP_CONFIG=${starshipConfig}
    export VISUAL=nvim

    if [[ $- == *i* ]]; then
      eval "$(${pkgs.starship}/bin/starship init bash)"
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"

      alias la='eza --all --group-directories-first'
      alias ll='eza --long --all --git --group-directories-first'
      alias lt='eza --tree --level=2 --group-directories-first'
      alias lg='lazygit'

      printf '\033[1;35mhomelab-config\033[0m dev shell · run \033[1;36mmake help\033[0m or \033[1;36mlazyvim\033[0m\n'
    fi
  '';
}
