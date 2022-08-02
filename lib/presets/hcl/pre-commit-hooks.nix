{ lib, terraform-format, ... }: {
  terraform-format = {
    enable = true;
    name = "terraform-format";
    description = "Lint Terraform files";
  };
}
