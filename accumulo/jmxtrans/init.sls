{%- set all_roles    = salt['grains.get']('roles', []) %}
{%- if 'monitor' in all_roles %}

include:
  - jmxtrans

{%- set jsondir = '/etc/jmxtrans/json' %}

# TODO: add yarn support
{%- if 'accumulo_slave' in all_roles %}
{{jsondir}}/tserver.json:
  file.managed:
    - source: salt://accumulo/jmxtrans/tserver.json
    - template: jinja
{%- endif %}

{%- if 'accumulo_master' in all_roles %}
{{jsondir}}/master.json:
  file.managed:
    - source: salt://accumulo/jmxtrans/master.json
    - template: jinja
{%- endif %}

{%- if 'accumulo_master' in all_roles or 'accumulo_slave' in all_roles %}
restart-jmxtrans-for-accumulo:
  module.wait:
    - name: service.restart
    - m_name: jmxtrans
    - watch:
{%- if 'accumulo_master' in all_roles %}
      - file: {{ jsondir }}/master.json
{%- endif %}
{%- if 'accumulo_slave' in all_roles %}
      - file: {{ jsondir }}/tserver.json
{%- endif %}
{%- endif %}

{%- endif %}
