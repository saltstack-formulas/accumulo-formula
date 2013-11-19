include:
  - sun-java
  - zookeeper.server
  - hadoop.hdfs
  - accumulo

{%- if grains['os'] in ['CentOS'] %}
redhat-lsb-core:
  pkg.installed
{% endif %}

{%- set accumulo = salt['pillar.get']('accumulo', {}) %}
{%- set prefix   = accumulo.get('prefix', '/usr/lib/accumulo') %}
{%- set version  = accumulo.get('version', '1.5.0') %}
{%- set instance_name  = salt['pillar.get']('accumulo:config:instance_name', 'accumulo') %}
{%- set secret = salt['pillar.get']('accumulo:secret', '123456789') %}
{%- set alt_config = salt['pillar.get']('accumulo:config:directory', '/etc/accumulo/conf') %}
{%- set real_config = alt_config + '-' + version %}
{%- set alt_home  = salt['pillar.get']('accumulo:prefix', '/usr/lib/accumulo') %}
{%- set real_home = alt_home + '-' + version %}
{%- set real_config_src = real_home + '/conf' %}
{%- set real_config_dist = alt_config + '.dist' %}
{%- set hadoop_prefix  = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- set hadoop_version = salt['pillar.get']('hadoop:version', '1.2.1') %}
{%- set hadoop_major   = hadoop_version.split('.')|first() %}
{%- set zookeeper_prefix  = salt['pillar.get']('zookeeper:prefix', '/usr/lib/zookeeper') %}
{%- set namenode_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set zookeeper_host = namenode_host %}
{%- set accumulo_master = salt['mine.get']('roles:accumulo_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set accumulo_slaves = salt['mine.get']('roles:accumulo_slave', 'network.interfaces', 'grain').keys() %}
{%- set accumulo_default_loglevel = 'WARN' %}
{%- set accumulo_loglevels = ['DEBUG', 'INFO', 'WARN', 'ERROR'] %}
{%- set accumulo_ll = salt['pillar.get']('accumulo:config:loglevel', accumulo_default_loglevel) %}
{%- if accumulo_ll in accumulo_loglevels %}
{%- set accumulo_loglevel = accumulo_ll %}
{%- else %}
{%- set accumulo_loglevel = accumulo_default_loglevel %}
{%- endif %}
{%- set accumulo_default_profile = salt['grains.get']('accumulo_default_profile', '512MB') %}
{%- set accumulo_profile = salt['grains.get']('accumulo_profile', accumulo_default_profile) %}
{%- set accumulo_profile_dict = salt['pillar.get']('accumulo:config:accumulo-site-profiles:' + accumulo_profile, None) %}

{%- if hadoop_major == '1' %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hdfs' %}
{%- endif %}

/etc/accumulo:
  file.directory:
    - owner: root
    - group: root
    - mode: 755

{{ real_config }}:
  file.recurse:
    - source: salt://accumulo/conf
    - template: jinja
    - file_mode: 644
    - user: root
    - group: root
    - context:
      prefix: {{ alt_home }}
      java_home: {{ salt['pillar.get']('java_home', '/usr/lib/java') }}
      hadoop_prefix: {{ hadoop_prefix }}
      alt_config: {{ alt_config }}
      zookeeper_prefix: {{ zookeeper_prefix }}
      accumulo_logs: '/var/log/accumulo'
      namenode_host: {{ namenode_host }}
      zookeeper_host: {{ zookeeper_host }}
      hadoop_major: {{ hadoop_major }}
      accumulo_master: {{ accumulo_master }}
      accumulo_slaves: {{ accumulo_slaves }}
      accumulo_default_profile: {{ accumulo_default_profile }}
      accumulo_profile: {{ accumulo_profile }}
      accumulo_loglevel: {{ accumulo_loglevel }}

move-accumulo-dist-conf:
  cmd.run:
    - name: mv  {{ real_config_src }} {{ real_config_dist }}
    - unless: test -L {{ real_config_src }}
    - onlyif: test -d {{ real_config_src }}
    - require:
      - file.directory: {{ real_home }}
      - file.directory: /etc/accumulo

{{ real_config_src }}:
  file.symlink:
    - target: {{ alt_config }}
    - require:
      - cmd: move-accumulo-dist-conf

accumulo-conf-link:
  alternatives.install:
    - link: {{ alt_config }}
    - path: {{ real_config }}
    - priority: 30
    - require:
      - file.directory: {{ real_config }}

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
    - name: {{prefix}}/bin/accumulo init --instance-name {{ instance_name }} --password {{ salt['pillar.get']('accumulo:secret', '123456789') }} > /var/log/accumulo/accumulo-init.log
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
