FROM jenkins/jenkins:alpine
MAINTAINER bingo <bingov5@icloud.com>

# Jenkins is using jenkins user, we need root to install things.
USER root

# timezone
ENV TIMEZONE Asia/Shanghai
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
    && echo $TIMEZONE > /etc/timezone

# zip unzip
RUN apk add --no-cache zip unzip

######################## Docker in Docker ########################

RUN apk add --no-cache \
    ca-certificates

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV DOCKER_CHANNEL edge
ENV DOCKER_VERSION 18.02.0-ce
ENV DOCKER_HOST_ADDRESS "docker:2375"
ENV DOCKER_HOST "tcp://$DOCKER_HOST_ADDRESS"

RUN set -ex; \
  apk add --no-cache --virtual .fetch-deps \
    curl \
    tar \
  ; \
  \
  apkArch="$(apk --print-arch)"; \
  case "$apkArch" in \
    x86_64) dockerArch='x86_64' ;; \
    armhf) dockerArch='armel' ;; \
    aarch64) dockerArch='aarch64' ;; \
    ppc64le) dockerArch='ppc64le' ;; \
    s390x) dockerArch='s390x' ;; \
    *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
  esac; \
  \
  if ! curl -fL -o docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
    echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
    exit 1; \
  fi; \
  \
  tar --extract \
    --file docker.tgz \
    --strip-components 1 \
    --directory /usr/local/bin/ \
  ; \
  rm docker.tgz; \
  \
  apk del .fetch-deps; \
  \
  dockerd -v; \
  docker -v

######################## Maven and Gradle ########################

ENV MAVEN_VERSION 3.5.4
ENV GRADLE_VERSION 4.6

RUN apk add --no-cache --virtual .maven-gradle-deps wget curl tar unzip \
  && mkdir /maven \
  && curl http://mirror.bit.edu.cn/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /maven --strip-components=1 \
  && ln -s /maven/bin/mvn /usr/bin/mvn \
  && wget -q https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip \
  && unzip -q gradle-$GRADLE_VERSION-bin.zip \
  && rm -rf gradle-$GRADLE_VERSION-bin.zip \
  && mv gradle-$GRADLE_VERSION gradle \
  && ln -s /gradle/bin/gradle /usr/bin/gradle \
  && apk del .maven-gradle-deps

########################## Node and Yarn #########################

ENV NODE_VERSION 8.16.1
ENV YARN_VERSION 1.3.2

RUN apk add --no-cache \
        libstdc++ \
  && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        libgcc \
        linux-headers \
        make \
        python \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
  && tar -xf "node-v$NODE_VERSION.tar.xz" \
  && cd "node-v$NODE_VERSION" \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && npm install cnpm -g --registry=https://registry.npm.taobao.org \
  && apk del .build-deps \
  && cd .. \
  && rm -Rf "node-v$NODE_VERSION" \
  && rm "node-v$NODE_VERSION.tar.xz"

RUN apk add --no-cache --virtual .build-deps-yarn \
        curl \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && mkdir -p /opt/yarn \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz \
  && apk del .build-deps-yarn

########################## SSH config #########################

RUN echo -e "\nHost *\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

# Go back to jenkins user.
USER jenkins
