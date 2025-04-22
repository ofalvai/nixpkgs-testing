{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=master";
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
              # node + strictDeps
              # (fetchpatch {
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/362151.patch";
              #   hash = "sha256-MWagFdcI+qc/amSCwRQmBfu19nuTseet+Q+ZfzgMEx0=";
              # })
              # # curl 8.13
              # (fetchpatch {
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/396200.patch";
              #   hash = "sha256-BjyGIMfSibgdP0lxY64PT/K6jBpBkRhXAcs/29Arcy4=";
              # })
              # randy libc++ rework
              # (fetchpatch {
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/398727.patch";
              #   hash = "sha256-lAj0XhMpKcS8mucs28xb/cNsd0uQvPs8Hmo9hrQIqQk=";
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
                    pyasynchat = python-prev.pyasynchat.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    requests-futures = python-prev.requests-futures.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    geoip2 = python-prev.geoip2.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    smtpdfix = python-prev.smtpdfix.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };
                    mocket = python-prev.mocket.overrideAttrs (mocket-prev: {
                      __darwinAllowLocalNetworking = true;
                      disabledTests = mocket-prev.disabledTests ++ [ "test_httprettish_httpx_session" ];

                    });
                    blockbuster = python-prev.blockbuster.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };
                    anyio = python-prev.anyio.overrideAttrs (anyio-prev: {
                      # Becomes flaky under heavy load: asserts empty logs, but a slowness warning appears in logs
                      disabledTests = anyio-prev.disabledTests ++ [ "test_asyncio_run_sync_called" ];
                    });
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
              # marksman
            ];
          };

          heavy = pkgs.buildEnv {
            name = "heavy-pkgs";
            paths = with pkgs; [
              nodejs
              nodejs-slim
              nodejs_20
            ];
          };

          test = pkgs.buildEnv {
            name = "test";
            paths = with pkgs; [
              ruby
              ruby_3_4
              ruby_3_2
              ruby_3_1
              go_1_22
              go_1_23
              go_1_24
              python311
              python312
              python313
            ];
            ignoreCollisions = true;
          };

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                _1password-cli
                ansible
                ansible-language-server
                ansible-lint
                aria
                atuin
                awscli2
                bash-language-server
                bat
                # bat-extras # sandbox issue in tests
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
                jq
                jujutsu
                just
                kotlin
                lazygit
                lokalise2-cli
                lsd
                # marksman # dotnet sandbox issue?
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
                terminal-notifier
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
