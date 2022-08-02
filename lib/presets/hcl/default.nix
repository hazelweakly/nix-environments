{ config, pkgs, lib, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  config.preset.hcl = {
    packages = pkgs: with pkgs; [
      awscli2
      consul
      jq
      nomad_1_3
      packer
      python3Packages.ec2instanceconnectcli
      ssm-session-manager-plugin
      terraform
      vault
    ];
    pre-commit-hooks = import ./pre-commit-hooks.nix { inherit lib; inherit (pkgs) terraform-format; };
  };
}
