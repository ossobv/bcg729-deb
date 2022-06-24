OSSO build of the Bcg729 shared library (G729 speech codec)
===========================================================

*NOTE: This package is obsolete now that there is libbcg720-0 in vanilla
Debian/Ubuntu.*


Docker build
------------

Just do::

    ./Dockerfile.build

And it will create the build files in ``Dockerfile.out/``.

For example::

    $ dpkg-deb -c stretch/bcg729_1.0.4-0osso3+deb9/libbcg729-0_1.0.4-0osso3+deb9_amd64.deb
     55,864  /usr/lib/x86_64-linux-gnu/libbcg729.so.0.0.0
        691  /usr/share/doc/libbcg729-0/changelog.Debian.gz
      3,459  /usr/share/doc/libbcg729-0/copyright
          0  /usr/lib/x86_64-linux-gnu/libbcg729.so.0 -> libbcg729.so.0.0.0
