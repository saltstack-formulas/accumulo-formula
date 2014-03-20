{%- from 'accumulo/settings.sls' import accumulo with context %}
{%- from 'hadoop/settings.sls' import hadoop with context %}

{%- set all_roles    = salt['grains.get']('roles', []) %}

{%- if 'accumulo_master' in all_roles %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-all.sh

# continuously fix accumulo permissions in hdfs

fix-accumulo-perms:
  cmd.run:
    - user: hdfs
    - names:
      - {{ hadoop.dfs_cmd }} -chown -R accumulo:accumulo /accumulo
      - {{ hadoop.dfs_cmd }} -chmod 755 /accumulo
      - {{ hadoop.dfs_cmd }} -chmod 755 /accumulo/version
      - {{ hadoop.dfs_cmd }} -chmod 755 /accumulo/instance_id
      - {{ hadoop.dfs_cmd }} -chmod 750 /accumulo/crypto
      - {{ hadoop.dfs_cmd }} -chmod -R 700 /accumulo/tables

{%- elif 'accumulo_slave' in salt['grains.get']('roles', []) %}

start-all:
  cmd.run:
    - user: accumulo
    - name: {{accumulo.prefix}}/bin/start-here.sh

{% endif %}
