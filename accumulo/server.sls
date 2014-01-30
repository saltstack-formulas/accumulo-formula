include:
  - zookeeper.server
  - hadoop.hdfs
  - accumulo.native

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if 'accumulo_master' in salt['grains.get']('roles', []) %}

{{ hdfs_mkdir('/accumulo',      'accumulo', None, 700, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user',          'hdfs',     None, 700, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user/accumulo', 'accumulo', None, 700, hadoop.dfs_cmd) }}

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
