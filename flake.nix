{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=staging";
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
                hash = "sha256-EWsHBAAdvlCwSlqLG5XVjicHF5O8sChkwn6a8DzlzIo=";
              })
              # nodejs: use more shared libs
              # (fetchpatch {
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/401454.patch";
              #   hash = "sha256-vxUlV9KnhJerktUi+/BK62JDGf3N3kv2CFiXFx358ss=";
              # })
            ];
          };
          pkgs = import nixpkgsPatched {
            inherit system;
            config.allowUnfree = true;
            # config.strictDepsByDefault = true;
            overlays = [
              (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                  })
                ];
                fontforge = prev.fontforge.overrideAttrs { strictDeps = false; };

                # wolfssl = prev.wolfssl.overrideAttrs {
                #   # test_wolfSSL_CTX_load_system_CA_certs
                #   # TODO: it's still not enough
                #   __impureHostDeps = [ "/System/Library/Security/Certificates.bundle" ];
                #   __darwinAllowLocalNetworking = true;
                # };

                cinny-desktop = prev.cinny-desktop.overrideAttrs {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild = ''
                    export HOME=$TMPDIR
                  '';
                };

                spotify-player = prev.spotify-player.overrideAttrs {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild = ''
                    export HOME=$TMPDIR
                  '';
                };

                haskellPackages = prev.haskellPackages.override {
                  overrides = hs-final: hs-prev: {
                    servant-client = hs-prev.servant-client.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    servant-auth-client = hs-prev.servant-auth-client.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };
                    network = hs-prev.network.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    here = prev.haskell.lib.overrideCabal hs-prev.here (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });

                    language-docker_11_0_0 = prev.haskell.lib.overrideCabal hs-prev.language-docker_11_0_0 (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });

                    http-date = prev.haskell.lib.overrideCabal hs-prev.http-date (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    http-types = prev.haskell.lib.overrideCabal hs-prev.http-types (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    auto-update = prev.haskell.lib.overrideCabal hs-prev.auto-update (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    text-zipper = prev.haskell.lib.overrideCabal hs-prev.text-zipper (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    word8 = prev.haskell.lib.overrideCabal hs-prev.word8 (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    hspec-wai = prev.haskell.lib.overrideCabal hs-prev.hspec-wai (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    yaml = prev.haskell.lib.overrideCabal hs-prev.yaml (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    say = prev.haskell.lib.overrideCabal hs-prev.say (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    ascii-progress = prev.haskell.lib.overrideCabal hs-prev.ascii-progress (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
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
            paths = with pkgs; [
              nodejs
              nodejs-slim
              nodejs_20
              wolfssl
              xcpretty
            ];
          };

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                _1password-cli
                affine
                # TODO: pythonPackages.future doesn't work with 3.13, textfsm depends on it
                ansible
                ansible-language-server
                ansible-lint
                aria
                asciinema
                asciinema_3
                atuin
                # anytype
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
                cmake
                ctop
                curl
                dart
                deno
                deploy-rs
                # devenv # /usr/bin/security access in tests
                difftastic
                direnv
                dua
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
                # gnupg
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
                jq
                # jujutsu
                just
                kotlin
                languagetool
                lazygit
                logseq
                lokalise2-cli
                lsd
                # marksman
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
                openconnect
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
                screen
                shellcheck
                sonar-scanner-cli
                spotify-player
                starship
                svelte-language-server
                tailscale
                tealdeer
                tree
                typescript-language-server
                watchman
                wezterm
                wget
                xcpretty
                xh
                yamllint
                yaml-language-server
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

              ];
          };
        }
      );
    };
}
