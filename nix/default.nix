let
  sources = import ./sources.nix;
in
import sources.nixpkgs {
  overlays = [
    (pkgs: _: {
      inherit (import sources."gitignore.nix" {
        inherit (pkgs) lib;
      }) gitignoreSource;
    })
    (import "${sources.poetry2nix}/overlay.nix")
    (pkgs: super: {
      ibisTestingData = pkgs.fetchFromGitHub {
        owner = "ibis-project";
        repo = "testing-data";
        rev = "master";
        sha256 = "sha256-BZWi4kEumZemQeYoAtlUSw922p+R6opSWp/bmX0DjAo=";
      };

      duckdb = super.duckdb.overrideAttrs (attrs: {
        patches = attrs.patches or [ ] ++ [
          (pkgs.fetchpatch {
            name = "fix-list-type-metadata.patch";
            url = "https://github.com/duckdb/duckdb/commit/26d123fdc57273903573c72b1ddafc52f365e378.patch";
            sha256 = "sha256-ttqs5EjeSLhZQOXc43Y5/N5IYSESQTD1FZWV1uJ15Fo=";
          })
        ];
      });

      mkPoetryEnv = python: pkgs.poetry2nix.mkPoetryEnv {
        inherit python;
        projectDir = ../.;
        editablePackageSources = {
          ibis = ../ibis;
        };
        overrides = pkgs.poetry2nix.overrides.withDefaults (
          import ../poetry-overrides.nix {
            inherit pkgs;
            inherit (pkgs) lib stdenv;
          }
        );
      };

      prettierTOML = pkgs.writeShellScriptBin "prettier" ''
        ${pkgs.nodePackages.prettier}/bin/prettier \
        --plugin-search-dir "${pkgs.nodePackages.prettier-plugin-toml}/lib" \
        "$@"
      '';

      ibisDevEnv38 = pkgs.mkPoetryEnv pkgs.python38;
      ibisDevEnv39 = pkgs.mkPoetryEnv pkgs.python39;
      ibisDevEnv310 = pkgs.mkPoetryEnv pkgs.python310;
      ibisDevEnv = pkgs.ibisDevEnv310;

      mic = pkgs.writeShellApplication {
        name = "mic";
        runtimeInputs = [ pkgs.ibisDevEnv pkgs.coreutils ];
        # The immediate reason setting PYTHONPATH is necessary is to allow the
        # subprocess invocations of `mkdocs` by `mike` to see Python dependencies.
        #
        # This shouldn't be necessary, but I think the nix wrappers may be
        # indavertently preventing this.
        text = ''
          export PYTHONPATH TEMPDIR

          PYTHONPATH="$(python -c 'import os, sys; print(os.pathsep.join(sys.path))')"
          TEMPDIR="$(python -c 'import tempfile; print(tempfile.gettempdir())')"

          mike "$@"
        '';
      };

      aws-sdk-cpp = (super.aws-sdk-cpp.overrideAttrs (attrs: {
        patches = (attrs.patches or [ ]) ++ [
          # https://github.com/aws/aws-sdk-cpp/pull/1912
          (pkgs.fetchpatch {
            url = "https://github.com/aws/aws-sdk-cpp/commit/1884876d331f97e75e60a2f210b4ecd8401ecc8f.patch";
            sha256 = "sha256-nea8TF6iJcHjwv0nsbrbw15ALQfLeB/DvRRpk35AWAU=";
          })
        ];
      })).override {
        apis = [
          "cognito-identity"
          "config"
          "core"
          "identity-management"
          "s3"
          "sts"
          "transfer"
        ];
      };

      changelog = pkgs.writeShellApplication {
        name = "changelog";
        runtimeInputs = [ pkgs.nodePackages.conventional-changelog-cli ];
        text = ''
          conventional-changelog --preset conventionalcommits
        '';
      };

      preCommitShell = pkgs.mkShell {
        name = "preCommitShell";
        buildInputs = with pkgs; [
          git
          just
          nix-linter
          nixpkgs-fmt
          pre-commit
          prettierTOML
          shellcheck
          shfmt
        ];
      };
    } // super.lib.optionalAttrs super.stdenv.isDarwin {
      arrow-cpp = super.arrow-cpp.override {
        enableS3 = false;
      };
    })
  ];
}
