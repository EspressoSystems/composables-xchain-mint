{
  description = "Espresso Moka bridge";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.foundry-nix.url = "github:shazow/foundry.nix/stable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.solc-bin.url = "github:EspressoSystems/nix-solc-bin";

  outputs =
    { nixpkgs
    , foundry-nix
    , flake-utils
    , solc-bin
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      solhintPkg = { buildNpmPackage, fetchFromGitHub }:
        buildNpmPackage rec {
          pname = "solhint";
          # To update the solhint version:
          # 1. update the version tag
          # 2  uncomment empty hash and npmDepsHash
          # 3. activate `nix develop` and fill in the new hash
          # 4. activate `nix develop` again, fill in the npmDepsHash.
          version = "5.1.0";
          src = fetchFromGitHub {
            owner = "protofire";
            repo = pname;
            rev = "refs/tags/v${version}";
            # hash = "";
            hash = "sha256-hWf+4vSSqjSvN2SFC0z07QvnhQj1IWy3G1jh/E8Fuv8=";
          };
          # npmDepsHash = "";
          npmDepsHash = "sha256-DbkjOZ/TtHHvmWPgQA8yuoTFLfXQg0LYwe9caZ0tCOc=";
          dontNpmBuild = true;
        };
      hyperlanePkg = { stdenv, nodejs, fetchurl, makeWrapper }:
        stdenv.mkDerivation rec {
          pname = "hyperlane-cli";
          version = "18.2.0";

          src = fetchurl {
            url = "https://registry.npmjs.org/@hyperlane-xyz/cli/-/cli-${version}.tgz";
            hash = "sha256-Qhg0GJpVVLxIzhFE4bUhI2TOh7hP12ZF767c+dv8GPY=";
          };

          nativeBuildInputs = [ makeWrapper ];
          buildInputs = [ nodejs ];

          installPhase = ''
            mkdir -p $out/lib/node_modules/@hyperlane-xyz/cli
            cp -r . $out/lib/node_modules/@hyperlane-xyz/cli

            mkdir -p $out/bin
            makeWrapper ${nodejs}/bin/node $out/bin/hyperlane \
              --add-flags "$out/lib/node_modules/@hyperlane-xyz/cli/cli-bundle/index.js"
          '';
        };
      overlays = [
        foundry-nix.overlay
        solc-bin.overlays.default
        (final: prev: {
          solhint =
            solhintPkg { inherit (prev) buildNpmPackage fetchFromGitHub; };
          hyperlane-cli =
            hyperlanePkg { inherit (prev) stdenv nodejs fetchurl makeWrapper; };
        })
      ];
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays;
      };
    in
    {
      devShell = with pkgs;
        mkShell {
          buildInputs = [
            just
            foundry-bin
            solc
            solhint
            hyperlane-cli
            pre-commit
            yq # like jq for yaml
            process-compose
            envsubst
          ];
        };
    });

}
