{ lib, inputs, config, pkgs, options, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf literalExpression;

  # This... is complex and annoying, but it was easier than writing a fully custom merge function
  # The long story short is that it "intuitively" merges everything together so
  # that config.preset.<preset> options can be declared separately and they'll
  # all get smushed together in the end
  mergedType = with types; submodule { freeformType = oneOf [ (listOf mergedSubType) (attrsOf mergedSubType) mergedSubType ]; };
  mergedSubType = with types; oneOf [ mergedPrimitive (submodule { freeformType = mergedPrimitive; }) ];
  mergedPrimitive = with types; (oneOf [ (listOf primitiveType) (attrsOf primitiveType) primitiveType ]);
  primitiveType = with types; (oneOf [ bool str int float package path attrs mergedPrimitive ]);

  presetType = types.enum (builtins.attrNames config.preset);
  cfg = config;

  appSubmodule = { config, ... }: {
    options = {
      type = mkOption {
        type = types.enum [ "app" ];
        default = "app";
      };
      program = mkOption {
        type = with types; coercedTo (either (functionTo (package)) package) (o: lib.getExe (if builtins.isFunction o then o pkgs else o)) (path);
        description = "the program";
      };
    };
  };

  hookSubmodule = { config, ... }:
    let c = config; in
    {
      options = {
        enable = mkEnableOption "hook config" // { default = true; };
        text = mkOption {
          type = types.str;
          description = "commands to be run. Will be concatenated together to form a single script";
          default = "";
          example = literalExpression ''
            shellHooks.just.text = '''
              [[ -f justfile  ]] && command -v just >/dev/null 2>&1 && just
            ''';
          '';
        };
        enableInCI = mkEnableOption "enable in CI";
        rendered = mkOption {
          type = types.str;
          visible = false;
          default = "";
        };
      };
      config.rendered = mkIf config.enable (
        let hook = config.text; in
        if !config.enableInCI then ''
          if [[ -z "$CI" ]]; then
            ${hook}
          fi
        '' else hook
      );
    };

  presetSubmodule = {
    options = {
      enable = mkEnableOption "whether or not to enable a preset";

      # This is a merged type, however we need to add back in a `mkForce` on
      # any overridden options before passing this into pre-commit-hooks.
      # See the explanation below:
      pre-commit-hooks = mkOption {
        type = mergedType;
        description = ''
          A nix representation of a pre-commit hook from pre-commit-hooks.nix.
          See https://github.com/cachix/pre-commit-hooks.nix for more details
        '';
        example = literalExpression ''
          {
            end-of-file-fixer = {
              enable = true;
              description = "Ensure files are empty or end with one newline";
              entry = lib.mkDefault "''${pre-commit-hooks}/bin/end-of-file-fixer";
              types = [ "text" ];
            };
          }
        '';

        # This is a little janky. Here's what's happening:
        # We would like to let people override pre-commit-hooks by way of using lib.mkForce
        #
        # However, we also want people to merge their definitions of various
        # pre-commit-hooks by way of enabling presets.
        # So we come to a dilemma: We can disallow all duplication or
        # overriding, and then things can be passed through "raw". Or, we can
        # allow duplication and overriding, but have no way to "preserve"
        # options. We want the best of both worlds, here.
        #
        # Concretely: if someone writes lib.mkForce on an entry to change a binary
        # that's used, it'll get resolved into the highest priority option *before*
        # the pre-commit-check gets it.
        # However, should the pre-commit-check declare that option itself, you'll
        # run into a conflicting option.
        #
        # The proper solution might be fancier, but for now what we do is we dig
        # into the hooks configuration object and rewrite all the entries to have
        # a mkForce priority unconditionally.
        apply = (lib.mapAttrs
          (_: hook: hook // lib.optionalAttrs (hook ? "entry") { entry = lib.mkForce hook.entry; }));
        default = { };
      };

      shellHooks = mkOption {
        type = types.attrsOf (types.submodule [ hookSubmodule ]);
        description = ''
          A set of shell hooks that will be concatenated together to form a
          single script which gets run upon entering a nix shell
        '';
        default = { };
      };

      direnvHooks = mkOption {
        type = types.attrsOf (types.submodule [ hookSubmodule ]);
        description = ''
          A set of direnv hooks that will be concatenated together to form a
          single script which becomes the contents of the `.envrc` file at the
          root of a repository. This file is run by direnv automatically upon
          entering a directory where direnv is enabled.
          `direnv reload` will also rerun the `.envrc` file.

          Inside these fragments, the direnv standard library is available.

          IMPORTANT: Direnv is not a guarantee, it's a convenience. It is not
          used in CI and it should not be relied upon for working functionality
          as a developer may choose to use a manual invokation of `nix develop`
          instead; prefer shell hooks instead whenever possible.
        '';
        example = literalExpression ''
          direnv_version 2.23.0 || {
            echo >&2 "Please upgrade direnv to continue"
            exit 1
          } # This will succeed because direnv_version is defined.

          # This also works
          layout node
        '';
        default = { };
      };

      shellArgs = mkOption {
        type = mergedType;
        description = "raw arguments passed through to mkShell for the generated devShells";
        example = literalExpression ''
          {
            buildInputs = [ some-runtime-dependency ];
            ENV_VAR = "value"; # available as $ENV_VAR in a nix shell.
            passthru = {
             __debug = builtins.throw "if you need `passthru` in a shell, rethink your life";
            };
          }
        '';
        default = { };
      };

      checks = mkOption {
        type = types.attrsOf types.package;
        description = "derivations built and ran when `nix flake check` is invoked";
        default = { };
      };

      packages = mkOption {
        type = with types; coercedTo (functionTo (listOf package)) (o: o pkgs) (listOf package);
        default = pkgs: [ ];
        defaultText = "pkgs: []";
        example = literalExpression "(pkgs: with pkgs; [ neovim ripgrep ])";
        description = "a function that is passed the nixpkgs attr set and returns a list of packages to be passed to a devShell.";
      };

      overlays = mkOption {
        type = types.attrsOf types.raw;
        description = "overlays that will be added to the generated flake";
        example = literalExpression ''
          {
            myOverlay = final: prev: {
              pre-commit-hooks = prev.python3Packages.pre-commit-hooks.overridePythonAttrs (_: {
                dontCheck = true;
                JAVA_HOME = "''${final.jdk.home}";
              });
            };
            # Force JDK11 to be used everywhere.
            jdk = _: prev: { jdk = prev.openjdk11; };
          }
        '';
        default = { };
      };
    };
  };

in
{
  options.projectName = mkOption {
    type = types.str;
    description = "The name of the project";
    default = "template";
  };

  options.src = mkOption {
    type = types.either types.path (types.enum [ (-1) null ]);
    description = ''
      Should be set to ./.
      You may set this to `null` explicitly if you don't want the source
      directory to be copied; this prevents pre-commit-hooks from being
      installed and might be necessary in some very large repositories.
    '';
    default = -1;
  };

  options.packages = mkOption {
    type = with types; coercedTo (functionTo (listOf package)) (o: o pkgs) (listOf package);
    default = pkgs: [ ];
    defaultText = literalExpression "pkgs: []";
    example = literalExpression "(pkgs: with pkgs; [ neovim ripgrep ])";
    description = "a function that is passed the nixpkgs attr set and returns a list of packages to be passed to a devShell.";
  };

  options.apps = mkOption {
    type = types.attrsOf (types.submodule [ appSubmodule ]);
    default = { };
    example = literalExpression ''{ type = "app"; program = pkgs.hello; }'';
    description = "an attribute set of apps. Apps are programs that do not appear in the path or anywhere else and are solely used via `nix run` commands.";
  };

  options.preset = mkOption {
    type = types.attrsOf (types.submodule [ presetSubmodule ]);
    default = { };
    description = ''
      Presets are a composable unit of abstraction that represents a fragment
      of options that make up a development environment.
      Presets are not intended to map 1:1 to any specific project; they are
      intended to be composed and require very little overriding or
      customization (if any).
      They will be glued together along with the global configuration in order
      to form the final flake and dev shell environment.
    '';
  };

  options.generated = mkOption {
    type = types.raw;
    internal = true;
    default = { };
  };

  options.mergedPresets = mkOption rec {
    type = types.submodule presetSubmodule;
    internal = true;
    # What cursed magic is this? Let us explain...
    # Actually, there is too much, let us summarize.
    # Hmm... Okay, tl;dr it is
    #
    # "apply" is used by the nixpkgs module system to automatically transform
    # one option to another It's very useful for expressing that one option is
    # derived automatically from another. In this case, mergedPresets is the
    # result of merging of all of the presets together. Consequently, we use
    # this to express that rather than burying this in the config somewhere.
    # Both options work fine, but this makes it a little cleaner.
    apply = presets:
      let
        # haha_sicko.jpg
        merged = (lib.evalModules {
          modules = type.getSubModules ++ (builtins.attrValues (lib.enabledPresets cfg));
        }).config;

        shellPkgs = cfg.packages ++ merged.packages ++ (merged.shellArgs.nativeBuildInputs or [ ]);
        mkHooks = hook: lib.concatMapStringsSep "\n" (x: x.rendered) (builtins.attrValues merged.${hook});
      in
      lib.recursiveUpdate merged {
        shellArgs = {
          nativeBuildInputs = lib.unique shellPkgs;
          shellHook = mkHooks "shellHooks";
        };

        packages =
          let
            uniquePackages = lib.unique (shellPkgs ++ (merged.shellArgs.buildInputs or [ ]));
          in
          lib.flattenTree (lib.attrsFromPkgList uniquePackages);

        overlay = lib.composeManyExtensions (builtins.attrValues merged.overlays);

        # We put "envrc" in a file so that it can be utilized in a
        # compare-and-swap manner for ergonomic (and efficient) updates inside
        # a shell hook. It's important to avoid hitting the file system as much
        # as possible when using this because doing so invalidates the direnv
        # cache which can be costly. The default shell hook in base takes care
        # of doing so and makes sure it's compatilbe with file-watching
        # daemons.
        envrc = builtins.toFile "envrc" (mkHooks "direnvHooks");

        apps = cfg.apps;
      };
    default = { };
  };

  config = {
    assertions = [
      {
        assertion = config.src != -1;
        message = ''
          Warning: src is expected to be set.
          If this was intentional (e.g., because you don't want precommit hooks or the
          directory tree is very large), please set src to null explicitly
        '';
      }
    ];

    # This configuration output mostly exists to merge up all of the
    # individual module settings into a global configuration.
    # eg given preset.a.packages = [a]; and preset.b.packages = [b];
    # this collects those into generated.packages = [a b];
    # for easier consumption.
    # As a convenience, pkgs and legacyPackages are also injected so that they
    # can be used in mkFlake easier.
    generated = lib.recursiveUpdate config.mergedPresets {
      inherit pkgs;
      legacyPackages = pkgs // { _debug = config; };
    };
  };
}
