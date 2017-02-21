#!/bin/bash

set -e

LS_BIN=/opt/logstash/bin/logstash
LS_CONF_DIR=/etc/logstash/conf.d
LS_LOG_DIR=/var/log/logstash
LS_LOG_FILE=${LS_LOG_DIR}/logstash.log
LS_LOG_STDOUT=${LS_LOG_DIR}/logstash.stdout
LS_LOG_ERROR=${LS_LOG_DIR}/logstash.err

set -- gosu logstash ${LS_BIN} -f ${LS_CONF_DIR} -l ${LS_LOG_FILE} > ${LS_LOG_STDOUT} 2> ${LS_LOG_ERROR}

if [ "${ELASTICSEARCH_URL}" ]; then
    sed -i -e "s#hosts.*#hosts => [\"${ELASTICSEARCH_URL}\"]#" /etc/logstash/conf.d/30-output.conf
fi

exec "$@"

