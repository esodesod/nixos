{ stdenv, kernel, lib, fetchFromGitHub, buildPackages }:

stdenv.mkDerivation rec {
  pname = "macbook12-spi-driver";
  version = "0.1";

  src = fetchFromGitHub {
    # owner = "roadrunner2";
    # rev = "master";
    # sha256 = "NLTI8xhOcEeLP4f4tstXBWLSz9CpeRY0zm2K6hjyDBI=";
    # owner = "marc-git";
    # repo = "macbook12-spi-driver";
    # rev = "touchbar-driver-hid-driver";
    # sha256 = "MRB4GgBh4qvzrq8sdGpNhSJ3/rVUQcS+kKLkT6QBhV0=";
    owner = "almas";
    repo = "macbook12-spi-driver";
    rev = "touchbar-driver-hid-driver";
    sha256 = "3sDnjMSDMAmd93C5CLhRKvX8ldrCfPNu1jE5zGKvcaQ=";
  };

  # Add patches attribute with a list including your patch file
  patches = [ 
    # ./fix-marc-git.patch
    ./fix-almas.patch
  ];

  # nativeBuildInputs = [ buildPackages.kernel.dev ];
  nativeBuildInputs = [ kernel.dev ];

  buildPhase = ''
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    '';

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    for m in applespi.ko apple-ibridge.ko apple-ib-tb.ko apple-ib-als.ko; do
    if [ -e $m ]; then cp $m $out/lib/modules/${kernel.modDirVersion}/extra/; fi
    done
    '';

  meta = {
    description = "SPI keyboard/touchpad/touchbar driver for newer MacBooks";
    # license = stdenv.lib.licenses.gpl2;
    license = lib.licenses.gpl2; # <-- Use `lib.licenses.gpl2`
    platforms = kernel.meta.platforms;
  };
}
