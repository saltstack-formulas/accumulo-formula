{%- from 'accumulo/settings.sls' import accumulo with context %}

{%- if grains['os_family'] == 'RedHat' %}
'gcc-c++':
  pkg.installed
{%- elif grains['os_family'] == 'Debian' %}
'g++':
  pkg.installed
{%- endif %}

compile-accumulo-native-lib:
  cmd.run:
    - name: ./build_native_library.sh
    - cwd: {{ accumulo.prefix }}/bin
    - shell: /bin/bash
    - onlyif: test -x {{ accumulo.prefix }}/bin/build_native_library.sh
    - unless: test -f {{ accumulo.prefix }}/lib/native/libaccumulo.so
    - env:
      - JAVA_HOME: {{ accumulo.java_home }}
      - PATH: /bin:/usr/bin:{{ accumulo.java_home }}/bin
