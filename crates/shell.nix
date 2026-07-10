{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.elan
    pkgs.lean4
  ];
  shellHook = ''
    echo "Hermetic MOC Lawful Core Environment Initialized."
  '';
}
