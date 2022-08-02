{ config, pkgs, lib, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  config.preset.docker = {
    packages = pkgs: with pkgs; [ docker-compose docker ];
    pre-commit-hooks = import ./pre-commit-hooks.nix { inherit lib; inherit (pkgs) hadolint; };
  };
}
