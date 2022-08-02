{ pkgs, lib, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  config.preset.clojure = {
    packages = pkgs: with pkgs; [ clj-kondo clojure jdk11 leiningen maven zprint ];
    pre-commit-hooks = import ./pre-commit-hooks.nix { inherit lib; inherit (pkgs) clj-kondo zprint; };

    shellHooks.clojure-auth.text = ''
      if [ -f deps.edn ]; then
        # This is a clojure cli repo
        if ! [ -f $HOME/.m2/settings.xml ]; then
          echo 1>&2 "Warning: Your m2 settings.xml file is missing"
          err=1
        fi
      fi
      if [ -f project.clj ]; then
        # This is a Leiningen repo
        if [ -f $HOME/.m2/settings.xml ]; then
          echo 1>&2 "Warning: You have an m2 settings.xml file."
          echo 1>&2 "This conflicts with how lein authenticates with registries"
          err=1
        fi
      fi
      [ "$err" ] && echo 1>&2 "authentication for clojure shouldn't work correctly"
      unset -v err
    '';

    shellHooks.z-clojure-check-env-local.text = ''
      if ! [ -f .env ]; then
        echo "Warning: .env does not exist."
        err=1
      else
        shellEnv=$(set -a ; . .env ; env)
        for var in 'CLOJURE_REGISTRY_USERNAME' 'CLOJURE_REGISTRY_PASSWORD'; do
          if ! echo "$shellEnv" | grep -q "^$var"=; then
            echo 1>&2 "Warning: neither .env or the shell environment contains $var"
            err=1
          fi
          if echo "$shellEnv" | grep -q "^''${var}=$"; then
            echo 1>&2 "Warning: $var is set, but it is empty"
            err=1
          fi
        done
      fi
      [ "$err" ] && echo 1>&2 "authentication for clojure won't work correctly"
      unset -v err
    '';

  };
}
