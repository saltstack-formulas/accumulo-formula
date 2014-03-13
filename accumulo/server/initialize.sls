{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}
{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

{%- if 'accumulo_master' in all_roles %}

{{ hdfs_mkdir('/accumulo',      'accumulo', None, 700, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user',          'hdfs',     None, 755, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user/accumulo', 'accumulo', None, 700, hadoop.dfs_cmd) }}

check-zookeeper:
  cmd.run:
    - name: {{ zk.prefix }}/bin/zkCli.sh -server {{ zk.zookeeper_host }}:{{zk.port}} ls / | tail -1 > /tmp/acc.status
    - env:
      - JAVA_HOME: {{ accumulo.java_home }}

init-accumulo:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/accumulo init --instance-name {{ accumulo.instance_name }} --password {{ accumulo.secret }} > {{ accumulo.log_root }}/accumulo-init.log
    - unless: grep -i accumulo /tmp/acc.status
    - env:
      - ACCUMULO_HOME: {{ accumulo.alt_home }}
      - HADOOP_PREFIX: {{ hadoop.alt_home }}
      - HADOOP_CONF_DIR: {{ hadoop.alt_config }}

{%- endif %}
