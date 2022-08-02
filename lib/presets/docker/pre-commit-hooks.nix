{ lib, hadolint, ... }: {
  hadolint = {
    enable = true;
    name = "hadolint";
    entry = "${hadolint}/bin/hadolint";
    description = "Lint Dockerfiles";
    types = [ "file" "dockerfile" ];
  };
}
