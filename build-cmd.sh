#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

OGG_VERSION=1.2.2
OGG_SOURCE_DIR="libogg-$OGG_VERSION"
VORBIS_VERSION=1.3.2
VORBIS_SOURCE_DIR=libvorbis-$VORBIS_VERSION

# load autbuild provided shell functions and variables
eval "$("$AUTOBUILD" source_environment)"

top="$(pwd)"
stage="$(pwd)/stage"

case "$AUTOBUILD_PLATFORM" in
    windows*)
        if [ "$AUTOBUILD_PLATFORM" == "windows64" ]; then
            build_target="x64"
        else
            build_target="Win32"
        fi
        if [ "$AUTOBUILD_VSVER" -gt "100" ]; then
            proj_suffix=".vcxproj"
        else
            proj_suffix=""
        fi
        pushd "$OGG_SOURCE_DIR"

        packages="$(cygpath -m "$stage/packages")"

        build_sln "win32/ogg.sln" "Debug|$build_target" "ogg_static$proj_suffix"
        build_sln "win32/ogg.sln" "Release|$build_target" "ogg_static$proj_suffix"

        mkdir -p "$stage/lib"/{debug,release}
        cp "win32/Static_Debug/ogg_static_d.lib" "$stage/lib/debug/ogg_static_d.lib"
        cp "win32/Static_Debug/vc100.pdb" "$stage/lib/debug/ogg_static_d.pdb"
        cp "win32/Static_Release/ogg_static.lib" "$stage/lib/release/ogg_static.lib"
        cp "win32/Static_Release/vc100.pdb" "$stage/lib/release/ogg_static.pdb"

        mkdir -p "$stage/include"
        cp -a "include/ogg/" "$stage/include/"
        
        popd
        pushd "$VORBIS_SOURCE_DIR"
        
        build_sln "win32/vorbis.sln" "Debug|$build_target" "vorbis_static$proj_suffix"
        build_sln "win32/vorbis.sln" "Release|$build_target" "vorbis_static$proj_suffix"
        build_sln "win32/vorbis.sln" "Debug|$build_target" "vorbisenc_static$proj_suffix"
        build_sln "win32/vorbis.sln" "Release|$build_target" "vorbisenc_static$proj_suffix"
        build_sln "win32/vorbis.sln" "Debug|$build_target" "vorbisfile_static$proj_suffix"
        build_sln "win32/vorbis.sln" "Release|$build_target" "vorbisfile_static$proj_suffix"
        
        cp "win32/Vorbis_Static_Debug/vorbis_static_d.lib" "$stage/lib/debug/vorbis_static_d.lib"
        cp "win32/Vorbis_Static_Debug/vc100.pdb" "$stage/lib/debug/vorbis_static_d.pdb"
        cp "win32/Vorbis_Static_Release/vorbis_static.lib" "$stage/lib/release/vorbis_static.lib"
        cp "win32/Vorbis_Static_Release/vc100.pdb" "$stage/lib/release/vorbis_static.pdb"
        cp "win32/VorbisEnc_Static_Debug/vorbisenc_static_d.lib" "$stage/lib/debug/vorbisenc_static_d.lib"
        cp "win32/VorbisEnc_Static_Debug/vc100.pdb" "$stage/lib/debug/vorbisenc_static_d.pdb"
        cp "win32/VorbisEnc_Static_Release/vorbisenc_static.lib" "$stage/lib/release/vorbisenc_static.lib"
        cp "win32/VorbisEnc_Static_Release/vc100.pdb" "$stage/lib/release/vorbis_static.pdb"
        cp "win32/VorbisFile_Static_Debug/vorbisfile_static_d.lib" "$stage/lib/debug/vorbisfile_static_d.lib"
        cp "win32/VorbisFile_Static_Debug/vc100.pdb" "$stage/lib/debug/vorbis_static_d.pdb"
        cp "win32/VorbisFile_Static_Release/vorbisfile_static.lib" "$stage/lib/release/vorbisfile_static.lib"
        cp "win32/VorbisFile_Static_Release/vc100.pdb" "$stage/lib/release/vorbis_static.pdb"
        cp -a "include/vorbis/" "$stage/include/"
        popd
    ;;
    "darwin")
        pushd "$OGG_SOURCE_DIR"
        ./configure --prefix="$stage"
        make
        make install
        popd
        
        pushd "$VORBIS_SOURCE_DIR"
        ./configure --prefix="$stage"
        make
        make install
        popd
        
        mv "$stage/lib" "$stage/release"
        mkdir -p "$stage/lib"
        mv "$stage/release" "$stage/lib"
     ;;
    "linux")
        pushd "$OGG_SOURCE_DIR"
        CFLAGS="-m32" CXXFLAGS="-m32" ./configure --prefix="$stage"
        make
        make install
        popd
        
        pushd "$VORBIS_SOURCE_DIR"
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$stage/lib"
        CFLAGS="-m32" CXXFLAGS="-m32" ./configure --prefix="$stage"
        make
        make install
        popd
        
        mv "$stage/lib" "$stage/release"
        mkdir -p "$stage/lib"
        mv "$stage/release" "$stage/lib"
    ;;
esac
mkdir -p "$stage/LICENSES"
pushd "$OGG_SOURCE_DIR"
    cp COPYING "$stage/LICENSES/ogg-vorbis.txt"
popd

pass

