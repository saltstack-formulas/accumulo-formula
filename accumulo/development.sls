include:
  - accumulo

{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- set test_suite_home = '/home/accumulo/continuous_test' %}

{%- if accumulo.sources %}

{%- set src_tgz = accumulo.sources.get('tgz', '') %}
{%- set src_tgz_path = salt['pillar.get']('downloads_path', '/tmp') + '/' + src_tgz %}

/tmp/{{ src_tgz }}:
  file.managed:
{%- if accumulo.sources %}
    - source: {{ accumulo.sources.get('source') }}
    - source_hash: {{ accumulo.sources.get('source_hash') }}
{%- else %}
    - source: salt://accumulo/files/{{ src_tgz }}
{%- endif %}

unpack-sources-to-userhome:
  cmd.wait:
    - name: tar xzf /tmp/{{ src_tgz }}
    - cwd: /home/accumulo
    - user: accumulo
    - watch:
      - file: /tmp/{{ src_tgz }}

{%- endif %}

copy-testsuite:
  cmd.run:
    - user: accumulo
    - name: cp -r {{ accumulo.prefix }}/test/system/continuous {{ test_suite_home }}
    - unless: test -d {{ test_suite_home }}

{{ test_suite_home }}/continuous-env.sh:
  file.managed:
    - user: accumulo
    - source: salt://accumulo/testconf/continuous-env.sh
    - template: jinja
    - context:
      accumulo_prefix: {{ accumulo.prefix }}
      hadoop_prefix: {{ accumulo.hadoop_prefix }}
      zookeeper_prefix: {{ accumulo.zookeeper_prefix }}
      java_home: {{ accumulo.java_home }}
      instance_name: {{ accumulo.instance_name }}
      zookeeper_host: {{ accumulo.zookeeper_host }}
      secret: {{ accumulo.secret }}

{{ test_suite_home }}/ingesters.txt:
  file.managed:
    - user: accumulo
    - contents: {{ accumulo.accumulo_master }}

{%- if grains['os'] == 'Amazon' %}
pssh:
  pkg.installed
{%- endif %}
