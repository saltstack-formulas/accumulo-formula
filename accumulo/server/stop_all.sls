{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- set all_roles    = salt['grains.get']('roles', []) %}
{%- if 'accumulo_master' in all_roles %}

stop-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/stop-all.sh

{% endif %}
