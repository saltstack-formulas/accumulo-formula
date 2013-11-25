include:
  - sun-java
  - zookeeper.server
  - hadoop.hdfs
  - accumulo

{%- if grains['os'] in ['CentOS'] %}
redhat-lsb-core:
  pkg.installed
{% endif %}

{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- set test_suite_home = '/home/accumulo/continuous_test' %}
{%- if accumulo.hadoop_major == '1' %}
{%- set dfs_cmd = accumulo.hadoop_prefix + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = accumulo.hadoop_prefix + '/bin/hdfs dfs' %}
{%- endif %}

/etc/accumulo:
  file.directory:
    - owner: root
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
      hadoop_prefix: {{ accumulo.hadoop_prefix }}
      alt_config: {{ accumulo.alt_config }}
      zookeeper_prefix: {{ accumulo.zookeeper_prefix }}
      accumulo_logs: '/var/log/accumulo'
      namenode_host: {{ accumulo.namenode_host }}
      zookeeper_host: {{ accumulo.zookeeper_host }}
      hadoop_major: {{ accumulo.hadoop_major }}
      accumulo_master: {{ accumulo.accumulo_master }}
      accumulo_slaves: {{ accumulo.accumulo_slaves }}
      accumulo_default_profile: {{ accumulo.accumulo_default_profile }}
      accumulo_profile: {{ accumulo.accumulo_profile }}
      accumulo_loglevel: {{ accumulo.accumulo_loglevel }}
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
    - name: {{ accumulo.zookeeper_prefix }}/bin/zkCli.sh ls / | tail -1 > /tmp/acc.status

init-accumulo:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/accumulo init --instance-name {{ accumulo.instance_name }} --password {{ accumulo.secret }} > /var/log/accumulo/accumulo-init.log
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
