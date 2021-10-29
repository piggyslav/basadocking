FROM debian:buster
WORKDIR /

ARG PROJECT_NAME
ENV PROJECT_NAME=$PROJECT_NAME

# Initial setup
RUN apt-get update && \
	apt-get dist-upgrade -y && \
	apt-get install -y wget curl apt-transport-https ca-certificates unzip file tini git openssh-server && \
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
	echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/php.list && \
	echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" > /etc/apt/sources.list.d/caddy-fury.list && \
	apt-get update && apt-get install -y \
		caddy \
		php7.4-cli \
		php7.4-fpm \
		php7.4-gd \
		php7.4-intl \
		php7.4-json \
		php7.4-mbstring \
		php7.4-mysql \
		php7.4-pdo \
		php7.4-tokenizer \
		php7.4-xml \
		php7.4-zip

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# copy files
ADD ./Caddyfile /etc/Caddyfile
ADD ./php.ini /etc/php/7.4/conf.d/999-php.ini
ADD ./php-fpm.conf /etc/php/7.4/php-fpm.conf
ADD ./entrypoint.sh /entrypoint.sh

# cleanup
RUN apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /var/lib/log/* /tmp/* /var/tmp/*

# SSH stuff
# add ssh user admin
RUN useradd -rm -d /home/admin/ -s /bin/bash -g root -G sudo -u 1001 admin
USER admin

# create folders and files
RUN mkdir -p /home/admin/.ssh/ && \
    chmod 0700 /home/admin/.ssh  && \
    touch /home/admin/.ssh/authorized_keys && \
    chmod 600 /home/admin/.ssh/authorized_keys && \
    touch /home/admin/.ssh/config && \
    chmod 600 /home/admin/.ssh/config

# copy shared keys
COPY ssh-keys /keys
COPY ssh-keys/id_rsa /home/admin/.ssh/id_rsa
RUN cat /keys/authorized_keys >> /home/admin/.ssh/authorized_keys
RUN cat /keys/config >> /home/admin/.ssh/config

USER root

RUN chmod 600 /home/admin/.ssh/id_rsa
# Create known_hosts
RUN mkdir /root/.ssh/&& \
    chmod 0700 /root/.ssh
RUN touch /root/.ssh/known_hosts
# Add github key
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# edit settings
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 80
EXPOSE 22
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
