include:
  - zookeeper.server
  - hadoop.hdfs
  - accumulo.native

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if 'accumulo_master' in salt['grains.get']('roles', []) %}

make-accumulo-dir:
  cmd.run:
    - user: hdfs
    - name: {{ hadoop.dfs_cmd }} -mkdir /accumulo
    - unless: {{ hadoop.dfs_cmd }} -stat /accumulo
    - require:
      - service: hdfs-services
      - service: zookeeper-service

set-accumulo-dir:
  cmd.wait:
    - user: hdfs
    - watch:
      - cmd: make-accumulo-dir
    - names:
      - {{ hadoop.dfs_cmd }} -chmod 700 /accumulo
      - {{ hadoop.dfs_cmd }} -chown accumulo /accumulo

make-user-dir:
  cmd.run:
    - user: hdfs
    - name: {{ hadoop.dfs_cmd }} -mkdir /user
    - unless: {{ hadoop.dfs_cmd }} -stat /user

make-accumulo-user-dir:
  cmd.wait:
    - user: hdfs
    - name: {{ hadoop.dfs_cmd }} -mkdir /user/accumulo
    - unless: {{ hadoop.dfs_cmd }} -stat /user/accumulo
    - watch:
      - cmd: make-user-dir

set-accumulo-user-dir:
  cmd.wait:
    - user: hdfs
    - watch:
      - cmd: make-accumulo-user-dir
    - names:
      - {{ hadoop.dfs_cmd }} -chmod 700 /user/accumulo
      - {{ hadoop.dfs_cmd }} -chown accumulo /user/accumulo

check-zookeeper:
  cmd.run:
    - name: {{ zk.prefix }}/bin/zkCli.sh ls / | tail -1 > /tmp/acc.status

init-accumulo:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/accumulo init --instance-name {{ accumulo.instance_name }} --password {{ accumulo.secret }} > {{ accumulo.log_root }}/accumulo-init.log
    - unless: grep -i accumulo /tmp/acc.status
    - env:
      - ACCUMULO_HOME: {{ accumulo.alt_home }}
      - HADOOP_PREFIX: {{ hadoop.alt_home }}
      - HADOOP_CONF_DIR: {{ hadoop.alt_config }}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-all.sh

{%- elif 'accumulo_slave' in salt['grains.get']('roles', []) %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-here.sh

{% endif %}
