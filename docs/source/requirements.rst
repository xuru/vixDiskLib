
Requirements
============

For Linux, you will need to install the following packages from your distribution:

* The development version of python
* pkg-config

From VMware, you will need to install:

* `VMware Virtual Disk Development Kit 1.2 <http://www.vmware.com/download/download.do?downloadGroup=VDDK-1-2>`_.
  
Python packages that are needed:

* Cython
* numpy

If you find that when you try to import the module, you get an error something like:
ImportError: libvixDiskLibVim.so.1: cannot open shared object file: No such file or directory
You need to setup your library path to point to the location of your vix-disklib directory (usually in /usr/lib/vmware-vix-disklib/lib64 or /usr/lib/vmware-vix-disklib/lib32).  To do this, execute the following command:

  sudo ldconfig /usr/lib/vmware-vix-disklib/lib64/
  
I've found this causes conflicts with other libraries on the system, so what I usually do is::
  
  $ cd /usr/lib/vmware-vix-disklib/lib64/
  $ mkdir removed
  $ mv libcrypto.so.* libcurl.so.* libglib-* libgobject-* libgthread-* libssl.so.* removed
    
  $ echo "/usr/lib/vmware-vix-disklib/lib64" > /etc/ld.so.conf.d/vmware-vix-disklib.conf
  $ ldconfig

Ubuntu Users
============

In order to use the vix disk library from VMware and be able to use SAN transport, you will have 
to modify the library it's self.  This of course may ruin your library and delete all your 
virtual machines and burn your vcenter to the ground.  You have been warned.

In order to modify the library to work with newer kernels in Ubuntu, Debian and probably other distributions, 
you will need to modify where the library looks for the mapped devices.  In my system, I point it to /vmware/mapper.

When you install the vmware-vix-disklib distribution, it will install it's self in /usr/lib/vmware-vix-disklib.  The library
that we are interested in is libdiskLibPlugin.so.  So whether you running a 32bit or 64bit machine (64 bit here), 
it will be located in plugins32 or plugins64.  So bring up a term, sudo to root and change directories to the plugins directory.

  $ sudo su
  $ cd /usr/lib/vmware-vix-disklib/plugins64

Now copy the library so that you can recover it later if it doesn't work.  Then run the following command to modify the library::
  
  $ mv libdiskLibPlugin.so libdiskLibPlugin.so.org
  $ sed -e 's@%s/class/scsi_disk@/////vmware/mapper@' libdiskLibPlugin.so.org > libdiskLibPlugin.so

Next, we'll need to make links to the correct device mappers.  This will need to be done on every boot, so put it in 
a script and link it to /etc/init.d.  Here is mine::

  #!/bin/bash
  
  shopt -s extglob
  
  for f in /dev/mapper/mpath+([0-9]) ; do
    d=$(basename $f)
    mkdir -p /vmware/mapper/$d/device/$d
    ln -sf /vmware/mapper/$d/device/$d /vmware/mapper/$d/device/block:$d
    ln -sf /dev/mapper/$d /dev/$d
  done

This script assumes that the devices in question (a fiber connection to our SAN, using multipath) are in /dev/mapper/mpath*.  
This may be different on your system.  Flavor to taste.


  
  
  
