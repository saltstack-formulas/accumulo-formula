{% set p   = salt['pillar.get']('accumulo', {}) %}
{% set pc  = p.get('config', {}) %}
{% set g   = salt['grains.get']('accumulo', {}) %}
{% set gc  = g.get('config', {}) %}

{%- set userhome          = '/home/accumulo' %}
{%- set default_uid       = '6040' %}
{%- set default_version   = '1.6.1' %}
{%- set default_prefix    = '/usr/lib/accumulo' %}
{%- set default_instance_name = 'accumulo' %}
{%- set default_secret    = 'secret' %}
{%- set default_memory_profile = '512MB' %}
{%- set default_walogs    = '/var/lib/accumulo/walogs' %}
{%- set default_confdir   = '/etc/accumulo/conf' %}
{%- set default_worker_heap = '1024m' %}
{%- set default_mgr_heap    = '512m' %}
{%- set loglevels         = ['DEBUG', 'INFO', 'WARN', 'ERROR'] %}
{%- set default_log_root  = '/var/log/accumulo' %}
{%- set default_log_level = 'WARN' %}

{%- set uid            = g.get('uid', p.get('uid', default_uid)) %}
{%- set version        = g.get('version', p.get('version', default_version)) %}
{%- set prefix         = g.get('prefix', p.get('prefix', default_prefix)) %}
# pssh is needed for the continuous testsuite
# it is not available out of base or epel repos for redhat/centos
{%- set pssh_rpm_source_url = g.get('pssh_rpm_source_url', p.get('pssh_rpm_source_url', 'ftp://fr2.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/pssh-2.3-1.el6.rf.noarch.rpm')) %}
{%- set alt_home       = prefix %}

{%- set default_url    = 'http://www.us.apache.org/dist/accumulo/' + version + '/accumulo-' + version + '-bin.tar.gz' %}
{%- set source_url     = g.get('source_url', p.get('source_url', default_url)) %}

{%- set version_name   = 'accumulo-' + version %}
{%- set instance_name  = gc.get('instance_name', pc.get('instance_name', default_instance_name)) %}
{%- set secret         = gc.get('secret', pc.get('secret', default_secret)) %}
{%- set walogs         = gc.get('walogs', pc.get('walogs', default_walogs)) %}
{%- set memory_profile = gc.get('memory_profile', pc.get('memory_profile', default_memory_profile)) %}
{%- set worker_heap    = gc.get('worker_heap', pc.get('worker_heap', default_worker_heap)) %}
{%- set mgr_heap       = gc.get('mgr_heap', pc.get('mgr_heap', default_mgr_heap)) %}
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
{%- set java_home        = salt['grains.get']('java_home', salt['pillar.get']('java_home', '/usr/lib/java')) %}
{%- set env              = gc.get('accumulo-env', pc.get('accumulo-env', [])) %}

{%- set accumulo_master = salt['mine.get']('roles:accumulo_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set accumulo_slaves = salt['mine.get']('roles:accumulo_slave', 'network.interfaces', 'grain').keys() %}

# make tracer processes optional
{%- if gc.get('tracer_flag', pc.get('tracer_flag', True)) %}
{%- set accumulo_tracers = accumulo_master %}
{%- else %}
{%- set accumulo_tracers = '#' %}
{%- endif %}

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
                          'accumulo_tracers' : accumulo_tracers,
                          'default_log_root': default_log_root,
                          'log_root': log_root,
                          'log_level' : log_level,
                          'memory_profile' : memory_profile,
                          'sources': g.get('sources', p.get('sources', {})),
                          'worker_heap': worker_heap,
                          'mgr_heap': mgr_heap,
                          'pssh_rpm_source_url': pssh_rpm_source_url,
                          'accumulo_env': env,
                        }) %}
