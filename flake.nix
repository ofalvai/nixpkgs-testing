{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=staging";
  };

  outputs = { self, nixpkgs }: {

    packages.aarch64-darwin.default = let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in pkgs.buildEnv {
      name = "regression-pkg-set";
      paths = with pkgs; [
        fish
        git
        btop
        bitrise
        ripgrep
        lsd
        jq
        just
        micro
        dua
        starship
        fzf
        fd
        yazi
        nix-output-monitor
        helix
        nix-tree
        nvd
        direnv
        gh
        xcodes
        aria
        google-cloud-sdk
        lazygit
        _1password
        devenv
        nixfmt-rfc-style
        nil
        nixpkgs-review
        wezterm
        # poetry
      ];
    };


  };
}
