FROM jenkins
MAINTAINER bingo <bingov5@icloud.com>

# Jenkins is using jenkins user, we need root to install things.
USER root

# Install maven.
RUN mkdir /maven && \
  curl http://mirror.bit.edu.cn/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz | tar xzf - -C /maven --strip-components=1 && \
  ln -s /maven/bin/mvn /usr/bin/mvn

# Install php and composer.
RUN apt-get update && \
  apt-get -y -f install apt-transport-https php && \
  mkdir /php-composer && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/php-composer && \
  ln -s /php-composer/composer.phar /usr/bin/composer

# Install node (npm) and yarn.
RUN mkdir /nodejs && \
  curl http://nodejs.org/dist/v8.9.4/node-v8.9.4-linux-x64.tar.gz | tar xzf - -C /nodejs --strip-components=1 && \
  ln -s /nodejs/bin/node /usr/bin/node && \
  ln -s /nodejs/bin/npm /usr/bin/npm && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get -y -f install --no-install-recommends yarn
  
RUN apt-get clean -y

# Go back to jenkins user.
USER jenkins