include:
  - hadoop

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
{%- set tgz_path = salt['pillar.get']('downloads_path', '/tmp') + '/' + tgz %}


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

/tmp/hadoop-snappy-0.0.1.tgz:
  file.managed:
    - source: salt://accumulo/libs/hadoop-snappy-0.0.1.tgz

{%- if 'development' in salt['grains.get']('roles', []) %}
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

{%- set test_suite_home = '/home/accumulo/continuous_test' %}
copy-testsuite:
  cmd.run:
    - user: accumulo
    - name: cp -r /home/accumulo/{{ version_name }}/test/system/continuous {{ test_suite_home }}
    - unless: test -d {{ test_suite_home }}

{%- endif %}
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
  cmd.run:
    - name: tar xzf /tmp/hadoop-snappy-0.0.1.tgz
    - cwd: /usr/lib/hadoop
    - unless: test -f /usr/lib/hadoop/lib/hadoop-snappy-0.0.1-SNAPSHOT.jar
    - require:
      - file.managed: /tmp/hadoop-snappy-0.0.1.tgz
      - alternatives.install: hadoop-home-link

snappy-libs:
  pkg.installed:
    - names:
      - snappy
      - snappy-devel

{{ real_home }}:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group
