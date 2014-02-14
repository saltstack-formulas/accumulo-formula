{%- if grains['os_family'] in ['RedHat'] %}
redhat-lsb-core:
  pkg.installed
{% endif %}

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}

accumulo:
  group.present:
    - gid: {{ accumulo.uid }}
  user.present:
    - uid: {{ accumulo.uid }}
    - gid: {{ accumulo.uid }}
    - shell: /bin/bash
    - home: {{ accumulo.userhome }}
    - groups: ['hadoop']
  file.directory:
    - user: accumulo
    - group: accumulo
    - makedirs: True
    - names:
      - {{ accumulo.log_root }}
      - /var/run/accumulo
      - /var/lib/accumulo

{%- if accumulo.log_root != '/var/log/accumulo' %}
/var/log/accumulo:
  file.symlink:
    - target: {{ accumulo.log_root }}
{%- endif %}

{{ accumulo.userhome }}/.ssh:
  file.directory:
    - user: accumulo
    - group: accumulo
    - mode: 744

accumulo_private_key:
  file.managed:
    - name: {{ accumulo.userhome }}/.ssh/id_dsa
    - user: accumulo
    - group: accumulo
    - mode: 600
    - source: salt://accumulo/files/dsa-accumulo

accumulo_public_key:
  file.managed:
    - name: {{ accumulo.userhome }}/.ssh/id_dsa.pub
    - user: accumulo
    - group: accumulo
    - mode: 644
    - source: salt://accumulo/files/dsa-accumulo.pub

ssh_dss_accumulo:
  ssh_auth.present:
    - user: accumulo
    - source: salt://accumulo/files/dsa-accumulo.pub
    - require:
      - file.managed: accumulo_private_key

{{ accumulo.userhome }}/.ssh/config:
  file.managed:
    - source: salt://accumulo/files/ssh_config
    - user: accumulo
    - group: accumulo
    - mode: 644

{{ accumulo.userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/accumulo/bin
      - export CONTINUOUS_CONF_DIR=/home/accumulo/continuous_test

/etc/security/limits.d/98-accumulo.conf:
  file.managed:
    - mode: 644
    - user: root
    - contents: |
        accumulo soft nofile 65536
        accumulo hard nofile 65536
        accumulo soft nproc 8092
        accumulo hard nproc 8092

install-accumulo-dist:
  cmd.run:
    - name: curl '{{ accumulo.source_url }}' | tar xz
    - user: root
    - group: root
    - cwd: /usr/lib
    - unless: test -d {{ accumulo.alt_home }}

accumulo-home-link:
  alternatives.install:
    - link: {{ accumulo.alt_home }}
    - path: {{ accumulo.real_home }}
    - priority: 30
    - require:
      - cmd.run: install-accumulo-dist

{{ accumulo.real_home }}/lib/ext:
  file.directory:
    - user: root
    - group: root

{{ accumulo.real_home }}:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group

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
      namenode_host: {{ hdfs.namenode_host }}
      zookeeper_host: {{ zk.zookeeper_host }}
      zookeeper_port: {{ zk.port }}
      hadoop_major: {{ hadoop.major_version }}
      hadoop_version: {{ hadoop.dist_id }}
      hadoop_cdhmr1: {{ hadoop.cdhmr1 }}
      accumulo_master: {{ accumulo.accumulo_master }}
      accumulo_slaves: {{ accumulo.accumulo_slaves }}
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
