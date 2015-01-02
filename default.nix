let
  unsafeDerivation = args: derivation ({
    PATH = builtins.getEnv "PATH";
    system = builtins.currentSystem;
    builder = ./bootstrap/proxy-bash.sh;
    preferLocalBuild = true;
    __noChroot = true;
  } // args);

  shell = name: command: unsafeDerivation {
    inherit name;
    args = ["-c" command];
  };

  # working git must be in $PATH.
  # increase (change) `clock' to trigger updates
  shallow-fetchgit =
    {url, branch ? "master", clock ? 1}:
      shell "${baseNameOf (toString url)}-${toString clock}" ''
        git clone --depth 1 -b ${branch} --recursive ${url} $out
        cd $out
      '';

  nixpkgs = shallow-fetchgit {
    url = "git://github.com/zalora/nixpkgs.git";
    branch = "upcast";
    clock = 1;
  };
in
{ system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
, name ? "aws-ec2"
, src ? builtins.filterSource (path: type: let base = baseNameOf path; in
    type != "unknown" &&
    base != ".git" && base != "result" && base != "dist" && base != ".cabal-sandbox"
    ) ./.
, haskellPackages ? pkgs.haskellPackages_ghc783
}:
with pkgs.lib;

let
  # Build a cabal package given a local .cabal file
  buildLocalCabalWithArgs = { src
                            , name
                            , args ? {}
                            , cabalDrvArgs ? { jailbreak = true; }
                            # for import-from-derivation, want to use current system
                            , nativePkgs ? import pkgs.path {}
                            }: let

    cabalExpr = shell "${name}.nix" ''
      export HOME="$TMPDIR"
      ${let c2n = builtins.getEnv "OVERRIDE_cabal2nix";
        in if c2n != "" then c2n
           else "${nativePkgs.haskellPackages.cabal2nix}/bin/cabal2nix"} \
        ${src + "/${name}.cabal"} --sha256=FILTERME \
          | grep -v FILTERME | sed \
            -e 's/{ cabal/{ cabal, cabalInstall, cabalDrvArgs ? {}, src/' \
            -e 's/cabal.mkDerivation (self: {/cabal.mkDerivation (self: cabalDrvArgs \/\/ {/' \
            -e 's/buildDepends = \[/buildDepends = \[ cabalInstall/' \
            -e 's/pname = \([^$]*\)/pname = \1  inherit src;/'  > $out
    '';
  in haskellPackages.callPackage cabalExpr ({ inherit src cabalDrvArgs; } // args);

  aws = haskellPackages.callPackage ./aws.nix {};
in

rec {
  library = buildLocalCabalWithArgs {
    inherit src name;
    args = {
      inherit aws;
    };
  };

  put-metric = pkgs.runCommand "${name}-put-metric" {} ''
    mkdir -p $out/bin
    cp ${library}/bin/put-metric $out/bin
  '';

  create-alarm = pkgs.runCommand "${name}-create-alarm" {} ''
    mkdir -p $out/bin
    cp ${library}/bin/create-alarm $out/bin
  '';
}
