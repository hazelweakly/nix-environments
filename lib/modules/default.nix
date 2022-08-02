{ lib, inputs, config, system }:
let
  project = lib.evalModules {
    # This is the only way to pass in and override `lib` so that it behaves
    # normally in all downstream modules.
    #
    # We override it here to provide the same exact lib that's declared in
    # nix-template's flake (which is what is provided everywhere, including
    # overriding `pkgs.lib`).
    specialArgs = { inherit lib; };

    # project.nix defines the module structures and type definitions of
    # everything and takes care of merging all of the configurations together
    # into a singular attribute set that can be used to construct flakes,
    # devShells, or other project-related nix stuff.
    #
    # The actual presets are defined inside the presets folder. They are all
    # automatically included by traversing the directory automatically so that
    # you don't have to remember to modify this file.
    #
    # Consequently, this file and project.nix can be thought of being the very
    # low level implementation details and ideally shouldn't ever have to be
    # modified.
    modules =
      let
        presets = builtins.attrNames (builtins.readDir ../presets);
        paths = builtins.map (p: ../presets + "/${p}") presets;
      in
      paths ++ [
        # The definition and configuration of a presets and collection of presets.
        # The 'config' argument that this module takes is exactly the arguments
        # passed into mkFlake
        #
        # The output is at the bottom of this file: project.config.generated
        # It is _not_ a complete flake. It's everything needed to _build_ a
        # flake (and devShell, and related items) conveniently
        (import ./preset.nix)

        # This is handy little doodad which lets us write assertions in modules
        # and then have them checked + collected at evaluation time. See the
        # bottom of this file for how that gets integrated into the rest of
        # this.
        # Note: We grab this module directly as a string path from a
        # non-evaluated nixpkgs in order to avoid infinite recursion
        (inputs.nixpkgs.outPath + "/nixos/modules/misc/assertions.nix")

        # This is where the mkFlake arguments get injected into ./preset.nix
        { inherit config; }

        # Here we also add inputs module arguments
        # we can't actually add "lib" to the inputs; see specialArgs above.
        { config._module.args.inputs = inputs; }

        # This is necessary to make suree that `pkgs` (which we'll pass in shortly)
        # have any overlays applied to them. We need this otherwise you can't
        # declare an overlay in a preset and then use it in that same preset.
        #
        # How it works is we go through the modules and grab all defined
        # overlays, applying them to nixpkgs.
        # This relies heavily on fixpoints and laziness to work behind the
        # scenes; try not to stare into the abyss too long trying to puzzle
        # this out :)
        ({ config, ... }:
          let
            overlayAttrs = config.generated.overlays;
            pkgs = import inputs.nixpkgs {
              # Override nixpkgs's lib here with our own
              # (Normally, this is dangerous: For us, This is fine
              # because we guarantee already that this is a strict superst of
              # the exact same lib that ships with this instantiation of
              # nixpkgs)
              overlays = [ (_: _: { inherit lib; }) ] ++ builtins.attrValues (overlayAttrs);
              # Allowing broken lets us attempt to build things even if they're "marked" as broken.
              # This lets checks pass, and lets us override broken packages to
              # fix them; it doesn't prevent _actually_ broken derivations from
              # "building".
              config = { allowUnfree = true; allowUnsupportedSystem = true; allowBroken = true; };
              inherit system;
            };
          in
          {
            config._module.args.pkgsPath = lib.mkDefault pkgs.path;
            config._module.args.pkgs = lib.mkDefault pkgs;
          }
        )
      ];
  };

  failedAssertions = builtins.map (x: x.message) (builtins.filter (x: !x.assertion) project.config.assertions);

  checkedConfig =
    if failedAssertions != [ ]
    then throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (builtins.map (x: "- ${x}") failedAssertions)}"
    else project.config;

in
checkedConfig
