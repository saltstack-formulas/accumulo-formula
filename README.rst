===
accumulo
===

Formula to set up and configure accumulo servers

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``accumulo``
-------

Downloads the accumulo tarball from the master (must exist as zookeeper/files/zookeeper-<version>.tar.gz), installs the package.

``accumulo.server``
--------------

Installs the server configuration and starts the accumulo master server.
Which services accumulo ends up running on a given host will depend on the hadoop-like text list files in the
configuration directory and - in turn - on the roles defined via salt grains:

- accumulo_master will run master, monitor and gc
- accumulo_slave will run tracer and tserver
