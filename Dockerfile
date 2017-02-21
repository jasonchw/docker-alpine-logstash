FROM jasonchw/alpine-consul:0.7.0

ARG JAVA_ALPINE_VERSION=8.111.14-r0
ARG LOGSTASH_VER=2.4.1
ARG LOGSTASH_URL=https://download.elastic.co/logstash/logstash

ENV LANG=C.UTF-8 

RUN apk update && apk upgrade && \
    apk add openjdk8-jre="$JAVA_ALPINE_VERSION" && \
    curl -sL ${LOGSTASH_URL}/logstash-${LOGSTASH_VER}.tar.gz | tar xfz - -C /opt/ && \
    mv /opt/logstash-${LOGSTASH_VER} /opt/logstash && \
    /opt/logstash/bin/logstash-plugin install logstash-input-beats && \
    rm -rf /var/cache/apk/* /tmp/* && \
    rm /etc/consul.d/consul-ui.json && \
    addgroup logstash && \
    adduser -S -G logstash logstash && \
    mkdir -p /var/log/logstash/ 

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

