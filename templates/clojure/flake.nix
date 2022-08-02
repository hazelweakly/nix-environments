{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix";

  outputs = { nix-template, ... }: nix-template.lib.mkFlake {
    projectName = "clojure";
    src = ./.;
    preset.clojure.enable = true;
  };
}
