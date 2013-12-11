include:
  - hadoop
  - hadoop.snappy

{%- if grains['os_family'] in ['RedHat'] %}
redhat-lsb-core:
  pkg.installed
{% endif %}

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
      - export PATH=$PATH:/usr/lib/accumulo/bin
      - export CONTINUOUS_CONF_DIR=/home/accumulo/

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

{{ accumulo.real_home }}:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group
