FROM jasonchw/alpine-consul:0.7.0

ARG JAVA_ALPINE_VERSION=8.111.14-r0
ARG LOGSTASH_VER=2.4.0
ARG LOGSTASH_URL=https://download.elastic.co/logstash/logstash

ENV LANG=C.UTF-8 \
    TWITTER_CONSUMER_KEY="consumer_key" \
    TWITTER_CONSUMER_SECRET="consumer_secret" \
    TWITTER_OAUTH_TOKEN="oauth_token" \
    TWITTER_OAUTH_TOKEN_SECRET="oauth_token_secret" \
    TWITTER_FOLLOWS="follows"

RUN apk update && apk upgrade && \
    apk add openjdk8-jre="$JAVA_ALPINE_VERSION" && \
    curl -sL ${LOGSTASH_URL}/logstash-${LOGSTASH_VER}.tar.gz | tar xfz - -C /opt/ && \
    mv /opt/logstash-${LOGSTASH_VER} /opt/logstash && \
    /opt/logstash/bin/logstash-plugin install logstash-input-beats && \
    rm -rf /var/cache/apk/* /tmp/* && \
    rm /etc/consul.d/consul-ui.json && \
    addgroup logstash && \
    adduser -S -G logstash logstash && \
    mkdir -p /var/log/logstash/ && \
    mkdir -p /etc/logstash/conf.d/ && \
    mkdir -p /etc/pki/tls/certs/ && \
    mkdir -p /etc/pki/tls/private/

COPY etc/consul.d/logstash.json                /etc/consul.d/
COPY etc/consul-templates/30-output.conf.ctmpl /etc/consul-templates/30-output.conf.ctmpl

# certificate
COPY ./fqdn-log.example.org.crt   /etc/pki/tls/certs/fqdn-log.example.org.crt
COPY ./fqdn-log.example.org.key   /etc/pki/tls/private/fqdn-log.example.org.key
COPY ./fqdn-log.example.org.pkcs8 /etc/pki/tls/private/fqdn-log.example.org.pkcs8

# filters
#COPY etc/logstash/conf.d/ /etc/logstash/conf.d/

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

