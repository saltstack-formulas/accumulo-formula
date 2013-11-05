{%- set accumulo_user_defaults = {'accumulo':'6040'} %}
{%- set accumulo = salt['pillar.get']('accumulo', {}) %}
{%- set accumulo_users = accumulo.get('users', {}) %}
{%- set version = accumulo.get('version', '1.5.0') %}
{%- set version_name = 'accumulo-' + version %}
{%- set source       = accumulo.get('source', '') %}
{%- set source_hash  = accumulo.get('source_hash', '') %}
{%- set alt_home  = salt['pillar.get']('accumulo:prefix', '/usr/lib/accumulo') %}
{%- set real_home = alt_home + '-' + version %}
{%- set tgz = version_name + "-bin.tar.gz" %}
{%- set src_tgz = version_name + "-src.tar.gz" %}
{%- set tgz_path = '/tmp/' + tgz %}
{%- set alt_config = salt['pillar.get']('accumulo:config:directory', '/etc/accumulo/conf') %}
{%- set real_config = alt_config + '-' + version %}
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


include:
  - hadoop

{% for username, default_uid in accumulo_user_defaults.items() %}
{% set userhome = '/home/' + username %}

{% set uid = accumulo_users.get(username, default_uid) %}

{{ username }}:
  group.present:
    - gid: {{ uid }}
  user.present:
    - uid: {{ uid }}
    - gid: {{ uid }}
    - home: {{ userhome }}
    - groups: ['hadoop']
    - require:
      - group: hadoop
      - group: {{ username }}
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - names:
      - /var/log/{{ username }}
      - /var/run/{{ username }}
      - /var/lib/{{ username }}

{{ userhome }}/.ssh:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 744
    - require:
      - user: {{ username }}
      - group: {{ username }}

{{ username }}_private_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - source: salt://{{ username }}/files/dsa-{{ username }}
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ username }}_public_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa.pub
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - source: salt://{{ username }}/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

ssh_dss_{{ username }}:
  ssh_auth.present:
    - user: {{ username }}
    - source: salt://{{ username }}/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

{{ userhome }}/.ssh/config:
  file.managed:
    - source: salt://accumulo/conf/ssh/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin:/usr/lib/accumulo

{% endfor %}

{{ tgz_path }}:
  file.managed:
{%- if source %}
    - source: {{ source }}
    - source_hash: {{ source_hash }}
{%- else %}
    - source: salt://accumulo/files/{{ tgz }}
{%- endif %}

{%- set sources = accumulo.get('sources', None) %}
{%- if sources %}

/tmp/{{ src_tgz }}:
  file.managed:
{%- if source %}
    - source: {{ sources.get('source') }}
    - source_hash: {{ sources.get('source_hash') }}
{%- else %}
    - source: salt://accumulo/files/{{ tgz }}
{%- endif %}

unpack-sources:
  cmd.wait:
    - name: tar xzf /tmp/{{ src_tgz }}
    - cwd: /usr/lib
    - unless: test -f {{ real_home }}/examples/pom.xml
    - user: root
    - watch:
      - file: /tmp/{{ src_tgz }}

unpack-sources-to-userhome:
  cmd.wait:
    - name: tar xzf /tmp/{{ src_tgz }}
    - cwd: /home/accumulo
    - user: accumulo
    - watch:
      - file: /tmp/{{ src_tgz }}

{%- endif %}

install-accumulo-dist:
  cmd.run:
    - name: tar xzf {{ tgz_path }}
    - cwd: /usr/lib
    - unless: test -f {{ real_home }}/lib/accumulo-server.jar
    - require:
      - file.managed: {{ tgz_path }}
  alternatives.install:
    - name: accumulo-home-link
    - link: {{ alt_home }}
    - path: {{ real_home }}
    - priority: 30
    - require:
      - cmd.run: install-accumulo-dist

{{ real_home }}:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group


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
      java_home: {{ salt['pillar.get']('java_home', '/usr/java/default') }}
      hadoop_prefix: {{ hadoop_prefix }}
      alt_config: {{ alt_config }}
      zookeeper_prefix: {{ zookeeper_prefix }}
      accumulo_logs: '/var/log/accumulo'
      namenode_host: {{ namenode_host }}
      zookeeper_host: {{ zookeeper_host }}
      hadoop_major: {{ hadoop_major }}
      accumulo_master: {{ accumulo_master }}
      accumulo_slaves: {{ accumulo_slaves }}

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
