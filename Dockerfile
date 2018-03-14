FROM jenkins/jenkins:slim
MAINTAINER bingo <bingov5@icloud.com>

# Jenkins is using jenkins user, we need root to install things.
USER root

# Install maven and gradle.
RUN apt-get update && \
  apt-get -y -f install apt-transport-https wget unzip && \ 
  mkdir /maven && \
  curl http://mirror.bit.edu.cn/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz | tar xzf - -C /maven --strip-components=1 && \
  ln -s /maven/bin/mvn /usr/bin/mvn && \
  wget -q https://services.gradle.org/distributions/gradle-4.6-bin.zip && \
  unzip -q gradle-4.6-bin.zip && \
  rm -rf gradle-4.6-bin.zip && \
  mv gradle-4.6 gradle && \
  ln -s /gradle/bin/gradle /usr/bin/gradle

# Install php and composer.
RUN apt-get -y -f install php && \
  mkdir /php-composer && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/php-composer && \
  ln -s /php-composer/composer.phar /usr/bin/composer

# Install node, npm, cnpm and yarn.
RUN mkdir /nodejs && \
  curl http://nodejs.org/dist/v8.9.4/node-v8.9.4-linux-x64.tar.gz | tar xzf - -C /nodejs --strip-components=1 && \
  ln -s /nodejs/bin/node /usr/bin/node && \
  ln -s /nodejs/bin/npm /usr/bin/npm && \
  npm install -g cnpm --registry=https://registry.npm.taobao.org && \
  ln -s /nodejs/bin/cnpm /usr/bin/cnpm && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get -y -f install --no-install-recommends yarn && \
  apt-get clean -y

# SSH config.
RUN echo "    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

# Go back to jenkins user.
USER jenkins
