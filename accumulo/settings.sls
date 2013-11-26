{%- set default_uid = '6040' %}
{%- set userhome = '/home/accumulo' %}
{%- set uid = salt['pillar.get']('accumulo:uid', default_uid) %}
# the version and source can either come out of a grain, the pillar or end up the default (currently 1.5.0)
{%- set pillar_source      = salt['pillar.get']('accumulo:source', '') %}
{%- set pillar_source_hash = salt['pillar.get']('accumulo:source_hash', '') %}
{%- set pillar_version     = salt['pillar.get']('accumulo:version', '1.5.0') %}
{%- set version      = salt['grains.get']('accumulo_version', pillar_version) %}
{%- set source       = salt['grains.get']('accumulo_source', pillar_source) %}
{%- set source_hash  = salt['grains.get']('accumulo_source_hash', pillar_source_hash) %}
{%- set version_name = 'accumulo-' + version %}
{%- set prefix = salt['pillar.get']('accumulo:prefix', '/usr/lib/accumulo') %}
{%- set instance_name = salt['pillar.get']('accumulo:config:instance_name', 'accumulo') %}
{%- set secret = salt['pillar.get']('accumulo:secret', 'secret') %}
{%- set alt_config = salt['pillar.get']('accumulo:config:directory', '/etc/accumulo/conf') %}
{%- set real_config = alt_config + '-' + version %}
{%- set alt_home  = salt['pillar.get']('accumulo:prefix', '/usr/lib/accumulo') %}
{%- set real_home = alt_home + '-' + version %}
{%- set real_config_src = real_home + '/conf' %}
{%- set real_config_dist = alt_config + '.dist' %}
{%- set java_home = salt['pillar.get']('java_home', '/usr/lib/java') %}

{%- set zookeeper_prefix  = salt['pillar.get']('zookeeper:prefix', '/usr/lib/zookeeper') %}
{%- set accumulo_default_loglevel = 'WARN' %}
{%- set accumulo_loglevels = ['DEBUG', 'INFO', 'WARN', 'ERROR'] %}
{%- set accumulo_ll = salt['pillar.get']('accumulo:config:loglevel', accumulo_default_loglevel) %}
{%- if accumulo_ll in accumulo_loglevels %}
{%- set accumulo_loglevel = accumulo_ll %}
{%- else %}
{%- set accumulo_loglevel = accumulo_default_loglevel %}
{%- endif %}
{%- set accumulo_default_profile = salt['grains.get']('accumulo_default_profile', '512MB') %}
{%- set accumulo_profile = salt['grains.get']('accumulo_profile', accumulo_default_profile) %}
{%- set accumulo_profile_dict = salt['pillar.get']('accumulo:config:accumulo-site-profiles:' + accumulo_profile, None) %}

# TODO:
{%- set namenode_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set zookeeper_host = namenode_host %}
{%- set accumulo_master = salt['mine.get']('roles:accumulo_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set accumulo_slaves = salt['mine.get']('roles:accumulo_slave', 'network.interfaces', 'grain').keys() %}

{%- set accumulo = {} %}
{%- do accumulo.update( { 'uid': uid,
                          'version' : version,
                          'version_name': version_name,
                          'userhome' : userhome,
                          'sources': None,
                          'source': source,
                          'source_hash': source_hash,
                          'prefix' : prefix,
                          'instance_name': instance_name,
                          'secret': secret,
                          'alt_config' : alt_config,
                          'real_config' : real_config,
                          'alt_home' : alt_home,
                          'real_home' : real_home,
                          'real_config_src' : real_config_src,
                          'real_config_dist' : real_config_dist,
                          'java_home' : java_home,
                          'zookeeper_prefix' : zookeeper_prefix,
                          'namenode_host' : namenode_host,
                          'zookeeper_host' : zookeeper_host,
                          'accumulo_master' : accumulo_master,
                          'accumulo_slaves' : accumulo_slaves,
                          'accumulo_loglevel' : accumulo_loglevel,
                          'accumulo_default_profile' : accumulo_default_profile,
                          'accumulo_profile' : accumulo_profile
                        }) %}
