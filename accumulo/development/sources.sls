{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if accumulo.sources.source_url is defined %}

install-accumulo-src-dist:
  cmd.run:
    - name: curl '{{ accumulo.sources.source_url }}' | tar xz
    - cwd: {{ accumulo.userhome }}
    - user: accumulo
    - unless: test -d {{ accumulo.userhome + '/' + accumulo.sources.version_name }}

{%- endif %}

