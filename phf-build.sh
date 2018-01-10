#! /bin/bash
echo "TRAVIS_USE_GTKMM3: ${TRAVIS_USE_GTKMM3}"
export TRAVIS_USE_GTKMM3=${TRAVIS_USE_GTKMM3:-OFF}
echo "Compiling photoflow with USE_GTKMM3=${TRAVIS_USE_GTKMM3}"
(crossroad cmake -DCMAKE_BUILD_TYPE=Release -DBUNDLED_LENSFUN=OFF -DUSE_GTKMM3=${TRAVIS_USE_GTKMM3} /sources && make -j 2 && make install) || exit 1
