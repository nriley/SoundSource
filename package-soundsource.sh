#!/bin/zsh -e

set -x -v

PACKAGEDIR="$PWD"
PRODUCT="soundsource"

find . -name \*~ -exec rm '{}' \;
rm -rf build/
xcodebuild -target $PRODUCT -configuration Release DSTROOT=/ INSTALL_PATH="$PWD" install
SetFile -c 'ttxt' -t 'TEXT' README.md

sudo /usr/bin/install -d /usr/local/bin /usr/local/man/man1
sudo /usr/bin/install $PRODUCT /usr/local/bin
#sudo /usr/bin/install -m 644 $PRODUCT.1 /usr/local/man/man1
chmod 755 $PRODUCT
#chmod 644 $PRODUCT.1
# man page is currently not usable, so don't install it
VERSION=$(agvtool vers -terse) TARBALL="$PWD/$PRODUCT-$VERSION.tar.gz"
rm -f ../$PRODUCT-$VERSION $TARBALL
ln -s $PWD ../$PRODUCT-$VERSION
cd ..
/usr/bin/tar \
    --exclude=.DS_Store --exclude=.git\* --exclude=.idea \
    --exclude=build --exclude=\*.xcworkspace --exclude=xcuserdata \
    --exclude=$PRODUCT-\*.tar.gz \
    -zcLf $TARBALL $PRODUCT-$VERSION
rm -f $PRODUCT-$VERSION
scp $TARBALL osric:web/nriley/software/
