{ config, lib, ... }: {
  config.preset.base.enable = lib.mkDefault true;
  config.preset.react = {
    packages = pkgs: with pkgs; [ nodejs-16_x yarn ];
    shellHooks.npmrc.text =
      let
        npmrc = builtins.toFile "npmrc" ''
          registry=https://private-npm-registry.com/
          //private-npm-registry.com/:_authToken=''${NPM_AUTH}
          email=''${NPM_EMAIL}
          always-auth=true
          _auth=''${NPM_AUTH}
        '';
      in
      lib.presetUtils.writeFile ".npmrc" npmrc;

    shellHooks.z-react-check-env-local.text = ''
      if ! [ -f .env.local ]; then
        echo "Warning: .env.local does not exist."
        err=1
      else
        shellEnv=$(set -a ; . .env.local ; env)
        for var in 'NPM_EMAIL' 'NPM_AUTH'; do
          if ! echo "$shellEnv" | grep -q "^$var"=; then
            echo 1>&2 "Warning: neither .env.local or the shell environment contains $var"
            err=1
          fi
          if echo "$shellEnv" | grep -q "^''${var}=$"; then
            echo 1>&2 "Warning: $var is set, but it is empty"
            err=1
          fi
        done
      fi
      [ "$err" ] && echo 1>&2 "private registry authentication for npm won't work correctly"
      unset -v err
    '';
  };
}
