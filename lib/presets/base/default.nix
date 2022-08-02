{ pkgs, config, lib, inputs, ... }:
let cfg = config.preset.base; in
{
  config.packages = pkgs: [ pkgs.pre-commit-hooks ];
  config.apps = {
    # What this does is creates a "checks" package that contains only
    # the system specific checks.
    # This allows you to do `nix run .#checks` and get the same
    # experience as `nix flake check` but without it breaking on IFD or
    # multi-platform issues
    #
    # This is a bit of a workaround for some warts, but it also lets us
    # get the pre-commit-hooks runnable in CI without having to do any
    # odd workarounds or remember what commands to run
    #
    # How this `runCommandLocal` is working is it strictly evaluates the
    # config.generated.checks and then echos that result out to standard-out.
    # runCommandLocal forces this to never be cached so it's recomputed every
    # time. This essentially works as "eval this nix expression on-demand every
    # time" which has the semantics we want.
    # (we _don't_ want to try and generate a shell script here, cause that's
    # annoying and the generated shell script will change every time we modify
    # a check somewhere)
    check.program = pkgs.runCommandLocal "check" { checkzDis = builtins.attrValues config.generated.checks; } ''
      echo "$checkzDis"
      mkdir -p $out/bin
      {
        echo '#!${pkgs.runtimeShell}'
        echo 'true'
      } >> $out/bin/check
      chmod +x $out/bin/check
    '';

    # This, on the other hand, is a plain shell script with a completely
    # hardcoded value. It makes sense to be a shell script because `nix run
    # .#_dump_path` is a very convenient way to access one off utilities like
    # this and nix run needs something to execute.
    dump_path.program = pkgs.writeShellScriptBin "dump_path" ''
      echo "${lib.makeBinPath (builtins.attrValues config.generated.packages)}"
    '';
  };

  config.preset.base =
    let
      sourceEnv = f: ''
        if [[ -f ${f} ]]; then
          echo 1>&2 'sourcing env variables from ${f}'
          set -a
          . ${f}
          set +a
        fi
      '';
      watchFile = f: ''
        if [[ -f ${f} ]]; then
          echo 1>&2 'watching ${f} to reload nix shell if it changes'
          nix_direnv_watch_file ${f}
        fi
      '';
    in
    {
      overlays = import ./overlays.nix { inherit inputs; };
      packages = pkgs: builtins.attrValues (import ./packages.nix { inherit pkgs lib config; });
      shellHooks.just.text = "[[ -f justfile  ]] && command -v just >/dev/null 2>&1 && just";

      shellHooks.source-env.text = sourceEnv ".env";
      shellHooks.source-env-local.text = sourceEnv ".env.local";

      shellHooks.envrc.text = lib.presetUtils.casFile ".envrc" config.generated.envrc;
      shellHooks.pre-commit-hooks.text = lib.mkIf (cfg.shellHooks.pre-commit-hooks.enable) cfg.checks.pre-commit-check.shellHook;
      shellHooks.pre-commit-hooks.enable = config.src != null;
      shellHooks.welcome.text = ''echo "Welcome to ${config.projectName}!"'';

      direnvHooks.base.text = builtins.readFile ../../../base-envrc.sh;
      direnvHooks.watch-env.text = watchFile ".env";
      direnvHooks.watch-env-local.text = watchFile ".env.local";

      pre-commit-hooks = import ./pre-commit-hooks.nix { inherit lib; inherit (pkgs) pre-commit-hooks; };

      checks = {
        pre-commit-check = lib.mkIf (config.src != null) (inputs.pre-commit-hooks.lib.${pkgs.system}.run {
          src = config.src;
          hooks = config.generated.pre-commit-hooks;
        });
      };
    };
}
