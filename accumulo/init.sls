{%- set accumulo_user_defaults = {'accumulo':'6040'} %}
{%- set accumulo = pillar.get('accumulo', {}) %}
{%- set accumulo_users = accumulo.get('users', {}) %}

include:
  - hadoop.prereqs

{% for username, default_uid in accumulo_user_defaults.items() %}

{% set uid = accumulo_users.get(username, default_uid) %}
{% set userhome = '/home/' + username %}

{{ username }}:
  group.present:
    - gid: {{ uid }}
  user.present:
    - uid: {{ uid }}
    - gid: {{ uid }}
    - home: {{ userhome }}
    - groups: ['hadoop']
    - require:
      - group: hadoop
      - group: {{ username }}
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - names:
      - /var/log/{{ username }}
      - /var/run/{{ username }}
      - /var/lib/{{ username }}

{{ userhome }}/.ssh:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 744
    - require:
      - user: {{ username }}
      - group: {{ username }}

{{ username }}_private_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - source: salt://{{ username }}/files/dsa-{{ username }}
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ username }}_public_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa.pub
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - source: salt://{{ username }}/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

ssh_dss_{{ username }}:
  ssh_auth.present:
    - user: {{ username }}
    - source: salt://{{ username }}/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

{{ userhome }}/.ssh/config:
  file.managed:
    - source: salt://misc/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin:/usr/lib/accumulo

{% endfor %}
