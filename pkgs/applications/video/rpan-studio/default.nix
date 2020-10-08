{ config, stdenv
, mkDerivation
, fetchFromGitHub
, addOpenGLRunpath
, cmake
, fdk_aac
, ffmpeg
, jansson
, libjack2
, libxkbcommon
, libpthreadstubs
, libXdmcp
, qtbase
, qtx11extras
, qtwebsockets
, qtsvg
, qtnetworkauth
, qoauth
, speex
, libv4l
, x264
, curl
, xorg
, makeWrapper
, pkgconfig
, libvlc
, mbedtls

, scriptingSupport ? true
, luajit
, swig
, python3

, alsaSupport ? stdenv.isLinux
, alsaLib
, pulseaudioSupport ? config.pulseaudio or stdenv.isLinux
, libpulseaudio
}:

let
  inherit (stdenv.lib) optional optionals;

#https://github.com/reddit/rpan-studio/archive/25.0.7.6-rpan.tar.gz

in mkDerivation rec {
  pname = "rpan-studio";
  version = "25.0.7.7";

  src = fetchTarball { url = https://github.com/reddit/rpan-studio/archive/25.0.7.7-rpan.tar.gz;
    sha256 = "0pxqnryqc2mdaz0hlh5rhg2gam9nm6n0ks2qb22nq72igjxga156";
    };

  # src = fetchFromGitHub {
  #   owner = "obsproject";
  #   repo = "obs-studio";
  #   rev = version;
  #   sha256 = "0j2k65q3wfyfxhvkl6icz4qy0s3kfqhksizy2i3ah7yml266axbj";
  # };

  nativeBuildInputs = [ addOpenGLRunpath cmake pkgconfig ];

  buildInputs = [
    curl
    fdk_aac
    ffmpeg
    jansson
    libjack2
    libv4l
    libxkbcommon
    libpthreadstubs
    libXdmcp
    qtbase
    qtx11extras
    qtsvg
    qtwebsockets
    qtnetworkauth
    qoauth
    speex
    x264
    libvlc
    makeWrapper
    mbedtls
  ]
  ++ optionals scriptingSupport [ luajit swig python3 ]
  ++ optional alsaSupport alsaLib
  ++ optional pulseaudioSupport libpulseaudio;

  # obs attempts to dlopen libobs-opengl, it fails unless we make sure
  # DL_OPENGL is an explicit path. Not sure if there's a better way
  # to handle this.
  cmakeFlags = [
    "-DCMAKE_CXX_FLAGS=-DDL_OPENGL=\\\"$(out)/lib/libobs-opengl.so\\\""
    "-DOBS_VERSION_OVERRIDE=${version}"
    "-Wno-dev" # kill dev warnings that are useless for packaging
  ];

  postInstall = ''
      mv $out/bin/obs $out/bin/rpan-studio
      wrapProgram $out/bin/rpan-studio \
        --prefix "LD_LIBRARY_PATH" : "${xorg.libX11.out}/lib:${libvlc}/lib"
  '';

  postFixup = stdenv.lib.optionalString stdenv.isLinux ''
      addOpenGLRunpath $out/lib/lib*.so
      addOpenGLRunpath $out/lib/obs-plugins/*.so
  '';

  meta = with stdenv.lib; {
    description = "Free and open source software for video recording and live streaming on RPAN";
    longDescription = ''
      This is a fork of obs intended to work with reddit's rpan streaming service.
    '';
    homepage = "https://github.com/reddit/rpan-studio";
    maintainers = with maintainers; [ ];
    license = licenses.gpl2;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
