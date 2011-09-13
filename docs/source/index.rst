.. vixDiskLib documentation master file, created by
   sphinx-quickstart on Mon Aug  1 11:51:05 2011.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.
   
.. _vixDiskLib:

vixDiskLib wrapper in Python
============================

:mod:`vixDiskLib` is a python wrapper to access the `VMware Virtual Disk Development Kit API <http://communities.vmware.com/community/developer/forums/vddk>`_.

Features
--------

* Python bindings to the C library vixDiskLib
* A more Object Oriented approach to interfacing with the vix API.
* Knowledge of the inner workings of the API is not needed.
* Simple and clean interface.

Installation
------------
This will be uploaded to the Python Package Index when it becomes more stable, but for now you can download the code from github, then run:

  $ sudo python ./setup.py install
  
TODO
----
* Add in Change Block Tracking


Documentation
=============

.. toctree::
   :maxdepth: 1
   :numbered:
   
   requirements.rst
   vixDiskLib.rst
   exceptions.rst
   examples.rst
   
   changes.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
