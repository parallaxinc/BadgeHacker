#!/bin/bash
set -e

case "$PLATFORM" in
"osx")
    qmake -v
    packthing -h

    packthing -j4 dmg
    mv build/staging/badgehacker-*.dmg .
    ;;
"linux")
    qmake -v
    packthing -h

    packthing -j4 run
    mv build/staging/badgehacker-*.run .

    fakeroot packthing -j4 deb
    mv build/staging/badgehacker-*.deb .
    ;;
"rpi")
    sudo chroot $MNT uname -a
    sudo chroot $MNT qmake -v
    sudo chroot $MNT packthing -h

    sudo packthing --checkout

    sudo chroot $MNT bash -c "cd /home/travis/build/parallaxinc/PropellerIDE/ && \
                                        packthing -j4 deb --arch armhf && \
                                        mv build/staging/badgehacker-*.deb ."

    sudo chown `whoami`:`groups | sed -r 's/ .*//g'` badgehacker-*.deb
    ;;
*)
    echo "Invalid PLATFORM"
    exit 1
    ;;
esac
