include:
  - accumulo

{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if accumulo.sources.source_url is defined %}

install-accumulo-src-dist:
  cmd.run:
    - name: curl '{{ accumulo.sources.source_url }}' | tar xz
    - cwd: {{ accumulo.user_home }}
    - user: accumulo
    - unless: test -d {{ accumulo.user_home + '/' + accumulo.sources.version_name }}

{%- endif %}

