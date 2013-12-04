{%- if 'accumulo_proxy' in salt['grains.get']('roles', []) %}

include:
  - accumulo

{%- from 'accumulo/settings.sls' import accumulo with context %}

{{ accumulo.alt_config }}/proxy.properties:
  file.managed:
    - source: salt://accumulo/proxy/proxy.properties
    - template: jinja
    - mode: '644'
    - user: root
    - group: root
    - context:
      accumulo_instance: {{ accumulo.instance_name }}
      zookeeper_host: {{ accumulo.zookeeper_host }}
      proxy_port: 50096
      proxy_max_framesize: 16M

/etc/init.d/accumulo-proxy:
  file.managed:
    - source: salt://accumulo/proxy/accumulo-proxy.init.d
    - template: jinja
    - mode: 755
    - user: root
    - group: root
    - context:
      accumulo_config: {{ accumulo.alt_config }}
      accumulo_prefix: {{ accumulo.alt_home }}

accumulo-proxy:
  service:
    - running
    - enable: True

{%- endif %}