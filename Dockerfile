FROM jasonchw/alpine-consul:0.7.0

ARG JAVA_VERSION_MAJOR=8
ARG JAVA_VERSION_MINOR=121
ARG GLIBC_VERSION=2.25-r0 
ARG LOGSTASH_VER=2.4.1
ARG LOGSTASH_URL=https://download.elastic.co/logstash/logstash

ENV LANG=C.UTF-8 \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin

COPY jdk-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz /tmp/java.tar.gz 

RUN apk update && apk upgrade && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    curl -sL ${LOGSTASH_URL}/logstash-${LOGSTASH_VER}.tar.gz | tar xfz - -C /opt/ && \
    mv /opt/logstash-${LOGSTASH_VER} /opt/logstash && \
    /opt/logstash/bin/logstash-plugin install logstash-input-beats && \
    addgroup logstash && \
    adduser -S -G logstash logstash && \
    mkdir -p /var/log/logstash/ && \
    rm /etc/consul.d/consul-ui.json && \
    rm -rf /var/cache/apk/* /tmp/* \
           /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar 

COPY etc/consul.d/logstash.json                /etc/consul.d/

# logrotate
COPY ./logstash-logrotate /etc/logrotate.d/logstash

# startup scripts
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY start-logstash.sh    /usr/local/bin/start-logstash.sh
COPY healthcheck.sh       /usr/local/bin/healthcheck.sh

RUN chown -R logstash:logstash /opt/logstash/ && \
    chown -R logstash:logstash /var/log/logstash/ && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/start-logstash.sh && \
    chmod +x /usr/local/bin/healthcheck.sh && \
    chmod 644 /etc/logrotate.d/logstash

EXPOSE 5000 5044

ENTRYPOINT ["docker-entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=5s --retries=300 CMD /usr/local/bin/healthcheck.sh

