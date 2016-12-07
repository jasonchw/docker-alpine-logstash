#!/bin/bash

set -e

LS_BIN=/opt/logstash/bin/logstash
LS_CONF_DIR=/etc/logstash/conf.d
LS_LOG_DIR=/var/log/logstash
LS_LOG_FILE=${LS_LOG_DIR}/logstash.log
LS_LOG_STDOUT=${LS_LOG_DIR}/logstash.stdout
LS_LOG_ERROR=${LS_LOG_DIR}/logstash.err

set -- gosu logstash ${LS_BIN} -f ${LS_CONF_DIR} -l ${LS_LOG_FILE} > ${LS_LOG_STDOUT} 2> ${LS_LOG_ERROR}

sleep 5
consul-template -consul localhost:8500 -once -template "/etc/consul-templates/30-output.conf.ctmpl:/tmp/30-output.conf"

# input
if [ "${TWITTER_CONSUMER_KEY}" ]; then
    sed -i -e "s#consumer_key.*#consumer_key => \"${TWITTER_CONSUMER_KEY}\"#" /etc/logstash/conf.d/03-input-twitter.conf
fi
if [ "${TWITTER_CONSUMER_SECRET}" ]; then
    sed -i -e "s#consumer_secret.*#consumer_secret => \"${TWITTER_CONSUMER_SECRET}\"#" /etc/logstash/conf.d/03-input-twitter.conf
fi
if [ "${TWITTER_OAUTH_TOKEN}" ]; then
    sed -i -e "s#oauth_token\ .*#oauth_token => \"${TWITTER_OAUTH_TOKEN}\"#" /etc/logstash/conf.d/03-input-twitter.conf
fi
if [ "${TWITTER_OAUTH_TOKEN_SECRET}" ]; then
    sed -i -e "s#oauth_token_secret.*#oauth_token_secret => \"${TWITTER_OAUTH_TOKEN_SECRET}\"#" /etc/logstash/conf.d/03-input-twitter.conf
fi
if [ ! -z "${TWITTER_FOLLOWS}" ]; then
    FOLLOWS=""
    for FOLLOW in $(echo ${TWITTER_FOLLOWS} | sed -e 's/,/ /g'); do
        FOLLOWS+=" ${FOLLOW}"
    done
    FOLLOWS=$(echo ${FOLLOWS} | sed -e 's/ /\",\"/g')
    if [ "X${FOLLOWS}" != "X" ]; then
        sed -i -e "s#follows.*#follows => [\"${FOLLOWS}\"]#" /etc/logstash/conf.d/03-input-twitter.conf
    fi
fi

# output
if [ "${ELASTICSEARCH_URL}" ]; then
    sed -i -e "s#hosts.*#hosts => [\"${ELASTICSEARCH_URL}\"]#" /etc/logstash/conf.d/30-output.conf
fi

exec "$@"

