{
  description = "KRM function to run Kustomize";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    kpt.url = "github:jashandeep-sohi/kpt";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, devenv-root, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        runtimeDeps = [
            pkgs.coreutils
            pkgs.yq-go
            pkgs.gitMinimal
            inputs'.kpt.packages.default
            pkgs.kustomize
        ];
      in {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        packages.default = pkgs.writeShellApplication {
          name = "krm-fn-kustomize";

          runtimeInputs = runtimeDeps;

          text = builtins.readFile ./krm-fn-kustomize.sh;
        };

        packages.container =  let
          user = "nobody";
          group = "nobody";
          uid = "1000";
          gid = "1000";
          tmp = pkgs.runCommand "tmp" {} ''
            mkdir -p $out/tmp
          '';
          makeImageUser = pkgs.runCommand "mkUser" { } ''
              mkdir -p $out/etc/pam.d
              echo "${user}:x:${uid}:${gid}::" > $out/etc/passwd
              echo "${user}:!x:::::::" > $out/etc/shadow
              echo "${group}:x:${gid}:" > $out/etc/group
              echo "${group}:x::" > $out/etc/gshadow
          '';
          package = config.packages.default;
        in with inputs'.nix2container.packages; nix2container.buildImage {
          name = "ghcr.io/jashandeep-sohi/krm-fn-kustomize";
          tag = "latest";
          copyToRoot = [ makeImageUser tmp ];
          perms = [
            { path = makeImageUser; regex = ".*"; mode = "0664"; uname = "nobody"; gname = "nobody"; }
            { path = tmp; regex = ".*"; mode = "0777"; }
          ];
          config = {
            User = user;
            Entrypoint = [
                "${package}/bin/${package.name}"
            ];
          };
        };

        devenv.shells.default = {
          devenv.root =
            let
              devenvRootFileContent = builtins.readFile devenv-root.outPath;
            in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

          imports = [
            # This is just like the imports in devenv.nix.
            # See https://devenv.sh/guides/using-with-flake-parts/#import-a-devenv-module
            # ./devenv-foo.nix
          ];

          # https://devenv.sh/reference/options/
          packages = [
            config.packages.default
          ] ++ runtimeDeps;

          enterShell = ''
            export SHELL=${pkgs.bashInteractive}/bin/bash
          '';
        };

      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
