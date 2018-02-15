FROM resin/armv7hf-debian
ENV QEMU_EXECVE=1

RUN [ "cross-build-start" ]

RUN apt-get update && \
    apt-get -y install  locales sane-utils tesseract-ocr tesseract-ocr-deu \
                        tesseract-ocr-eng ghostscript curl ruby ruby-dev gcc \
                        make libxslt-dev libxml2-dev zlib1g-dev libconfuse-dev \
                        libsane-dev libudev-dev libusb-dev libdbus-1-dev libsane-dev \
                        dbus xinetd && \
    groupadd --gid 1000 app && \
    adduser --disabled-login --uid 1000 --gid 1000 --gecos '' app && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "net" > /etc/sane.d/dll.conf

COPY . /usr/src/app

# install scanbd
RUN cd /usr/src/app/src/scanbd-code-244-trunk && \
    ./configure --enable-udev && \
    make all && \
    make install && \
    echo "test\ncanon_dr" > /usr/local/etc/scanbd/dll.conf

COPY scripts/scanbd.conf /usr/local/etc/scanbd/scanbd.conf
COPY scripts/saned.conf /usr/local/etc/scanbd/saned.conf
COPY scripts/net.conf /etc/sane.d/net.conf
COPY scripts/scanbd_dbus.conf /etc/dbus-1/system.d/scanbd_debus.conf
COPY scripts/sane-port /etc/xinetd.d/sane-port

#RUN echo "sane-port stream tcp4 nowait saned /usr/local/sbin/scanbm scanbm" >> /etc/inetd.conf
RUN mkdir -p /var/run/dbus/

# install ruby app
RUN gem install bundler
RUN cd /usr/src/app && \
    bundle install -j 8

RUN [ "cross-build-end" ]

RUN chown -R app:app /usr/src/app

USER app

WORKDIR /usr/src/app

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

CMD ["run.sh"]
#CMD ["ls"]

# CMDS:
# dbus-daemon --nofork --system
# inetutils-inetd -d
# scanbm -f
# SANE_CONFIG_DIR=/usr/local/etc/scanbd /usr/local/sbin/scanbd -d7 -s-f -c /usr/local/etc/scanbd/scanbd.conf
