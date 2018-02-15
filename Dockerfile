FROM ruby:2.5

RUN apt-get update && \
    apt-get -y install locales sane-utils tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng ghostscript && \
    groupadd --gid 1000 app && \
    adduser --disabled-login --uid 1000 --gid 1000 --gecos '' app && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo test >> /etc/sane.d/dll.conf

COPY Gemfile* /usr/src/app/

RUN echo '2.5.0' > /usr/src/app/.ruby-version && \
    cd /usr/src/app && \
    bundle install -j 8 && \
    chown -R app /usr/local/bundle

USER app
WORKDIR /usr/src/app
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
