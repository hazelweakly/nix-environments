{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix-environments";

  outputs = { nix-template, ... }: nix-template.lib.mkFlake {
    projectName = "react-native";
    src = ./.;
    preset.react-native.enable = true;
  };
}
