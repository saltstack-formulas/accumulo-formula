#!/bin/bash

[ $(id -un) != hdfs ] && echo "Must execute as the hdfs user" && exit 1

{{ dfs_command }} -mkdir /usr
{{ dfs_command }} -mkdir /usr/lib
{{ dfs_command }} -mkdir /usr/lib/zookeeper
{{ dfs_command }} -mkdir /usr/lib/accumulo
{{ dfs_command }} -mkdir /usr/lib/accumulo/lib

for jar in $(ls -1 /usr/lib/accumulo/lib/*jar /usr/lib/zookeeper/zookeeper-*.jar)
do
  {{ dfs_command }} -put $jar $jar
done
