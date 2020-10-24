#! /usr/bin/env bash
set -euo pipefail

# Args
config=$1
config_pwd=$2
shift 2

# Building the command
command=(nix-instantiate --show-trace --expr '
  { system, configuration, ... }:
  let
    os = import <nixpkgs/nixos> { inherit system configuration; };
    inherit (import <nixpkgs/lib>) concatStringsSep;
  in {
    substituters = concatStringsSep " " os.config.nix.binaryCaches;
    trusted-public-keys = concatStringsSep " " os.config.nix.binaryCachePublicKeys;
    drv_path = os.system.drvPath;
    out_path = os.system;
    inherit (builtins) currentSystem;
  }')

if [[ -f "$config" ]]; then
  config=$(readlink -f "$config")
  command+=(--argstr configuration "$config")
else
  command+=(--arg configuration "$config")
fi

# add all extra CLI args as extra build arguments
command+=("$@")

# Changing directory
cd "$(readlink -f "$config_pwd")"

# Instantiate
echo "running (instantiating): ${command[*]@Q}" -A out_path >&2
"${command[@]}" -A out_path >/dev/null

# Evaluate some more details,
# relying on preceding "Instantiate" command to perform the instantiation,
# because `--eval` is required but doesn't instantiate for some reason.
echo "running (evaluating): ${command[*]@Q}" --eval --strict --json >&2
"${command[@]}" --eval --strict --json
