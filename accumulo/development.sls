include:
  - accumulo

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if accumulo.sources.source_url %}

install-accumulo-src-dist:
  cmd.run:
    - name: curl '{{ accumulo.sources.source_url }}' | tar xz
    - cwd: {{ accumulo.user_home }}
    - user: accumulo
    - unless: test -d {{ accumulo.user_home + '/' + accumulo.sources.version_name }}

{%- endif %}

{%- set test_suite_logroot = accumulo.log_root + '/continuous_test' %}
{%- set test_suite_home    = '/home/accumulo/continuous_test' %}

copy-testsuite:
  cmd.run:
    - user: accumulo
    - name: cp -r {{ accumulo.prefix }}/test/system/continuous {{ accumulo.test_suite_home }}
    - unless: test -d {{ accumulo.test_suite_home }}

{{ accumulo.test_suite_logroot }}:
  file.directory:
    - user: accumulo
    - group: accumulo

{{ accumulo.test_suite_home }}/logs:
  file.symlink:
    - target: {{ accumulo.test_suite_logroot }}

{{ accumulo.test_suite_home }}/continuous-env.sh:
  file.managed:
    - user: accumulo
    - source: salt://accumulo/testconf/continuous-env.sh
    - template: jinja
    - context:
      accumulo_prefix: {{ accumulo.prefix }}
      hadoop_prefix: {{ hadoop.alt_home }}
      zookeeper_prefix: {{ zk.prefix }}
      java_home: {{ accumulo.java_home }}
      instance_name: {{ accumulo.instance_name }}
      zookeeper_host: {{ zk.zookeeper_host }}
      accumulo_log_root: {{ accumulo.log_root }}
      secret: {{ accumulo.secret }}

{{ accumulo.test_suite_home }}/ingesters.txt:
  file.managed:
    - user: accumulo
    - contents: {{ accumulo.accumulo_master }}

{%- if grains['os'] in ['Amazon', 'Ubuntu'] %}
pssh:
  pkg.installed
{%- endif %}

{%- if grains['os'] in ['Ubuntu'] %}
/usr/local/bin/pssh:
  file.symlink:
    - target: /usr/bin/parallel-ssh
    - require:
      - pkg: pssh
{%- endif %}

