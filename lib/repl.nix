{ flakePath ? null }:

let
  inherit (builtins) toString getFlake currentSystem pathExists;
  flake = if flakePath != null && pathExists flakePath then getFlake (toString flakePath) else { };
  nixpkgs = flake.outputs.packages.${currentSystem} or flake.outputs.legacyPackages.${currentSystem} or { };
  nixpkgsInput = flake.inputs.nixpkgs or flake.inputs.nix-template.inputs.nixpkgs or { };
  pkgs = nixpkgsInput.outputs.legacyPackages.${currentSystem} or { };
  nixpkgsOutput = (removeAttrs (nixpkgs // nixpkgs.lib or { }) [ "options" "config" ]);
in
{ inherit flake; }
// flake
// builtins
// { inherit pkgs; }
// pkgs
// nixpkgsOutput
  // { getFlake = path: getFlake (toString path); }
