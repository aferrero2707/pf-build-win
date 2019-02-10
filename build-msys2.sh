#! /bin/bash
sudo pacman --noconfirm -S wget || exit 1
(sudo mkdir -p /work && sudo chmod a+w /work) || exit 1

cd /work || exit 1

(rm -f pacman-msys.conf && wget https://raw.githubusercontent.com/aferrero2707/docker-buildenv-mingw/master/pacman-msys.conf && sudo cp pacman-msys.conf /etc/pacman-msys.conf) || exit 1
(rm -f Toolchain-mingw-w64-x86_64.cmake && wget https://raw.githubusercontent.com/aferrero2707/docker-buildenv-mingw/master/Toolchain-mingw-w64-x86_64.cmake && sudo cp Toolchain-mingw-w64-x86_64.cmake /etc/Toolchain-mingw-w64-x86_64.cmake) || exit 1

for PKG in mingw-w64-x86_64-libjpeg-turbo-1.5.3-1-any.pkg.tar.xz mingw-w64-x86_64-lensfun-0.3.2-4-any.pkg.tar.xz mingw-w64-x86_64-gtk3-3.22.30-1-any.pkg.tar.xz mingw-w64-x86_64-gtkmm3-3.22.3-1-any.pkg.tar.xz; do
	if [ -e "$PKG" ]; then continue; fi
	wget http://repo.msys2.org/mingw/x86_64/"$PKG" || exit 1
	sudo pacman --noconfirm --config /etc/pacman-msys.conf -U "$PKG" || exit 1
done


sudo pacman --noconfirm --config /etc/pacman-msys.conf -S \
mingw64/mingw-w64-x86_64-fftw mingw64/mingw-w64-x86_64-libtiff mingw64/mingw-w64-x86_64-lcms2 \
mingw64/mingw-w64-x86_64-pugixml mingw64/mingw-w64-x86_64-libexif \
mingw64/mingw-w64-x86_64-gtkmm mingw64/mingw-w64-x86_64-iconv \
mingw64/mingw-w64-x86_64-expat mingw64/mingw-w64-x86_64-openexr \
mingw64/mingw-w64-x86_64-pugixml mingw-w64-x86_64-opencolorio-git || exit 1

(cd / && sudo rm -f mingw64 && sudo ln -s /msys2/mingw64 /mingw64) || exit 1
export PKG_CONFIG=/usr/sbin/x86_64-w64-mingw32-pkg-config
export PKG_CONFIG_PATH=/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH
export PKG_CONFIG_PATH_CUSTOM=/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH

mkdir -p /work/w64-build/phf || exit 1
cd /work/w64-build/phf || exit 1


if [ ! -e vips-8.6.5 ]; then
wget https://github.com/libvips/libvips/releases/download/v8.6.5/vips-8.6.5.tar.gz || exit 1
rm -rf vips-8.6.5
tar xzf vips-8.6.5.tar.gz || exit 1
cd vips-8.6.5 || exit 1
./configure --host=x86_64-w64-mingw32 --prefix=/msys2/mingw64 --with-expat=/mingw64 || exit 1
(make && sudo make install) || exit 1
fi


if [ "x" = "y" ]; then
cd /work/w64-build/phf || exit 1
if [ ! -e OpenColorIO-1.1.0 ]; then
wget https://github.com/imageworks/OpenColorIO/archive/v1.1.0.tar.gz || exit 1
tar xzf v1.1.0.tar.gz || exit 1
cd OpenColorIO-1.1.0 || exit 1
mkdir -p build || exit 1
cd build || exit 1
(cmake \
 -DCMAKE_TOOLCHAIN_FILE=/etc/Toolchain-mingw-w64-x86_64.cmake \
 -DPKG_CONFIG_EXECUTABLE=/usr/sbin/x86_64-w64-mingw32-pkg-config \
 -DCMAKE_C_FLAGS="-mwin32 -m64 -mthreads -msse2 -Wno-unused-function -Wno-deprecated-declarations" \
 -DCMAKE_C_FLAGS_RELEASE="-DNDEBUG -O2 -Wno-unused-function -Wno-deprecated-declarations" \
 -DCMAKE_CXX_FLAGS="-mwin32 -m64 -mthreads -msse2 -Wno-unused-function -Wno-deprecated-declarations" \
 -DCMAKE_CXX_FLAGS_RELEASE="-Wno-aggressive-loop-optimizations -DNDEBUG -O3 -Wno-unused-function -Wno-deprecated-declarations" \
 -DCMAKE_EXE_LINKER_FLAGS="-m64 -mthreads -static-libgcc" \
 -DCMAKE_EXE_LINKER_FLAGS_RELEASE="-s -O3" \
 -DCMAKE_INSTALL_PREFIX=/mingw64 \
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/msys2/mingw64 \
 -DOCIO_BUILD_APPS=OFF -DOCIO_BUILD_NUKE=OFF \
 -DOCIO_BUILD_DOCS=OFF -DOCIO_BUILD_TESTS=OFF -DOCIO_BUILD_GPU_TESTS=OFF \
 -DOCIO_BUILD_PYTHON=OFF -DOCIO_BUILD_JAVA=OFF .. && \
 make VERBOSE=1 -j 1 install) || exit 1
fi
fi


cd /work/w64-build/phf || exit 1
rm -f CMakeCache.txt
echo "TRAVIS_USE_GTKMM3: ${TRAVIS_USE_GTKMM3}"
export TRAVIS_USE_GTKMM3=${TRAVIS_USE_GTKMM3:-OFF}
echo "Compiling photoflow with USE_GTKMM3=${TRAVIS_USE_GTKMM3}"
(cmake \
 -DCMAKE_TOOLCHAIN_FILE=/etc/Toolchain-mingw-w64-x86_64.cmake \
 -DPKG_CONFIG_EXECUTABLE=/usr/sbin/x86_64-w64-mingw32-pkg-config \
 -DCMAKE_C_FLAGS="'-mwin32 -m64 -mthreads -msse2'" \
 -DCMAKE_C_FLAGS_RELEASE="'-DNDEBUG -O2'" \
 -DCMAKE_CXX_FLAGS="'-mwin32 -m64 -mthreads -msse2'" \
 -DCMAKE_CXX_FLAGS_RELEASE="'-Wno-aggressive-loop-optimizations -DNDEBUG -O3'" \
 -DCMAKE_EXE_LINKER_FLAGS="'-m64 -mthreads -static-libgcc'" \
 -DCMAKE_EXE_LINKER_FLAGS_RELEASE="'-s -O3'" \
 -DPugixml_INCLUDE_DIR="/msys2/mingw64/include/pugixml-1.9" \
 -DCMAKE_INSTALL_PREFIX=/mingw64 \
 -DCMAKE_BUILD_TYPE=Release -DBUNDLED_LENSFUN=OFF -DBUNDLED_LENSFUN_DB=ON \
 -DUSE_GTKMM3=${TRAVIS_USE_GTKMM3} /sources && \
 make -j 1 && sudo make install) || exit 1
