{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix";

  outputs = { nix-template, ... }: nix-template.lib.mkFlake {
    projectName = "base";
    src = ./.;
    preset.base.enable = true;
  };
}
