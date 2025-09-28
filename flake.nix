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
              (fetchpatch {
                name = "python-darwin-sandbox-fixes";
                url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/402244.patch";
                hash = "sha256-oQNxog28WoMAG0BuD6SoZxmPlKwz+rZxECaURkeXx4c=";
              })
              # (fetchpatch {
              #   name = "nodejs-shared-libs";
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/401454.patch";
              #   hash = "sha256-DLusI/Yr67vFkH/52jdYwqiUpXhV6I71lKkb69086/Y=";
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

                cinny-desktop = prev.cinny-desktop.overrideAttrs (prevCinny: {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild = ''
                    export HOME=$TMPDIR
                  '';
                });

                toml11 = prev.toml11.overrideAttrs {
                  patches = [
                    (prev.fetchpatch {
                      name = "todo";
                      url = "https://patch-diff.githubusercontent.com/raw/ToruNiina/toml11/pull/285.patch";
                      hash = "sha256-LZPr/cY6BZXC6/rBIAMCcqEdnhJs1AvbrPjpHF76uKg=";
                    })
                  ];
                };

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
              wolfssl
              xcpretty
              # https://github.com/harfbuzz/harfbuzz/blob/772279df448bdb550704e8dccd7f865bd0700cbd/test/api/test-coretext.c#L72
              harfbuzz
            ];
          };

          test = pkgs.nixd;

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                # affine
                _1password-cli
                ansible
                # ansible-language-server
                ansible-lint
                aria2
                asciinema
                asciinema_3
                attic-client
                atuin
                # awscli2
                bash-language-server
                bat
                bazelisk
                bitrise
                borgmatic
                broot
                btop
                bundler
                cargo-semver-checks
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
                diffutils
                direnv
                docker
                docker-compose
                dua
                eza
                fastlane
                fd
                firebase-tools
                fish
                flow
                fzf
                gh
                ghostty
                git
                git-branchless
                git-lfs
                github-mcp-server
                gnupg
                go
                go_1_24
                go_1_25
                google-cloud-sdk
                gopls
                groovy
                hadolint
                helix
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
                localsend
                logseq
                lokalise2-cli
                lnav
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
                ripgrep
                rsync
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
                yaml-language-server
                yamllint
                yt-dlp
                zeromq
                zsh
                zstd
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                cocoapods
                goku
                jazzy
                karabiner-elements
                raycast
                rectangle
                swift-quit
                tart
                terminal-notifier
                utm
                xcode-install
                xcodes
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                bluez
                cadvisor
                clickhouse
                e2fsprogs
                ghostty
                grafana
                logrotate
                lvm2
                mosquitto
                nixos-rebuild-ng
                node-red
                plausible
                pipewire
                podman
                postgresql
                prometheus
                prometheus-node-exporter
                prometheus-postgres-exporter
                raspberrypi-eeprom
                redlib
                smartmontools
                snowflake
                telegraf
                traefik
              ];
          };
        }
      );
    };
}
