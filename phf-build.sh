#! /bin/bash
echo "Compiling photoflow"
(crossroad cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUNDLED_LENSFUN=ON /sources && make -j 2 && make install) || exit 1
