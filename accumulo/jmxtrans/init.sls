{%- set all_roles    = salt['grains.get']('roles', []) %}

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

