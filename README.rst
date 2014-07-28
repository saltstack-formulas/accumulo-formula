========
accumulo
========

Formula to set up and configure accumulo servers

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``accumulo``
------------

Downloads the accumulo tarball from accumulo:source_url, installs the package.

``accumulo.server``
-------------------

Installs the server configuration, then initializes and starts the accumulo services.
Which services accumulo ends up running on a given host will depend on the hadoop-like text list files in the
configuration directory and - in turn - on the roles defined via salt grains:

- accumulo_master will run master, monitor and gc (tracer if also the development role exists)
- accumulo_slave will run a tablet server

``accumulo.proxy``
------------------

Runs a thrift proxy server on any node with the __accumulo_proxy__ role. Implies accumulo.

``accumulo.native``
-------------------

Install (compile when necessary) the native lib for accumulo. EXPERIMENTAL!

``accumulo.development.sources``
-------------------------------

Install a source tarball into the accumulo userhome. (see pillar.example)

``accumulo.development.testsuite``
----------------------------------

Make the continuous ingest system test suite available in the accumulo userhome, includes configuration.
