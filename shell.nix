{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  tf = terraform.withPlugins (p: with p; [
    external
    google
    p.null
    random
  ]);
in
mkShell {
  buildInputs = [
    tf
  ];
  shellHook = ''
  '';
}
