include:
  - accumulo

{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- set pillar_source_url = salt['pillar.get']('accumulo:native:source_url', 'no-native-source_url') %}
{%- set source_url = salt['grains.get']('accumulo:native:source_url', pillar_source_url) %}
{%- set pillar_version_name = salt['pillar.get']('accumulo:native:version_name', None) %}
{%- set version_name = salt['grains.get']('accumulo:native:version_name', pillar_version_name) %}
{%- if source_url != 'no-native-source_url' %}
# currently expects the accumulo-native package

{%- set native_dir = '/tmp/' + version_name %}
{%- set lib_name = 'libaccumulo.so' %}
{%- set lib_source = native_dir + '/' + lib_name %}
{%- set native_libdir = accumulo.alt_home + '/lib/native' %}
{%- set lib_target = native_libdir + '/' + lib_name %}

{{ native_libdir }}:
  file.directory:
    - user: root
    - group: root
    - makedirs: True

install-accumulo-native-dist:
  cmd.run:
    - name: curl '{{ source_url }}' | tar xz
    - cwd: /tmp
    - unless: test -f {{ lib_target }}

compile-accumulo-native-dist:
  cmd.wait:
    - name: make
    - cwd: {{ native_dir }}
    - env:
      - JAVA_HOME: {{ accumulo.java_home }}
      - PATH: {{ accumulo.java_home }}/bin:/usr/bin:/bin:/usr/sbin
    - watch:
      - cmd: install-accumulo-native-dist
    - unless: test -f {{ lib_source }}

copy-accumulo-native-lib:
  cmd.wait:
    - user: root
    - name: cp {{ lib_source }} {{ lib_target }}
    - watch:
      - cmd: compile-accumulo-native-dist

{%- endif %}