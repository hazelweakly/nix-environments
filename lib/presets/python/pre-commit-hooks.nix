{ black, isort, flake8, vulture, lib, mypy }: {
  black.enable = true;
  black.entry = lib.mkForce "${black}/bin/black";
  black.raw.require_serial = true;
  black.types = [ "file" "python" ];

  isort.enable = true;
  isort.entry = lib.mkForce "${isort}/bin/isort";
  isort.types = [ "file" "python" ];

  flake8.enable = true;
  flake8.entry = lib.mkDefault "${flake8}/bin/flake8";
  flake8.types = [ "file" "python" ];

  vulture.enable = true;
  vulture.entry = lib.mkDefault "${vulture}/bin/vulture";
  vulture.pass_filenames = false;
  vulture.types = [ "file" "python" ];

  mypy.enable = true;
  mypy.description = "Check type annotations in Python code.";
  mypy.entry = lib.mkDefault "${mypy}/bin/mypy";
  mypy.types = [ "file" "python" ];
  mypy.raw.require_serial = true;
}
