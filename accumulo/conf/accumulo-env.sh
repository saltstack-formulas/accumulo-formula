#! /usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###
### Configure these environment variables to point to your local installations.
###
### The functional tests require conditional values, so keep this style:
###
### test -z "$JAVA_HOME" && export JAVA_HOME=/usr/local/lib/jdk-1.6.0
###
###
### Note that the -Xmx -Xms settings below require substantial free memory: 
### you may want to use smaller values, especially when running everything
### on a single machine.
###

export ACCUMULO_HOME={{ prefix }}

if [ -z "$HADOOP_HOME" ]
then
	test -z "$HADOOP_PREFIX"      && export HADOOP_PREFIX={{ hadoop_prefix }}
else
   HADOOP_PREFIX="$HADOOP_HOME"
   unset HADOOP_HOME
fi

test -z "$HADOOP_CONF_DIR"       && export HADOOP_CONF_DIR={{ hadoop_config }}
test -z "$JAVA_HOME"             && export JAVA_HOME={{ java_home }}
test -z "$ZOOKEEPER_HOME"        && export ZOOKEEPER_HOME={{ zookeeper_home }}
test -z "$ACCUMULO_LOG_DIR"      && export ACCUMULO_LOG_DIR={{ accumulo_logs }}
if [ -f {{ alt_config }}/accumulo.policy ]
then
	POLICY="-Djava.security.manager -Djava.security.policy={{ alt_config }}/accumulo.policy"
fi

{%- if memory_profile == "512MB" %}
{%- set worker_heap = '512m' %}
{%- set mgr_heap = '256m' %}
{%- elif memory_profile == "1GB" %}
{%- set worker_heap = '1024m' %}
{%- set mgr_heap = '512m' %}
{%- elif memory_profile == "2GB" %}
{%- set worker_heap = '2048m' %}
{%- set mgr_heap = '1024m' %}
{%- elif memory_profile == "3GB" %}
{%- set worker_heap = '3072m' %}
{%- set mgr_heap = '1536m' %}
{%- else %}
{%- set worker_heap = manual_worker_heap %}
{%- set mgr_heap    = manual_mgr_heap %}
{%- endif %}

TSERVER_DBG="{{ salt['grains.get']('accumulo:config:debug_opts:tserver', '') }}"
MASTER_DBG="{{ salt['grains.get']('accumulo:config:debug_opts:master', '') }}"
MONITOR_DBG="{{ salt['grains.get']('accumulo:config:debug_opts:monitor', '') }}"
GC_DBG="{{ salt['grains.get']('accumulo:config:debug_opts:gc', '') }}"

export ACCUMULO_MONITOR_BIND_ALL="true"
export JMX_OPTS=" -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=127.0.0.1"
MASTER_OOM_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$ACCUMULO_LOG_DIR/master.hpro"
TSERVER_OOM_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$ACCUMULO_LOG_DIR/tserver.hpro"
test -z "$ACCUMULO_TSERVER_OPTS" && export ACCUMULO_TSERVER_OPTS="$TSERVER_DBG $TSERVER_OOM_OPTS $JMX_OPTS -Dcom.sun.management.jmxremote.port=26051 ${POLICY} -Xmx{{ worker_heap }} -Xms128m "
test -z "$ACCUMULO_MASTER_OPTS"  && export ACCUMULO_MASTER_OPTS="$MASTER_DBG $MASTER_OOM_OPTS $JMX_OPTS -Dcom.sun.management.jmxremote.port=26052 ${POLICY} -Xmx{{ worker_heap }} -Xms128m"
test -z "$ACCUMULO_MONITOR_OPTS" && export ACCUMULO_MONITOR_OPTS="$MONITOR_DBG $JMX_OPTS -Dcom.sun.management.jmxremote.port=26053 ${POLICY} -Xmx{{ mgr_heap }} -Xms64m"
test -z "$ACCUMULO_GC_OPTS"      && export ACCUMULO_GC_OPTS="$GC_DBG $JMX_OPTS -Dcom.sun.management.jmxremote.port=26054 -Xmx{{ mgr_heap }} -Xms64m"
test -z "$ACCUMULO_GENERAL_OPTS" && export ACCUMULO_GENERAL_OPTS="-XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75"
test -z "$ACCUMULO_OTHER_OPTS"   && export ACCUMULO_OTHER_OPTS="-Xmx{{ worker_heap }} -Xms64m"
export ACCUMULO_LOG_HOST=`(grep -v '^#' {{ alt_config }}/monitor ; echo localhost ) 2>/dev/null | head -1`

{%- for line in acc_env_list %}
{{ line }}
{%- endfor %}

