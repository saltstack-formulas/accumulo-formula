include:
  - sun-java
  - zookeeper.server
  - hadoop.hdfs
  - accumulo.native

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}

/etc/accumulo:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{{ accumulo.real_config }}:
  file.recurse:
    - source: salt://accumulo/conf
    - template: jinja
    - file_mode: 644
    - user: root
    - group: root
    - context:
      prefix: {{ accumulo.prefix }}
      java_home: {{ accumulo.java_home }}
      accumulo_local: '/var/lib/accumulo'
      hadoop_prefix: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}
      alt_config: {{ accumulo.alt_config }}
      zookeeper_prefix: {{ zk.prefix }}
      accumulo_walogs: {{ accumulo.walogs }}
      accumulo_logs: {{ accumulo.log_root }}
      accumulo_loglevel: {{ accumulo.log_level }}
      namenode_host: {{ accumulo.namenode_host }}
      zookeeper_host: {{ zk.zookeeper_host }}
      zookeeper_port: {{ zk.port }}
      hadoop_major: {{ hadoop.major_version }}
      hadoop_version: {{ hadoop.dist_id }}
      accumulo_master: {{ accumulo.accumulo_master }}
      accumulo_slaves: {{ accumulo.accumulo_slaves }}
      default_memory_profile: {{ accumulo.default_memory_profile }}
      memory_profile: {{ accumulo.memory_profile }}
      secret: {{ accumulo.secret }}

move-accumulo-dist-conf:
  cmd.run:
    - name: mv  {{ accumulo.real_config_src }} {{ accumulo.real_config_dist }}
    - unless: test -L {{ accumulo.real_config_src }}
    - onlyif: test -d {{ accumulo.real_config_src }}
    - require:
      - file.directory: {{ accumulo.real_home }}
      - file.directory: /etc/accumulo

{{ accumulo.real_config_src }}:
  file.symlink:
    - target: {{ accumulo.alt_config }}
    - require:
      - cmd: move-accumulo-dist-conf

accumulo-conf-link:
  alternatives.install:
    - link: {{ accumulo.alt_config }}
    - path: {{ accumulo.real_config }}
    - priority: 30
    - require:
      - file.directory: {{ accumulo.real_config }}

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
