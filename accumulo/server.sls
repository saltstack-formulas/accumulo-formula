include:
  - zookeeper.server
  - hadoop.hdfs
  - accumulo

{%- if grains['os'] in ['CentOS'] %}
redhat-lsb-core:
  pkg.installed
{% endif %}

{%- set prefix  = salt['pillar.get']('accumulo:prefix', '/usr/lib/accumulo') %}
{%- set hadoop_prefix  = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- set zookeeper_prefix  = salt['pillar.get']('zookeeper:prefix', '/usr/lib/zookeeper') %}
{%- set hadoop_version = salt['pillar.get']('hadoop:version', '1.2.1') %}
{%- set hadoop_major   = hadoop_version.split('.')|first() %}

{%- if hadoop_major == '1' %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hdfs' %}
{%- endif %}

{%- if 'accumulo_master' in salt['grains.get']('roles', []) %}

make-accumulo-dir:
  cmd.run:
    - user: hdfs
    - name: {{ dfs_cmd }} -mkdir /accumulo
    - unless: {{ dfs_cmd }} -stat /accumulo
    - require:
      - service: hdfs-services
      - service: zookeeper

set-accumulo-dir:
  cmd.wait:
    - user: hdfs
    - watch:
      - cmd: make-accumulo-dir
    - names:
      - {{ dfs_cmd }} -chmod 700 /accumulo
      - {{ dfs_cmd }} -chown accumulo /accumulo

make-user-dir:
  cmd.run:
    - user: hdfs
    - name: {{ dfs_cmd }} -mkdir /user
    - unless: {{ dfs_cmd }} -stat /user

make-accumulo-user-dir:
  cmd.wait:
    - user: hdfs
    - name: {{ dfs_cmd }} -mkdir /user/accumulo
    - unless: {{ dfs_cmd }} -stat /user/accumulo
    - watch:
      - cmd: make-user-dir

set-accumulo-user-dir:
  cmd.wait:
    - user: hdfs
    - watch:
      - cmd: make-accumulo-user-dir
    - names:
      - {{ dfs_cmd }} -chmod 700 /user/accumulo
      - {{ dfs_cmd }} -chown accumulo /user/accumulo

check-zookeeper:
  cmd.run:
    - name: {{ zookeeper_prefix }}/bin/zkCli.sh ls / | tail -1 > /tmp/acc.status

init-accumulo:
  cmd.run:
    - user: accumulo
    - name: {{prefix}}/bin/accumulo init --instance-name accumulo --password {{ salt['pillar.get']('accumulo:secret', '123456789') }} > /var/log/accumulo/accumulo-init.log
    - unless: grep -i accumulo /tmp/acc.status

start-all:
  cmd.run:
    - user: accumulo
    - name: {{prefix}}/bin/start-all.sh

{%- elif 'accumulo_slave' in salt['grains.get']('roles', []) %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{prefix}}/bin/start-here.sh

{% endif %}