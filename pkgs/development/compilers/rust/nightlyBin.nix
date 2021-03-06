{ stdenv, fetchurl, makeWrapper, cacert, zlib, buildRustPackage, curl }:

let
  inherit (stdenv.lib) optionalString;

  platform = if stdenv.system == "x86_64-linux"
    then "x86_64-unknown-linux-gnu"
    else throw "missing bootstrap url for platform ${stdenv.system}";

  bootstrapHash =
    if stdenv.system == "x86_64-linux"
    then "1d5h34dkm1r1ff562szygn9xk2qll1pjryvypl0lazzanxdh5gv5"
    else throw "missing bootstrap hash for platform ${stdenv.system}";

  needsPatchelf = stdenv.isLinux;

  src = fetchurl {
     url = "https://static.rust-lang.org/dist/${version}/rust-nightly-${platform}.tar.gz";
     sha256 = bootstrapHash;
  };

  version = "2017-03-16";
in

rec {
  inherit buildRustPackage;

  rustc = stdenv.mkDerivation rec {
    name = "rustc-nightly-${version}";

    inherit version;
    inherit src;

    meta = with stdenv.lib; {
      homepage = http://www.rust-lang.org/;
      description = "A safe, concurrent, practical language";
      maintainers = with maintainers; [ qknight ];
      license = [ licenses.mit licenses.asl20 ];
    };

    buildInputs = [ makeWrapper ];
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      ./install.sh --prefix=$out \
        --components=rustc,rust-std-x86_64-unknown-linux-gnu

      ${optionalString needsPatchelf ''
        patchelf \
          --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          "$out/bin/rustc"
        patchelf \
          --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          "$out/bin/rustdoc"
      ''}
    '';

  };
  cargo = stdenv.mkDerivation rec {
    name = "cargo-nightly-${version}";

    inherit version;
    inherit src;

    meta = with stdenv.lib; {
      homepage = http://www.rust-lang.org/;
      description = "A safe, concurrent, practical language";
      maintainers = with maintainers; [ qknight ];
      license = [ licenses.mit licenses.asl20 ];
    };

    buildInputs = [ makeWrapper curl ];
    phases = ["unpackPhase" "installPhase"];

    installPhase = ''
      ./install.sh --prefix=$out \
        --components=cargo

      ${optionalString needsPatchelf ''
        patchelf \
          --set-rpath "${stdenv.lib.makeLibraryPath [ curl zlib ]}" \
          --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          "$out/bin/cargo"
      ''}
    '';
  };
}
