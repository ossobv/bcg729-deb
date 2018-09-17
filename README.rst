OSSO build of the Bcg729 shared library (G729 speech codec)
===========================================================

Using Docker::

    ./Docker.build

If the build succeeds, the built Debian packages are placed inside (a
subdirectory of) ``Docker.out/``.


------------
Manual build
------------

Get source::

    VER=1.0.4
    curl \
      https://codeload.github.com/BelledonneCommunications/bcg729/tar.gz/$VER \
      >bcg729_$VER.orig.tar.gz
    tar zxf bcg729_$VER.orig.tar.gz

Setup ``debian/`` dir::

    cd bcg729-$VER
    git clone https://github.com/ossobv/bcg729-deb.git debian

Optionally alter ``debian/changelog`` and then build::

    dpkg-buildpackage -us -uc -sa
