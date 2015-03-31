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
  file.directory:
    - user: accumulo
    - group: accumulo
    - makedirs: True
    - names:
      - /var/run/accumulo
      - /var/lib/accumulo

# if this is used instead of the groups user attribute, consecutive formulas can add groups
make-accumulo-a-hadoop-user:
  cmd.run:
    - name: usermod -G hadoop accumulo
    - unless: id accumulo | grep hadoop

# even if we end up using an alternative log path it would be nice to point to it from the default location
{%- if accumulo.log_root != accumulo.default_log_root %}
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
      - file: accumulo_private_key

{{ accumulo.userhome }}/.ssh/config:
  file.managed:
    - source: salt://accumulo/files/ssh_config
    - user: accumulo
    - group: accumulo
    - mode: 644

{{ accumulo.userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:{{ accumulo.alt_home }}/bin:{{ hadoop.alt_home }}/bin:{{ zk.alt_home }}/bin
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
  file.directory:
    - name: {{ accumulo.real_home }}
    - user: root
    - group: root
  cmd.run:
    - name: curl '{{ accumulo.source_url }}' | tar xz --no-same-owner --strip-components=1
    - user: root
    - group: root
    - cwd: {{ accumulo.real_home }}
    - unless: test -d {{ accumulo.real_home }}/lib

accumulo-home-link:
  alternatives.install:
    - link: {{ accumulo.alt_home }}
    - path: {{ accumulo.real_home }}
    - priority: 30
    - require:
      - cmd: install-accumulo-dist

{{ accumulo.real_home }}/lib/ext:
  file.directory:
    - user: root
    - group: root

{{ accumulo.real_config }}:
  file.directory:
    - user: root
    - group: root
    - makedirs: True

/etc/accumulo:
  file.directory:
    - user: root
    - group: root
    - mode: 755

move-accumulo-dist-conf:
  cmd.run:
    - name: mv  {{ accumulo.real_config_src }} {{ accumulo.real_config_dist }}
    - unless: test -L {{ accumulo.real_config_src }}
    - onlyif: test -d {{ accumulo.real_config_src }}

{{ accumulo.real_config_src }}:
  file.symlink:
    - target: {{ accumulo.alt_config }}

accumulo-conf-link:
  alternatives.install:
    - link: {{ accumulo.alt_config }}
    - path: {{ accumulo.real_config }}
    - priority: 30
    - require:
      - file: {{ accumulo.real_config }}

{{ accumulo.alt_config }}:
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
      zookeeper_home: {{ zk.alt_home }}
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
      accumulo_tracers: {{ accumulo.accumulo_tracers }}
      memory_profile: {{ accumulo.memory_profile }}
      secret: {{ accumulo.secret }}
      manual_worker_heap: {{ accumulo.worker_heap }}
      manual_mgr_heap: {{ accumulo.mgr_heap }}
      acc_env_list: {{ accumulo.accumulo_env }}

set-accumulo-logdir-permissions:
  file.directory:
    - name: {{ accumulo.log_root }}
    - user: accumulo
    - group: accumulo
    - makedirs: True

# replace any existing logdir (which would belong to root) if necessary
{{ accumulo.real_home }}/logs:
  file.symlink:
    - target: /var/log/accumulo
    - force: true
