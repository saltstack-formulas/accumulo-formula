include:
  - hadoop
  - hadoop.snappy

{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- set tgz = accumulo.version_name + "-bin.tar.gz" %}
{%- set tgz_path = salt['pillar.get']('downloads_path', '/tmp') + '/' + tgz %}

accumulo:
  group.present:
    - gid: {{ accumulo.uid }}
  user.present:
    - uid: {{ accumulo.uid }}
    - gid: {{ accumulo.uid }}
    - home: {{ accumulo.userhome }}
    - groups: ['hadoop']
    - require:
      - group: hadoop
      - group: accumulo
  file.directory:
    - user: accumulo
    - group: accumulo
    - names:
      - /var/log/accumulo
      - /var/run/accumulo
      - /var/lib/accumulo

{{ accumulo.userhome }}/.ssh:
  file.directory:
    - user: accumulo
    - group: accumulo
    - mode: 744
    - require:
      - user: accumulo
      - group: accumulo

accumulo_private_key:
  file.managed:
    - name: {{ accumulo.userhome }}/.ssh/id_dsa
    - user: accumulo
    - group: accumulo
    - mode: 600
    - source: salt://accumulo/files/dsa-accumulo
    - require:
      - file.directory: {{ accumulo.userhome }}/.ssh

accumulo_public_key:
  file.managed:
    - name: {{ accumulo.userhome }}/.ssh/id_dsa.pub
    - user: accumulo
    - group: accumulo
    - mode: 644
    - source: salt://accumulo/files/dsa-accumulo.pub
    - require:
      - file.managed: accumulo_private_key

ssh_dss_accumulo:
  ssh_auth.present:
    - user: accumulo
    - source: salt://accumulo/files/dsa-accumulo.pub
    - require:
      - file.managed: accumulo_private_key

{{ accumulo.userhome }}/.ssh/config:
  file.managed:
    - source: salt://accumulo/conf/ssh/ssh_config
    - user: accumulo
    - group: accumulo
    - mode: 644
    - require:
      - file.directory: {{ accumulo.userhome }}/.ssh

{{ accumulo.userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin:/usr/lib/accumulo/bin

{{ tgz_path }}:
  file.managed:
{%- if accumulo.source %}
    - source: {{ accumulo.source }}
    - source_hash: {{ accumulo.source_hash }}
{%- else %}
    - source: salt://accumulo/files/{{ tgz }}
{%- endif %}

install-accumulo-dist:
  cmd.run:
    - name: tar xzf {{ tgz_path }}
    - cwd: /usr/lib
    - unless: test -f {{ accumulo.real_home }}/lib/accumulo-server.jar
    - require:
      - file.managed: {{ tgz_path }}
  alternatives.install:
    - name: accumulo-home-link
    - link: {{ accumulo.alt_home }}
    - path: {{ accumulo.real_home }}
    - priority: 30
    - require:
      - cmd.run: install-accumulo-dist

{{ accumulo.real_home }}:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group
