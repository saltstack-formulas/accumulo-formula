{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

{%- if 'accumulo_master' in all_roles %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-all.sh

{%- elif 'accumulo_slave' in salt['grains.get']('roles', []) %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-here.sh

{% endif %}
