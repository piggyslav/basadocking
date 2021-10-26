FROM debian:buster
WORKDIR /

# Initial setup
RUN apt-get update && \
	apt-get dist-upgrade -y && \
	# dependencies
	apt-get install -y wget curl apt-transport-https ca-certificates unzip file tini git openssh-server #&& \
#	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
#	echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/php.list && \
#	echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" > /etc/apt/sources.list.d/caddy-fury.list && \
#	apt-get update && apt-get install -y \
#		caddy \
#		php7.4-cli \
#		php7.4-fpm \
#		php7.4-gd \
#		php7.4-intl \
#		php7.4-json \
#		php7.4-mbstring \
#		php7.4-sqlite3 \
#		php7.4-tokenizer \
#		php7.4-xml \
#		php7.4-zip && \
#	# composer
#	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

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
# Create known_hosts
RUN mkdir /root/.ssh/&& \
    chmod 0700 /root/.ssh
RUN touch /root/.ssh/known_hosts
# Add github key
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# edit settings
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

#RUN service ssh start
#RUN ssh-add /home/admin/.ssh/id_rsa

WORKDIR /srv

# Clone the conf files into the docker container
RUN git clone --config core.sshCommand="ssh -i /home/admin/.ssh/id_rsa" git@github.com:piggyslav/basa.git .
RUN rm -rf /srv/.git
RUN git config --global user.email "docker@basa.com"
RUN git config --global user.name "Docking Basa"

# Create new repo on github
RUN curl -u piggyslav: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 https://api.github.com/user/repos -d '{"name":"basadocking", "description": "Basa dockerfile project", "private": true}'
RUN git init
RUN git remote add origin git@github.com:piggyslav/basadocking.git
# Create new repo on github checkout and add everything
RUN git add .
RUN git commit -m "initial commit"
RUN git checkout -b dev
RUN git push -u origin dev prod

# Folder permissions
#RUN chmod 0777 /srv/log
WORKDIR /
RUN chmod +x entrypoint.sh
#ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
