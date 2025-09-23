FROM debian:bullseye AS build
LABEL maintainer="Yeimar Yecid Lemus <yeimar112003@outlook.com>"

ENV SWITCH_VER=1.10.12  

# Install Required Dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        ca-certificates \
        git \
        sed \
        lsb-release \
        ssl-cert \
        ghostscript \
        libtiff5-dev \
        libtiff-tools \
        nginx \
        php \
        php-cli \
        php-fpm \
        php-pgsql \
        php-mysql \
        php-odbc \
        php-curl \
        php-imap \
        php-xml \
        wget \
        curl \
        openssh-server \
        supervisor \
        net-tools \
        gnupg2 \
        postgresql-client \
        unzip \
        tcpdump \
        nano \
        netcat



# Freeswitch build deps
RUN apt install -y \
        build-essential gcc libtool autoconf automake \
        cmake \
        libssl-dev \
        libasound2-dev \ 
        libogg-dev libvorbis-dev \
        libspeex-dev libspeexdsp-dev \ 
        libsqlite3-dev \
        libedit-dev \ 
        libcurl4-openssl-dev \
        libpcre3-dev \
        libjpeg-dev libpng-dev libtiff5-dev \
        libncurses5-dev \
        libgdbm-dev libdb-dev \
        libpq-dev \
        libvlc-dev \
        libldns-dev \
        uuid-dev \
        nasm \
        libavformat-dev libswscale-dev \
        libtool-bin lua5.4 liblua5.4-dev libmariadb-dev libmemcached-dev libopus-dev \
        libshout3-dev libmpg123-dev libmp3lame-dev libsndfile-dev \
        php-dev \
        python3.9-distutils python-dev


# Install spandsp3
RUN cd /usr/src && git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && ./autogen.sh && \
    ./configure --prefix=/usr && make all && make install

# Install sofia-sip
RUN cd /usr/src && git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && ./autogen.sh && \
    ./configure --prefix=/usr && make all && make install

# Install ks2
RUN cd /usr/src && git clone https://github.com/signalwire/libks.git && \
    cd libks && cmake . -DCMAKE_BUILD_TYPE=Release && \
    make all && make install

# Install signalwire-c2
RUN cd /usr/src && git clone https://github.com/signalwire/signalwire-c.git && \
    cd signalwire-c && cmake . -DCMAKE_BUILD_TYPE=Release && \
    make all && make install

# Get Freeswitch sources
RUN cd /usr/src && git clone https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && apt install libtool-bin -y && ./bootstrap.sh

#RUN cd /usr/src && wget http://files.freeswitch.org/freeswitch-releases/freeswitch-${SWITCH_VER}.-release.zip && \
#    unzip freeswitch-${SWITCH_VER}.-release.zip && \
#    rm -Rf freeswitch && \
#    mv freeswitch-${SWITCH_VER}.-release freeswitch

#RUN cd /usr/src/freeswitch/src/mod/endpoints/mod_gsmopen/gsmlib/gsmlib-1.10-patched-13ubuntu && ./configure && make && make install
#RUN cd /usr/src/freeswitch/src/mod/endpoints/mod_gsmopen/libctb-0.16/build && make DEBUG=0 GPIB=0 && make DEBUG=0 GPIB=0 install

# Enable modules
RUN sed -i /usr/src/freeswitch/modules.conf -e s:'#endpoints/mod_gsmopen:endpoints/mod_gsmopen:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#databases/mod_mariadb:databases/mod_mariadb:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_avmd:applications/mod_avmd:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_callcenter:applications/mod_callcenter:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_cidlookup:applications/mod_cidlookup:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_memcache:applications/mod_memcache:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_nibblebill:applications/mod_nibblebill:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_curl:applications/mod_curl:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_shout:formats/mod_shout:' && \
    sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_pgsql:formats/mod_pgsql:'

# Configure build
RUN cd /usr/src/freeswitch && ./configure && ./configure -C --enable-portable-binary --disable-dependency-tracking \
    --prefix=/usr --localstatedir=/var --sysconfdir=/etc \
    --with-openssl --enable-core-pgsql-support

# Build & install
RUN cd /usr/src/freeswitch && \
    make && \
    make install && \
    make sounds-install moh-install && \
    make hd-sounds-install hd-moh-install && \
    make cd-sounds-install cd-moh-install

# mod_gsmopen
#RUN apt-get install -y gsm-utils libgsmme-dev usb-modeswitch-data usb-modeswitch
#RUN cd /usr/src/freeswitch/src/mod/endpoints/mod_gsmopen/libctb-0.16/build && \
#    make DEBUG=0 GPIB=0 && \
#    make DEBUG=0 GPIB=0 install && \
#    ldconfig
#RUN cd /usr/src/freeswitch/src/mod/endpoints/mod_gsmopen && \
#    make clean && \
#    make install
#RUN cd /usr/src/freeswitch/src/mod/endpoints/mod_gsmopen/configs/ && \
#    cp gsmopen.conf.xml /etc/freeswitch/autoload_configs/

# Move the music into music/default directory
RUN mkdir -p /usr/share/freeswitch/sounds/music/default && \
    mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/music/default

### ----------------------------------------------------------------------------------------------------

FROM debian:bullseye

COPY --from=build /usr/lib /usr/
COPY --from=build /usr/share/freeswitch /usr/share/
COPY --from=build /etc/freeswitch /etc/
COPY --from=build /var/lib/freeswitch /var/lib/
COPY --from=build /var/log/freeswitch /var/log/
COPY --from=build /var/run/freeswitch /var/run/

RUN mkdir -p /etc/freeswitch /var/lib/freeswitch /usr/share/freeswitch /var/log/freeswitch /var/run/freeswitch && \
    usermod -aG dialout www-data && \
    chown -R www-data:www-data /etc/freeswitch && \
    chown -R www-data:www-data /var/lib/freeswitch && \
    chown -R www-data:www-data /usr/share/freeswitch && \
    chown -R www-data:www-data /var/log/freeswitch && \
    chown -R www-data:www-data /var/run/freeswitch

COPY freeswitch/start-freeswitch.sh /usr/bin/start-freeswitch.sh
RUN chmod +x /usr/bin/start-freeswitch.sh

# Remember, docker cannot handle too many ports
EXPOSE 5060/tcp
EXPOSE 5060/udp
EXPOSE 16384-16390/udp

# Persist Freeswitch data
VOLUME ["/etc/freeswitch/"]