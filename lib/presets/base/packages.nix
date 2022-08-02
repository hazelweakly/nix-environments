{ pkgs, lib, config, ... }: {
  inherit (pkgs)
    # https://just.systems/man
    just

    # repl lets you run `nix run .#repl .` to be  put into a fully interactive
    # nix repl that loads the current flake.nix as well as other convenience
    # helpers
    repl

    # https://developer.1password.com/docs/cli/reference
    _1password

    # https://github.com/FiloSottile/mkcert
    mkcert

    # https://rust-lang.github.io/mdBook
    mdbook

    # a modern bash version
    bashInteractive

    # a sane fucking version of sed
    gnused
    ;
}
