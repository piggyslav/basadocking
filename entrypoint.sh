#!/usr/bin/env bash
set -e
echo Entrypoint of project: "$PROJECT_NAME"

# if folder with project does not exist, create it
if [ ! -f "/srv/www/index.php" ]; then
  echo "Project was not cloned yet, cloning..."
  cd /srv
  # Clone the conf files into the docker container
  git clone --config core.sshCommand="ssh -i /home/admin/.ssh/id_rsa" git@github.com:piggyslav/basa.git .
  rm -rf /srv/.git
  git config --global user.email "docker@basa.com"
  git config --global user.name "Docking Basa"

  # Create new repo on github
  echo Creating repo piggyslav/"$PROJECT_NAME"....
  curl -u piggyslav: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 https://api.github.com/user/repos -d '{"name": "'$PROJECT_NAME'", "description": "", "private": true}'
  git init
  git remote add origin git@github.com:piggyslav/"$PROJECT_NAME".git
  # Create new repo on github checkout and add everything
  git add .
  git commit -m "initial commit"
  git checkout -b prod
  git checkout -b dev
  git config --global core.sshCommand "ssh -i /home/admin/.ssh/id_rsa"
  git push -u origin dev prod

  echo Repo created successfully, running composer
  # composer run
  composer update --no-progress

  # Folders and permissions
  chmod 0666 /srv/app/config/config.neon
  chmod 0666 /srv/www/upload
  mkdir /srv/temp /srv/log
  chmod 0777 /srv/log
  chmod 0777 /srv/temp
  chown -R admin:root /srv
fi
cd /
echo "Project ready starting..."

/usr/sbin/php-fpm7.4 -F -R -y /etc/php/7.4/php-fpm.conf &
caddy run -config /etc/Caddyfile &
wait -n
service ssh start
service ssh status