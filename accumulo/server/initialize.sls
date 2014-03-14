{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}
{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

{%- if 'accumulo_master' in all_roles %}

{{ hdfs_mkdir('/accumulo',      'accumulo', 'accumulo', 700, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user',          'hdfs',     None, 755, hadoop.dfs_cmd) }}
{{ hdfs_mkdir('/user/accumulo', 'accumulo', 'accumulo', 700, hadoop.dfs_cmd) }}

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

# fix accumulo permissions in hdfs

fix-accumulo-perms:
  cmd.run:
    - user: hdfs
    - names:
      - {{ hadoop.dfs_cmd }} -chown -R accumulo:accumulo /accumulo
      - {{ hadoop.dfs_cmd }} -chmod -R 700 /accumulo
      - {{ hadoop.dfs_cmd }} -chmod 750 /accumulo
      - {{ hadoop.dfs_cmd }} -chmod 750 /accumulo/crypto
      - {{ hadoop.dfs_cmd }} -chmod 750 /accumulo/instance_id
    - require:
      - cmd: init-accumulo

{%- endif %}
