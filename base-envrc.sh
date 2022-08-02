# shellcheck shell=sh

# This is a bit tricky because we install this file with nix but it checks to
# make sure nix is working...
# Really, most of these checks are going to assume you successfully
# bootstrapped _once_ and then check to make sure your environment didn't drift
# in an odd way.
if ! command -v nix >/dev/null; then
  echo >&2 "Error: Nix does not appear to be installed"
  exit 1
fi

# We need at least this version of direnv to use source_url
direnv_version 2.23.0 || {
  echo >&2 "Please upgrade direnv to continue"
  exit 1
}

# Grab the latest version of nix-direnv if it's not already being used
# This lets direnv efficiently cache and utilize nix
if ! has nix_direnv_version || ! nix_direnv_version 2.1.1 2>/dev/null; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.1.1/direnvrc" "sha256-b6qJ4r34rbE23yWjMqbmu3ia2z4b2wIlZUksBke/ol0="
fi

# Store direnv results outside of the project directory
# This improves caching when there are multiple branches
# and means you don't have to gitignore .direnv
# This function differs from the one in the docs for nix-direnv because it
# needs to work with bash v3.22 (thx macOS)
direnv_layout_dir() {
  : "${XDG_CACHE_HOME:=$HOME/.cache}"
  pwd_hash=$(basename "$PWD")-$(printf '%s' "$PWD" | shasum | cut -d ' ' -f 1 | head -c 7)
  layout_dir="$XDG_CACHE_HOME/direnv/layouts/$pwd_hash"
  mkdir -p "$layout_dir"
  echo "$layout_dir"
  unset -v pwd_hash layout_dir
}

use flake
