{ pre-commit-hooks, lib }: {
  nixpkgs-fmt.enable = true;
  nix-linter.enable = true;
  prettier.enable = true;
  shellcheck.enable = true;
  shellcheck.types_or = lib.mkForce [ ];

  end-of-file-fixer = {
    enable = true;
    description = "Ensure files are empty or end with one newline";
    entry = lib.mkDefault "${pre-commit-hooks}/bin/end-of-file-fixer";
    types = [ "text" ];
  };

  check-yaml = {
    enable = true;
    description = "Check YAML files for parseable syntax";
    entry = lib.mkDefault "${pre-commit-hooks}/bin/check-yaml";
    types = [ "yaml" ];
  };


  trailing-whitespace = {
    enable = true;
    entry = lib.mkDefault "${pre-commit-hooks}/bin/trailing-whitespace-fixer";
    types = [ "text" ];
    raw.stages = [ "commit" "push" "manual" ];
  };
}
