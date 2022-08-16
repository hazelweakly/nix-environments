# Nix

Centralized nix code

Simple example:

```nix
{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix";

  outputs = { nix-template, ... }: nix-template.lib.mkFlake {
    projectName = "example";
    src = ./.;
    packages = pkgs: [];
    preset.base = {
      enable = true;
      pre-commit-hooks = {};
      shellHooks = {};
      shellArgs = {};
      checks = {};
      overlays = {};
    };
  };
}
```

Accessing generated outputs to put into other inputs:

```nix
{
  description = "Nix environment for development";
  inputs.nix-template.url = "github:hazelweakly/nix";

  outputs = { self, nix-template, ... }: nix-template.lib.mkFlake (system:
    # This pkgs will have the result of all overlays declared below available
    # to use.
    let pkgs = self.legacyPackages.${system}; in
    {
      projectName = "example";
      src = ./.;
      packages = pkgs: [];
      preset.base = {
        enable = true;
        pre-commit-hooks = {};
        shellHooks = {};
        shellArgs = {};
        checks = {};
        overlays = {};
      };
    });
}
```

## How to Use

Inside an empty directory, run:

```sh
git init
nix flake template -t 'github:hazelweakly/nix#templates.<template>'
```

where `<template>` is one of the templates available in the nix flake.
At the time of writing, the list is `base`, `clojure`,`react`,`react-native`, `python`, and `hcl`.
If you don't specify the template, it'll default to the default template, which is the base template.

## How to Use (if you fork this and make it private)

If you want to fork this repo and make it private (in order to add custom modules to it or your own custom logic),
you'll need to consume it with a personal access token, or nix will be grumpy that you're wanting it to clone a private repo.

To consume this as a private repo, you'll need to set up a personal access token where nix can read it.

1. Make a PAT in GitHub by going [here](https://github.com/settings/tokens).

- Use the permissions `repo`.
- Set the expiration date for `90 days`.

2. Copy the PAT and save it in a password manager somewhere
3. Take the PAT and write it in `~/.config/nix/nix.conf` like so:
   ```text
   access-tokens = github.com=$token_goes_here
   ```

Test this by running the command `nix flake prefetch github:hazelweakly/nix`. It _should_ work.

## Module organization.

The flake takes two types of configuration: Global configuration and preset configurations.
The `preset` configurations are logical units of bundled defaults: often presets will be for a specific language or framework.
Presets are not intended to map 1:1 to any specific project; they are intended to be composed and require very little overriding or customization (if any).
They will be glued together along with the global configuration in order to form the final flake and dev shell environment.
Specifying presets in this way allows for defaults specific to that language, framework, or whatever else to be wired in but still overridden as needed.

### Global config

- Project name (the repo name in GitHub)
- src should point to `./.`
  - It can be set explicitly to `null` in order to avoid copying the repo into the nix store.
    Do note that nix flakes typically copy the repo into the nix store anyway so there's not much point to setting it to `null` yet.
- packages: anything else to add to the dev shell

### Preset

- `enable`: whether to enable that set of defaults
- `pre-commit-hooks`: add hooks or override provided ones
- `shellHooks`: add hooks or override provided ones. These get concatenated together to form a single `shellHook` script.
- `shellArgs`: raw arguments that are passed into the developer shell. This allows for low level overriding of defaults or adding special configuration as needed.
- `checks`: add checks or override provided ones (note: we don't currently use checks anywhere, but eventually this is what will be used to run pre-commit-hooks in CI)
- `overlays`: add or override provided overlays

The defaults are designed to be sufficient and mostly complete.

All the big scary dragons are hiding in the `./lib/modules` folder.
