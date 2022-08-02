{ inputs, self, lib }:
let
  inherit (lib) nameValuePair filterAttrs forallSystemsMap getName mkFlake test-utils;
  inherit (builtins) map mapAttrs;

  templates = filterAttrs (n: _: n != "default") self.templates;

  flakeConfigs = mapAttrs
    (name: template: {
      projectName = name;
      src = template.path;
      preset.${name}.enable = true;
    })
    templates;

  rawConfigs = forallSystemsMap (system: mapAttrs (_: config: lib.mkRawConfig { inherit config system; }) flakeConfigs);

  flakes = mapAttrs (name: _: mkFlake flakeConfigs.${name}) templates;

  goldenValues = system:
    let jdk =
      if system == "x86_64-linux" then "openjdk" else "zulu11.48.21-ca-jdk"; in
    {
      nativeBuildInputs = {
        base = [ "just" "repl" "1password-cli" "mkcert" "mdbook" "pre-commit-hooks" ];
        clojure = [ "clj-kondo" "clojure" "leiningen" "zprint" jdk ];
        hcl = [ ];
        python = [ "isort" "black" "vulture" "mypy" "flake8" ];
        react = [ "nodejs" "yarn" ];
        react-native = [ "android-sdk-env" "gradle" jdk ];
      };
    };

  # Tests that nativeBuildInputs in the default devShells are what's expected.
  buildInputTests = system:
    let
      rawConfig = rawConfigs.${system};
      enabled = name: builtins.attrNames (lib.enabledPresets rawConfig.${name});

      given = f: lib.naturalSort (map getName (f.devShells.${system}.default.nativeBuildInputs));
      expected = name: lib.naturalSort (lib.concatMap (n: (goldenValues system).nativeBuildInputs.${n}) (enabled name));

      test = n: v: test-utils.${system}.isEqual (given v) (expected n);
    in
    (lib.mapAttrs' (n: v: nameValuePair "shell/${n}" (test n v)) flakes);

in

forallSystemsMap (system: (buildInputTests system))
