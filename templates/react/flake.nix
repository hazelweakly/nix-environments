{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix-environments";

  outputs = { nix-template, ... }: nix-template.lib.mkFlake {
    projectName = "react";
    src = ./.;
    preset.react.enable = true;
  };
}
