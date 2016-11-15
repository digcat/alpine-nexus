FROM java:openjdk-8-jdk-alpine

RUN apk add --no-cache git openssh-client curl zip unzip bash ttf-dejavu

ENV NEXUS_HOME /usr/local/nexus
ENV MVN_VER 3.3.9
ENV URI_MAVEN http://apache.ip-connect.vn.ua/maven/maven-3/$MVN_VER/binaries/apache-maven-$MVN_VER-bin.tar.gz
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH /opt/apache-maven-$MVN_VER/bin:$PATH

WORKDIR /opt
RUN wget -O- $URI_MAVEN | tar -zx && mvn dependency:get || mvn deploy:deploy-file || echo Ok

ARG user=nexus
ARG group=nexus
ARG uid=1010
ARG gid=1010

# ensure you use the same uid
RUN addgroup -g ${gid} ${group} \
    && adduser -h "$NEXUS_HOME" -u ${uid} -G ${group} -s /bin/bash -D ${user}

# Nexus home directory is a volume, so configuration and build history 
VOLUME /var/nexus_home

ENV TINI_SHA 066ad710107dc7ee05d3aa6e4974f01dc98f3888

# Use tini as subreaper in Docker container to adopt zombie processes 
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha1sum -c -

ARG NEXUS_VERSION
ENV NEXUS_VERSION 3.0.0-03 
ENV NEXUS_URL http://download.sonatype.com/nexus/3/nexus-3.0.0-03-unix.tar.gz
RUN mkdir -p /opt/nexus_vers
USER root
RUN curl -fsSL ${NEXUS_URL} -o /opt/nexus.tar.gz \
  && gzip -d /opt/nexus.tar.gz \
  && tar -xvf /opt/nexus.tar -C /opt/nexus_vers
RUN ls -alrt /opt/nexus_vers
RUN cp -rp /opt/nexus_vers/nexus-3.0.0-03/* /usr/local/nexus
RUN cp -rp /opt/nexus_vers/nexus-3.0.0-03/.install4j /usr/local/nexus
RUN ls -alrt /usr/local/nexus/bin

# for main web interface:
EXPOSE 8081

# will be used by attached slave agents:

RUN chown -R ${user}:${user} "${NEXUS_HOME}"
USER ${user}
RUN /bin/ls -alrt /usr/local/nexus/bin
RUN /usr/local/nexus/bin/nexus start
ENTRYPOINT ["/usr/bin/tail", "-f", "/etc/motd"]
