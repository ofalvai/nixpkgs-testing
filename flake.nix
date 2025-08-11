{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=staging-next";
    nixpkgs-cached.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-cached,
    }:
    let
      forEachSystem = nixpkgs-cached.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = forEachSystem (
        system:
        let
          nixpkgsPatched = (import nixpkgs-cached { inherit system; }).applyPatches {
            name = "nixpkgs-patched";
            src = nixpkgs;
            patches = with nixpkgs-cached.legacyPackages.${system}.pkgs; [
              # python + darwin sandbox fixes
              (fetchpatch {
                url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/402244.patch";
                hash = "sha256-oQNxog28WoMAG0BuD6SoZxmPlKwz+rZxECaURkeXx4c=";
              })
              # (fetchpatch {
              #   name = "nodejs-darwin-sandbox";
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/425699.patch";
              #   hash = "sha256-m5LJ3/4NlZnldA/j6AWguwBNUMa42sng3ILLKi67G0I=";
              # })
            ];
          };
          pkgs = import nixpkgsPatched {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                  })
                ];

                cinny-desktop = prev.cinny-desktop.overrideAttrs(prevCinny: {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild = ''
                    export HOME=$TMPDIR
                  '';
                });

                haskellPackages = prev.haskellPackages.override {
                  overrides = hs-final: hs-prev: {
                    servant-client = hs-prev.servant-client.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    servant-auth-client = hs-prev.servant-auth-client.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };
                  };
                };
              })
            ];
          };
        in
        {
          stdenv = pkgs.stdenv;

          sandbox-test = pkgs.buildEnv {
            name = "sandbox-test";
            ignoreCollisions = true;
            paths = with pkgs; [
              nodejs
              nodejs-slim
              nodejs_20
              wolfssl
              xcpretty
            ];
          };

          test = pkgs.python313Packages.mypy;

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                _1password-cli
                # affine
                ansible
                ansible-language-server
                ansible-lint
                aria2
                asciinema
                asciinema_3
                atuin
                attic-client
                awscli2
                bash-language-server
                bat
                bazelisk
                bitrise
                borgmatic
                broot
                btop
                bundler
                cinny-desktop
                claude-code
                cmake
                ctop
                curl
                dart
                deno
                deploy-rs
                devenv
                difftastic
                direnv
                dua
                eza
                fastlane
                fd
                fish
                firebase-tools
                flow
                fzf
                gh
                git
                git-branchless
                git-lfs
                github-mcp-server
                gnupg
                go
                go_1_23
                go_1_24
                google-cloud-sdk
                gopls
                groovy
                helix
                hadolint
                hugo
                hydra-check
                imagemagick
                jdk17_headless
                jetbrains-mono
                jq
                jujutsu
                just
                kotlin
                languagetool
                lazygit
                lixPackageSets.latest.lix
                logseq
                localsend
                lokalise2-cli
                lsd
                marksman
                mercurial
                metabase
                micro
                nerd-fonts.symbols-only
                nil
                nix-direnv
                nix-output-monitor
                nix-search-cli
                nix-tree
                nix-your-shell
                nixd
                nixfmt-rfc-style
                nixpkgs-review
                nodePackages.tiddlywiki
                nushell
                nvd
                openvpn
                packer
                parallel
                php83
                pipx
                pnpm
                poetry
                protobuf
                pyenv
                pylint
                python311
                python312
                python313
                qemu
                rbenv
                readline
                rsync
                ripgrep
                screen
                shellcheck
                sonar-scanner-cli
                starship
                svelte-language-server
                tailscale
                tealdeer
                tree
                typescript-language-server
                vscode-langservers-extracted
                watchman
                wezterm
                wget
                xcpretty
                xh
                yamllint
                yaml-language-server
                yt-dlp
                zeromq
                zsh
                zstd
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                cocoapods
                goku
                karabiner-elements
                jazzy
                raycast
                rectangle
                swift-quit
                tart
                terminal-notifier
                utm
                xcodes
                xcode-install
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [

                clickhouse
                docker
                grafana
                plausible
                nixos-rebuild-ng
                postgresql
                ctop
                prometheus
                prometheus-node-exporter
                prometheus-postgres-exporter
                redlib
                cadvisor
                podman
                raspberrypi-eeprom
                bluez
                smartmontools
                telegraf
                node-red
                snowflake
                mosquitto
              ];
          };
        }
      );
    };
}
