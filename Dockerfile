FROM resin/armv7hf-debian:stretch

ENV BUILD_PACKAGES="ruby-dev gcc automake git libtool make libxslt-dev libxml2-dev zlib1g-dev build-essential libconfuse-dev libsane-dev libudev-dev libusb-dev libdbus-1-dev libsane-dev curl"
ENV RUNTIME_PACKAGES="locales sane-utils ghostscript ruby dumb-init redis-server"
ENV TESSDATA_PREFIX=/usr/local/share

COPY . /usr/src/app
COPY scripts/scanbd.conf /usr/local/etc/scanbd/scanbd.conf

# install dependencies
RUN apt-get update && apt-get -y install $RUNTIME_PACKAGES $BUILD_PACKAGES && \
    groupadd --gid 1000 app && \
    adduser --disabled-login --uid 1000 --gid 1000 --gecos '' app && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    echo "" > /etc/sane.d/dll.conf && \
    # build Tesseract 3.05
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    curl -sSL -o "$tmpdir/leptonica.tar.gz" https://github.com/DanBloomberg/leptonica/releases/download/1.74.4/leptonica-1.74.4.tar.gz && \
    tar xf leptonica.tar.gz && \
    cd leptonica-1.74.4 && \
    ./configure && \
    make -j8 && \
    make install && \
    cd / && \
    rm -rf "$tmpdir" && \
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    git clone https://github.com/tesseract-ocr/tesseract.git && \
    cd tesseract && \
    git checkout 3.05 && \
    ./autogen.sh && \
    ./configure && \
    make -j8 && \
    make install && \
    curl -sSL -o /usr/local/share/tessdata/osd.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/osd.traineddata && \
    curl -sSL -o /usr/local/share/tessdata/deu.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/deu.traineddata && \
    curl -sSL -o /usr/local/share/tessdata/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/3.04.00/eng.traineddata && \
    cd / && \
    rm -rf "$tmpdir" && \
    # install scanbd
    cd /usr/src/app/src/scanbd-code-244-trunk && \
    ./configure --enable-udev && \
    make all && \
    make install && \
    echo "test\ncanon_dr" > /usr/local/etc/scanbd/dll.conf && \
    cp /etc/sane.d/canon_dr.conf /usr/local/etc/scanbd/ && \
    # install ruby app
    gem install bundler && \
    cd /usr/src/app && \
    bundle install -j 8 && \
    chown -R app:app /usr/src/app && chmod +x /usr/src/app/run.sh && \
    #clean up
    AUTO_ADDED_PACKAGES=`apt-mark showauto` \
    apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#RUN [ "cross-build-end" ]
#RUN chown -R app:app /usr/src/app && chmod +x /usr/src/app/run.sh

USER app

WORKDIR /usr/src/app

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

CMD ["/usr/src/app/run.sh"]
#CMD ["ls"]

# CMDS:
# dbus-daemon --nofork --system
# inetutils-inetd -d
# scanbm -f
# SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -d7 -s-f -c /usr/local/etc/scanbd/scanbd.conf
