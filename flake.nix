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
      overlays = [
        foundry-nix.overlay
        solc-bin.overlays.default
        (final: prev: {
          solhint =
            solhintPkg { inherit (prev) buildNpmPackage fetchFromGitHub; };
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
            foundry-bin
            solc
            solhint
            pre-commit
          ];
        };
    });

}
