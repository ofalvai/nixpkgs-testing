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
          nixpkgs-patched = (import nixpkgs-cached { inherit system; }).applyPatches {
            name = "nixpkgs-patched";
            src = nixpkgs;
            patches = with nixpkgs-cached.legacyPackages.${system}.pkgs; [
              # (fetchpatch {
              #   # xmlto
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/353329.patch";
              #   hash = "sha256-9rCD52mnQlOopDqZfSJDE1WYXJJLcHP/ylnhUU2fnqs=";
              # })
              # (fetchpatch {
              #   # buildNodePackage
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/362151.patch";
              #   hash = "sha256-BujQ9V+qGrY+auq5IhNMkkNaJpmZjpm0iT4ZvRqRTxw=";
              # })
              # ./dejavu_fonts.patch
              # (fetchpatch {
              #   # ansible-compat
              #   url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/368789.patch";
              #   hash = "sha256-WidHC7bvJlXIkUhpoPDvzCVbOBd9Fh4b6LwZXdblbdI=";
              # })
            ];
          };
          pkgs = import nixpkgs-patched {
            inherit system;
            config.allowUnfree = true;
            config.strictDepsByDefault = false;
            config.permittedInsecurePackages = [
              "cinny-4.2.3"
              "cinny-unwrapped-4.2.3"
            ];
            overlays = [
              (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                    pytest-services = python-prev.pytest-services.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    waitress = python-prev.waitress.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    # Sandbox issue, tries to load system fonts.
                    # It's surfaced as a Cairo memory error in tests
                    cairocffi = python-prev.cairocffi.overrideAttrs {
                      disabledTests = [
                        "test_recording_surface"
                        "test_unbounded_recording_surface"
                        "test_context_font"
                        "test_scaled_font"
                        "test_glyphs"
                      ];
                    };

                    pycairo = python-prev.pycairo.overrideAttrs {
                      __impureHostDeps = [ "/System/Library/Fonts" ];
                    };

                    uvloop = python-prev.uvloop.overrideAttrs {
                      disabledTestPaths = [
                        # Regardless of sandbox, this test just fails on my machine
                        "tests/test_dns.py"
                      ];
                    };

                    pygal = python-prev.pygal.overrideAttrs {
                      __impureHostDeps = [ "/System/Library/Fonts" ];
                    };

                    pook = python-prev.pook.overrideAttrs {
                      # Tests launch a local server
                      __darwinAllowLocalNetworking = true;
                    };
                  })
                ];

                # fontforge = prev.fontforge.overrideAttrs { strictDeps = false; };

                # TODO: maybe not needed?
                mbedtls = prev.mbedtls.overrideAttrs {
                  env.NIX_CFLAGS_COMPILE = "-Wno-error=unused-command-line-argument";
                };

                wolfssl = prev.wolfssl.overrideAttrs {
                  # test_wolfSSL_CTX_load_system_CA_certs
                  # TODO: it's still not enough
                  __impureHostDeps = [ "/System/Library/Security/Certificates.bundle" ];
                  __darwinAllowLocalNetworking = true;
                };

                # Sandbox issue in test066-autoca
                # TODO: still not enough
                openldap = prev.openldap.overrideAttrs {
                  __darwinAllowLocalNetworking = true;
                };

                # Sandbox bug
                # https://github.com/NixOS/nixpkgs/pull/374884
                openvpn = prev.openvpn.overrideAttrs (prevOpenvpn: {
                  nativeBuildInputs = prevOpenvpn.nativeBuildInputs ++ [
                    prev.unixtools.route
                    prev.unixtools.ifconfig
                  ];
                });

                cinny-desktop = prev.cinny-desktop.overrideAttrs {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild =  ''
                    export HOME=$TMPDIR
                  '';
                };

                spotify-player = prev.spotify-player.overrideAttrs {
                  # tries to access HOME only in aarch64-darwin environment when building mac-notification-sys
                  preBuild =  ''
                    export HOME=$TMPDIR
                  '';
                };


                # Already merged to master
                rustc = prev.rustc.overrideAttrs {
                  __impureHostDeps = [ "/usr/bin/strip" ];
                };

                awscli2 = prev.awscli2.overrideAttrs {
                  __darwinAllowLocalNetworking = true;
                };

                haskellPackages = prev.haskellPackages.override {
                  overrides = hs-final: hs-prev: {

                    servant-client = hs-prev.servant-client.overrideAttrs {
                      __darwinAllowLocalNetworking = true;
                    };

                    here = prev.haskell.lib.overrideCabal hs-prev.here (drv: {
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
                    ascii-progress = prev.haskell.lib.overrideCabal hs-prev.ascii-progress (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    text-zipper = prev.haskell.lib.overrideCabal hs-prev.text-zipper (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    word8 = prev.haskell.lib.overrideCabal hs-prev.word8 (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    say = prev.haskell.lib.overrideCabal hs-prev.say (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    hspec-wai = prev.haskell.lib.overrideCabal hs-prev.hspec-wai (drv: {
                      testToolDepends = drv.testToolDepends or [ ] ++ [ hs-final.hspec-discover ];
                    });
                    yaml = prev.haskell.lib.overrideCabal hs-prev.yaml (drv: {
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
              openldap
              postgresql
              rustc
              xcode-install
              python312Packages.uvloop
              wolfssl
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

          default = pkgs.buildEnv {
            name = "regression-pkg-set";
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
                bat-extras
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
                git-lfs
                gnupg
                go
                go_1_22
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
                just
                kotlin
                lazygit
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
                nix-tree
                nix-your-shell
                nixd
                nixfmt-rfc-style
                nixpkgs-review
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
                tree
                typescript-language-server
                wezterm
                wget
                xcpretty
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
