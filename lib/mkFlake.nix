{ lib, inputs, config }:
let
  specializeConfig = system: if builtins.isFunction config then config system else config;

  # forallSystemsMap: { a = v; } => { <system>.a = v; }
  cfgs = lib.forallSystemsMap (system: (lib.mkRawConfig { inherit system; config = specializeConfig system; }).generated);

  flake = {
    devShells = lib.forallSystemsMap (system: {
      default = let inherit (cfgs.${system}) pkgs shellArgs; in pkgs.mkShell shellArgs;
    });

    # x86_64-darwin is picked as an arbitrary hardcoded system that we know
    # we'll always have (because it's in the system defaults).
    # These are functions that are system generic, but get generated needlessly
    # namespaced because of forallSystemsMap.
    inherit (cfgs.x86_64-darwin) overlays overlay;
    inherit lib;
  };

in
# forallSystems: { a = v; } => { a.<system> = v; }
flake // lib.forallSystems (system: {
  inherit (cfgs.${system}) legacyPackages packages checks apps;
  # compat: defaultX is deprecated as of Nix 2.7.0
  devShell = flake.devShells.${system}.default;
})
