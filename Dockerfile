ARG osdistro=debian
ARG oscodename=stretch

FROM $osdistro:$oscodename
LABEL maintainer="Walter Doekes <wjdoekes+bcg729@osso.nl>"
LABEL dockerfile-vcs=https://github.com/ossobv/bcg729-deb

ARG DEBIAN_FRONTEND=noninteractive

# This time no "keeping the build small". We only use this container for
# building/testing and not for running, so we can keep files like apt
# cache. We do this before copying anything and before getting lots of
# ARGs from the user. That keeps this bit cached.
RUN echo 'APT::Install-Recommends "0";' >/etc/apt/apt.conf.d/01norecommends
# We'll be ignoring "debconf: delaying package configuration, since apt-utils
#   is not installed"
RUN apt-get update -q && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
        ca-certificates curl \
        build-essential devscripts dh-autoreconf dpkg-dev equivs quilt && \
    printf "%s\n" \
        QUILT_PATCHES=debian/patches QUILT_NO_DIFF_INDEX=1 \
        QUILT_NO_DIFF_TIMESTAMPS=1 'QUILT_DIFF_OPTS="--show-c-function"' \
        'QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index"' \
        >~/.quiltrc

# Apt-get prerequisites according to control file.
COPY control /build/debian/control
RUN mk-build-deps --install --remove --tool "apt-get -y" /build/debian/control

# debian, deb, stretch, bcg729, 1.0.4, '', 0osso1
ARG osdistro osdistshort oscodename upname upversion debepoch= debversion

COPY changelog /build/debian/changelog
RUN . /etc/os-release && \
    sed -i -e "1s/+[^+)]*)/+${osdistshort}${VERSION_ID})/;1s/) stable;/) ${oscodename};/" \
        /build/debian/changelog && \
    fullversion="${upversion}-${debversion}+${osdistshort}${VERSION_ID}" && \
    expected="${upname} (${debepoch}${fullversion}) ${oscodename}; urgency=medium" && \
    head -n1 /build/debian/changelog && \
    if test "$(head -n1 /build/debian/changelog)" != "${expected}"; \
    then echo "${expected}  <-- mismatch" >&2; false; fi

# Trick to allow caching of UPNAME*.tar.gz files. Download them
# once using the curl command below into .cache/* if you want. The COPY
# is made conditional by the "[z]" "wildcard". (We need one existing
# file (README.rst) so the COPY doesn't fail.)
COPY ./README.rst .cache/${upname}_${upversion}.orig.tar.g[z] /build/
# https://github.com/BelledonneCommunications/bcg729/tags
RUN if ! test -s /build/${upname}_${upversion}.orig.tar.gz; then \
    url="https://github.com/BelledonneCommunications/bcg729/archive/refs/tags/${upversion}.tar.gz" && \
    echo "Fetching: ${url}" >&2 && \
    curl -fLsS "${url}" -o /build/${upname}_${upversion}.orig.tar.gz; fi
# 0234814618a4314cb56ae0b9084d1ae1 = 1.0.4
# 3e8277a684b8060c60bf9fb5ef99920b = 1.1.1
RUN test $(md5sum /build/bcg729_${upversion}.orig.tar.gz | awk '{print $1}') = 3e8277a684b8060c60bf9fb5ef99920b
RUN cd /build && tar zxf "${upname}_${upversion}.orig.tar.gz" && \
    mv debian "${upname}-${upversion}/"
COPY compat control copyright libbcg729-0.install libbcg729-0.symbols \
    libbcg729-dev.install patches rules source watch \
    /build/${upname}-${upversion}/debian/
WORKDIR /build/${upname}-${upversion}

# Build!
RUN DEB_BUILD_OPTIONS=parallel=6 dpkg-buildpackage -us -uc -sa

# TODO: for bonus points, we could run quick tests here;
# for starters dpkg -i tests?

# Write output files (store build args in ENV first).
ENV oscodename=$oscodename osdistshort=$osdistshort \
    upname=$upname upversion=$upversion debversion=$debversion
RUN . /etc/os-release && fullversion=${upversion}-${debversion}+${osdistshort}${VERSION_ID} && \
    mkdir -p /dist/${upname}_${fullversion} && \
    mv /build/${upname}_${upversion}.orig.tar.gz /dist/${upname}_${fullversion}/ && \
    mv /build/*${fullversion}* /dist/${upname}_${fullversion}/ && \
    cd / && find dist/${upname}_${fullversion} -type f >&2
