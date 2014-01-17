{% set p  = salt['pillar.get']('accumulo', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('accumulo', {}) %}
{% set gc = g.get('config', {}) %}

{%- set userhome          = '/home/accumulo' %}
{%- set default_uid       = '6040' %}
{%- set default_version   = '1.5.0' %}
{%- set default_prefix    = '/usr/lib/accumulo' %}
{%- set default_instance_name = 'accumulo' %}
{%- set default_secret    = 'secret' %}
{%- set default_memory_profile = '512MB' %}
{%- set default_walogs    = '/var/lib/accumulo/walogs' %}
{%- set default_confdir   = '/etc/accumulo/conf' %}
{%- set loglevels         = ['DEBUG', 'INFO', 'WARN', 'ERROR'] %}
{%- set default_log_root  = '/var/log/accumulo' %}
{%- set default_log_level = 'WARN' %}

{%- set uid            = g.get('uid', p.get('uid', default_uid)) %}
{%- set version        = g.get('version', p.get('version', default_version)) %}
{%- set prefix         = g.get('prefix', p.get('prefix', default_prefix)) %}
{%- set alt_home       = prefix %}

{%- set default_url    = 'http://www.us.apache.org/dist/accumulo/' + version + '/accumulo-' + version + '-bin.tar.gz' %}
{%- set source_url     = g.get('source_url', p.get('source_url', default_url)) %}

{%- set version_name   = 'accumulo-' + version %}
{%- set instance_name  = gc.get('instance_name', pc.get('instance_name', default_instance_name)) %}
{%- set secret         = gc.get('secret', pc.get('secret', default_secret)) %}
{%- set walogs         = gc.get('walogs', pc.get('walogs', default_walogs)) %}
{%- set memory_profile = gc.get('memory_profile', pc.get('memory_profile', default_memory_profile)) %}
{%- set alt_config     = gc.get('directory', pc.get('directory', default_confdir)) %}
{%- set log_root       = gc.get('log_root', pc.get('log_root', default_log_root)) %}
{%- set ll             = gc.get('log_level', pc.get('log_level', default_log_level)) %}

{%- if ll in loglevels %}
{%- set log_level = ll %}
{%- else %}
{%- set log_level = default_log_level %}
{%- endif %}

{%- set real_config      = alt_config + '-' + version %}
{%- set real_home        = alt_home + '-' + version %}
{%- set real_config_src  = real_home + '/conf' %}
{%- set real_config_dist = alt_config + '.dist' %}
{%- set java_home        = salt['pillar.get']('java_home', '/usr/lib/java') %}

{%- set accumulo_master = salt['mine.get']('roles:accumulo_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set accumulo_slaves = salt['mine.get']('roles:accumulo_slave', 'network.interfaces', 'grain').keys() %}

{%- set accumulo = {} %}
{%- do accumulo.update( { 'uid': uid,
                          'version' : version,
                          'version_name': version_name,
                          'userhome' : userhome,
                          'source_url': source_url,
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
                          'walogs': walogs,
                          'accumulo_master' : accumulo_master,
                          'accumulo_slaves' : accumulo_slaves,
                          'log_root': log_root,
                          'log_level' : log_level,
                          'memory_profile' : memory_profile,
                          'sources': g.get('sources', p.get('sources', {})),
                        }) %}
