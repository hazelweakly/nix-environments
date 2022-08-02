{ pkgs, config, lib, inputs, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  config.preset.python = {
    packages = pkgs: with pkgs.python3Packages; [ isort black vulture mypy flake8 inputs.mach-nix.packages.${pkgs.system}.mach-nix ];
    pre-commit-hooks = import ./pre-commit-hooks.nix { inherit lib; inherit (pkgs) black isort flake8 vulture mypy; };
    overlays = {
      py = _: prev: {
        inherit (prev.python3Packages) flake8 isort vulture;
      };
    };
  };
}
