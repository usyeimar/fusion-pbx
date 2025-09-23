FROM usyeimar/freeswitch

LABEL maintainer="Yeimar Lemus <yeimar112003@outlook.com>"
ENV FUSION_PBX_BRANCH=master
ENV DEBIAN_FRONTEND=noninteractive

# ---- System packages ----
RUN apt-get update && apt-get install -y \
    nano \
    php \
    php-fpm \
    php-cli \
    php-pgsql \
    php-curl \
    php-mbstring \
    php-xml \
    php-gd \
    nginx \
    git \
    supervisor \
    wget \
    lsb-release \
    gnupg2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

## FreeSWITCH provided by base image usyeimar/freeswitch

# ---- Setup NGINX ----
RUN PHP_VERSION=$(php --version | head -1 | awk '{print $2}' | cut -d. -f1-2) \
 && wget https://raw.githubusercontent.com/samael33/fusionpbx-install.sh/master/debian/resources/nginx/fusionpbx \
      -O /etc/nginx/sites-available/fusionpbx \
 && sed -i "s|/var/run/php/php7.1-fpm.sock|/run/php/php${PHP_VERSION}-fpm.sock|g" /etc/nginx/sites-available/fusionpbx \
 && ln -sf /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx \
 && ln -sf /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key \
 && ln -sf /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt \
 && rm -f /etc/nginx/sites-enabled/default

# ---- FusionPBX source ----
RUN mkdir -p /var/cache/fusionpbx && chown -R www-data:www-data /var/cache/fusionpbx
RUN git clone -b ${FUSION_PBX_BRANCH} https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx \
 && chown -R www-data:www-data /var/www/fusionpbx

# ---- FreeSWITCH config ----
RUN cp -R /var/www/fusionpbx/app/switch/resources/conf/* /etc/freeswitch \
 && chown -R www-data:www-data /etc/freeswitch \
 && sed -i 's/<!-- <param name="rtp-start-port" value="16384"\/> -->/<param name="rtp-start-port" value="16384"\/>/g' /etc/freeswitch/autoload_configs/switch.conf.xml \
 && sed -i 's/<!-- <param name="rtp-end-port" value="32768"\/> -->/<param name="rtp-end-port" value="16390"\/>/g' /etc/freeswitch/autoload_configs/switch.conf.xml

RUN cp -R /var/www/fusionpbx/app/switch/resources/scripts /usr/share/freeswitch \
 && chown -R www-data:www-data /usr/share/freeswitch

# ---- FusionPBX config dir ----
RUN mkdir -p /etc/fusionpbx /run/php \
 && chown -R www-data:www-data /etc/fusionpbx

# ---- Supervisor config ----
# Create supervisord.conf inline (nginx, php-fpm, freeswitch)
RUN PHP_VERSION=$(php --version | head -1 | awk '{print $2}' | cut -d. -f1-2) \
 && cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[supervisord]
nodaemon=true

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"

[program:php-fpm]
command=/usr/sbin/php-fpm${PHP_VERSION} -F
autorestart=true

[program:freeswitch]
command=/usr/bin/freeswitch -nonat -nf
user=www-data
autorestart=true
EOF

EXPOSE 80 443

VOLUME ["/etc/fusionpbx"]

CMD ["/usr/bin/supervisord", "-n"]
