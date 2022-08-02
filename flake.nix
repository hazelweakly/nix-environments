{
  description = "Provides templates and a library to abstract common patterns.";

  # These inputs are used by at least one of the templates
  # They are manually flattened as much as possible to reduce the amount of fetches required.
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";

  # For react-native repos
  inputs.android.url = "github:tadfisher/android-nixpkgs/stable";
  inputs.android.inputs.nixpkgs.follows = "nixpkgs";
  inputs.android.inputs.flake-utils.follows = "flake-utils";
  inputs.android.inputs.devshell.follows = "devshell";

  # Specified only to flatten android
  inputs.devshell.url = "github:numtide/devshell";
  inputs.devshell.inputs.flake-utils.follows = "flake-utils";
  inputs.devshell.inputs.nixpkgs.follows = "nixpkgs";

  # For python repos
  inputs.mach-nix.url = "github:DavHau/mach-nix";
  inputs.mach-nix.inputs.flake-utils.follows = "flake-utils";
  inputs.mach-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";
  inputs.pypi-deps-db.url = "github:DavHau/pypi-deps-db";
  inputs.pypi-deps-db.inputs.mach-nix.follows = "mach-nix";
  inputs.pypi-deps-db.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, ... }: {
    templates = {
      base = {
        path = ./templates/base;
        description = "A basic setup for a repo";
        welcomeText = ''
          # A basic setup
          ## How to finish bootstrapping this project
          See [here](https://docs.are.cool)

          ## How Magic More Do Go Go?
          Something something slide into my DMs
        '';
      };

      clojure = {
        path = ./templates/clojure;
        description = "A basic setup for a clojure repo";
      };

      python = {
        path = ./templates/python;
        description = "A basic setup for a python repo";
      };

      react-native = {
        path = ./templates/react-native;
        description = "A basic setup for a react-native repo";
      };

      react = {
        path = ./templates/react;
        description = "A basic setup for a react repo";
      };

      hcl = {
        path = ./templates/hcl;
        description = "A basic setup for a hcl repo";
      };

      default = inputs.self.templates.base;
    };

    lib = import ./lib { inherit inputs; };

    checks = import ./tests { inherit inputs self; inherit (self) lib; };

    # compat: defaultX is deprecated as of Nix 2.7.0
    defaultTemplate = inputs.self.templates.base;
  };
}
