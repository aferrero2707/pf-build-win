#!/bin/bash

# transfer.sh
transfer() 
{ 
	if [ $# -eq 0 ]; then 
		echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; 		
		return 1; 
	fi
	tmpfile=$( mktemp -t transferXXX ); 
	if tty -s; then 
		basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); 
		curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; 
	else 
		curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; 
	fi; 
	cat $tmpfile; 
	rm -f $tmpfile; 
}

/usr/bin/x86_64-w64-mingw32-gcc -v

# unzip to here
export installdir=/mingw64

bash $TRAVIS_BUILD_DIR/windows/build-msys2.sh || exit 1

photoflow_package=photoflow
TARGET_SYS="w64"
if [ x"$TRAVIS_USE_GTKMM3" = "xON" ]; then
	TARGET_SYS="w64-gtk3"
fi
photoflow_version="${TARGET_SYS}-$(date +%Y%m%d)_$(date +%H%M)-git-${TRAVIS_BRANCH}-${TRAVIS_COMMIT}"
TRAVIS_USE_GTKMM3=${TRAVIS_USE_GTKMM3:-OFF}
#photoflow_version=0.2.7
#photoflow_version=$(cat checkout/PhotoFlow/VERSION | head -n 1)

# stuff is in here
basedir=`pwd`
 
# download zips to here
packagedir=packages

if [ ! -e $installdir/bin/photoflow.exe ]; then
	exit 1
fi

# jhbuild will download sources to here 
#checkoutdir=source

mingw_prefix=x86_64-w64-mingw32-

repackagedir=/work/$photoflow_package-$photoflow_version

echo "cp -a $installdir/PhotoFlow/src/rt/rtengine/camconst.json $installdir/bin/camconst.json"
cp -a $installdir/PhotoFlow/src/rt/rtengine/camconst.json $installdir/bin/camconst.json

echo "cp -a $installdir/share/photoflow/gmic_def.gmic $installdir/bin/gmic_def.gmic"
cp -a $installdir/share/photoflow/gmic_def.gmic $installdir/bin/gmic_def.gmic

#cp theme-gimp-dark/gtkrc $installdir/share/photoflow/themes/photoflow-dark.gtkrc
#cp -a theme-gimp-dark/ui $installdir/share/photoflow/themes

#mkdir -p $installdir/share/photoflow/gmic
#cp gmic_film_cluts.gmz $installdir/share/photoflow/gmic
#ls -l gdb.exe
#cp -a gdb.exe $installdir/bin
#read dummy

echo "Contents of \"$installdir/bin\":"
ls -l $installdir/bin
echo "================="; echo ""

echo "copying install area \"$installdir\""

rm -rf $repackagedir
mkdir -p $repackagedir
cp -a $installdir/bin $repackagedir || exit 1
cp -a $installdir/lib $repackagedir || exit 1
cp -a $installdir/share $repackagedir || exit 1
cp -L $installdir/lib/*.dll $repackagedir/bin
echo "================="; echo ""

echo "Contents of \"$repackagedir\":"
ls -l $repackagedir
echo "================="; echo ""
echo "Contents of \"$repackagedir/bin\":"
ls -l $repackagedir/bin
echo "================="; echo ""

echo "cleaning build \"$repackagedir\""

if [ ! -e $repackagedir/bin ]; then echo "$repackagedir/bin not found."; exit; fi
if [ ! -e $repackagedir/lib ]; then echo "$repackagedir/lib not found."; exit; fi

(cd $repackagedir/bin; wget ftp://ftp.equation.com/gdb/64/gdb.exe)

echo "Before cleaning $repackagedir/bin"
pwd
#read dummy

( cd $repackagedir/bin ; echo "$repackagedir/bin before cleaning:"; ls $repackagedir/bin; mkdir poop ; mv *photoflow* pfbatch.exe gdb.exe phf_stack.exe gdk-pixbuf-query-loaders.exe update-mime-database.exe camconst.json gmic_def.gmic poop ; mv *.dll poop ; rm -f * ; mv poop/* . ; rmdir poop )

( cd $repackagedir/bin ; rm -f libvipsCC-15.dll run-nip2.sh *-vc100-*.dll *-vc80-*.dll *-vc90-*.dll  )

#( cd $repackagedir/bin ; strip --strip-unneeded *.exe )

# for some reason we can't strip zlib1
( cd $repackagedir/bin ; mkdir poop ; mv zlib1.dll poop ; strip --strip-unneeded *.dll ; mv poop/zlib1.dll . ; rmdir poop )


( cd $repackagedir/share ; rm -rf aclocal applications doc glib-2.0 gtk-2.0 gtk-doc ImageMagick-* info jhbuild man mime pixmaps xml goffice locale icons)

( cd $repackagedir ; rm -rf include )

# we need some lib stuff at runtime for goffice and the theme
( cd $repackagedir/lib ; mkdir ../poop ; mv goffice gtk-2.0 gdk-pixbuf-2.0 ../poop ; rm -rf * ; mv ../poop/* . ; rmdir ../poop )

# we don't need a lot of it though
( cd $repackagedir/lib/gtk-2.0 ; find . -name "*.la" -exec rm {} \; )
( cd $repackagedir/lib/gtk-2.0 ; find . -name "*.a" -exec rm {} \; )
( cd $repackagedir/lib/gtk-2.0 ; find . -name "*.h" -exec rm {} \; )

( cd $repackagedir ; rm -rf make )

( cd $repackagedir ; rm -rf man )

( cd $repackagedir ; rm -rf manifest )

( cd $repackagedir ; rm -rf src )
echo "================="; echo ""

# we need to copy the C++ runtime dlls in there
gccmingwlibdir=/usr/lib/gcc/x86_64-w64-mingw32
mingwlibdir=/usr/x86_64-w64-mingw32/lib
cp -L $gccmingwlibdir/*/*.dll $repackagedir/bin
cp -L $mingwlibdir/*.dll $repackagedir/bin

# turn on the theme
mkdir -p $repackagedir/etc/gtk-2.0 || exit 1
cat > $repackagedir/etc/gtk-2.0/gtkrc <<EOF
gtk-theme-name = "Clearlooks"
EOF

sudo pacman --noconfirm -S wine || exit 1
#wine $installdir/bin/gdk-pixbuf-query-loaders.exe | sed -e "s%^\"lib%..\\\\\\\lib%g" > $repackagedir/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache || exit 1
wine $installdir/bin/gdk-pixbuf-query-loaders.exe > $repackagedir/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache || exit 1
cat $repackagedir/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

#exit

rm -rf $repackagedir/share/mime
cp -a /usr/share/mime $repackagedir/share/mime
rm $repackagedir/share/mime/application/vnd.ms-*

mkdir -p $repackagedir/share/glib-2.0/schemas
cp -a $installdir/share/glib-2.0/schemas/gschemas.compiled $repackagedir/share/glib-2.0/schemas

sudo pacman --noconfirm -S lensfun || exit 1
sudo lensfun-update-data
mkdir -p $repackagedir/share/photoflow/lensfun/version_1
cp -a /var/lib/lensfun-updates/version_1/* $repackagedir/share/photoflow/lensfun/version_1

(cd /work && rm -rf hicolor-icon-theme-0.* && \
wget http://icon-theme.freedesktop.org/releases/hicolor-icon-theme-0.17.tar.xz && \
tar xJf hicolor-icon-theme-0.17.tar.xz && cd hicolor-icon-theme-0.17 && \
./configure --prefix=$repackagedir && make install && rm -rf hicolor-icon-theme-0.*) || exit 1
echo "icons after hicolor installation:"
ls $repackagedir/share/icons
echo ""

(cd /work && rm -rf adwaita-icon-theme-3.* && \
wget http://ftp.gnome.org/pub/gnome/sources/adwaita-icon-theme/3.26/adwaita-icon-theme-3.26.0.tar.xz && \
tar xJf adwaita-icon-theme-3.26.0.tar.xz && cd adwaita-icon-theme-3.26.0 && \
./configure --prefix=$repackagedir && make install && rm -rf adwaita-icon-theme-3.26.0*) || exit 1
echo "icons after adwaita installation:"
ls $repackagedir/share/icons
echo ""

#exit

#echo creating $photoflow_package-$photoflow_version.zip
#rm -f $photoflow_package-$photoflow_version.zip
#zip -r -qq $photoflow_package-$photoflow_version.zip $photoflow_package-$photoflow_version

sudo pacman --noconfirm -S zip || exit 1

rm -f $TRAVIS_BUILD_DIR/$photoflow_package-$photoflow_version.zip
cd $repackagedir/../
sudo zip -q -r $TRAVIS_BUILD_DIR/$photoflow_package-$photoflow_version.zip $photoflow_package-$photoflow_version
#transfer $TRAVIS_BUILD_DIR/$photoflow_package-$photoflow_version.zip

ls -lh $TRAVIS_BUILD_DIR/$photoflow_package-$photoflow_version.zip

exit 0

# have to make in a subdir to make sure makensis does not grab other stuff
echo building installer nsis/$photoflow_package-$photoflow_version-setup.exe
( cd nsis ; rm -rf $photoflow_package-$photoflow_version ; 
#unzip -qq -o ../$photoflow_package-$photoflow_version.zip ;
rm -rf $photoflow_package-$photoflow_version
mv ../$photoflow_package-$photoflow_version .
#makensis -DVERSION=$photoflow_version $photoflow_package.nsi > makensis.log 
)
cd nsis
rm -f $photoflow_package-$photoflow_version.zip
zip -r $photoflow_package-$photoflow_version.zip $photoflow_package-$photoflow_version
rm -rf $photoflow_package-$photoflow_version
rm -f $photoflow_package-$photoflow_version-setup.zip
#zip $photoflow_package-$photoflow_version-setup.zip $photoflow_package-$photoflow_version-setup.exe
