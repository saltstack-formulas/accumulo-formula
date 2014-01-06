include:
  - accumulo

{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- set pillar_source_url = salt['pillar.get']('accumulo:native:source_url', 'no-native-source_url') %}
{%- set source_url = salt['grains.get']('accumulo:native:source_url', pillar_source_url) %}
{%- set pillar_version_name = salt['pillar.get']('accumulo:native:version_name', None) %}
{%- set version_name = salt['grains.get']('accumulo:native:version_name', pillar_version_name) %}

# there is no default accumulo:native:source_url
{%- if source_url != 'no-native-source_url' %}

# This is right now only meant to help with 1.6 packages of accumulo, the state
# currently expects the accumulo-native (maven) package for 1.6
# 1.5- should be less critical as it comes packaged with a native lib
# please add an issue at https://github.com/accumulo/accumulo-formula/issues
# keep in mind that the location and the name of the lib have changed from 1.5 to 1.6

{%- set native_dir            = '/tmp/' + version_name %}
{%- set native_source_dir     = native_dir + '/src/main/c++/nativeMap' %}
{%- set lib_name              = 'libaccumulo.so' %}
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
    - unless:
      - test -f {{ lib_target }}
      - test -f {{ accumulo.prefix }}/lib/native/map/libNativeMap-Linux-amd64-64.so

compile-accumulo-native-dist:
  cmd.wait:
    - name: make clean all
    - cwd: {{ native_dir }}
    - env:
      - JAVA_HOME: {{ accumulo.java_home }}
      - PATH: {{ accumulo.java_home }}/bin:/usr/bin:/bin:/usr/sbin
    - watch:
      - cmd: install-accumulo-native-dist
    - unless: test -f {{ lib_source }}
    - onlyif: test -f {{ native_source_dir }}/Makefile

copy-accumulo-native-lib:
  cmd.wait:
    - user: root
    - name: cp {{ lib_source }} {{ lib_target }}
    - watch:
      - cmd: compile-accumulo-native-dist
    - onlyif: test -f {{ lib_source }}

{%- endif %}