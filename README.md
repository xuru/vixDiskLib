
# vixDiskLib - vixDiskLib wrapper in Python

  [vixDiskLib](http://xuru.github.com/vixDiskLib) is a Python wrapper to access the [VMware Virtual Disk Development Kit API](http://communities.vmware.com/community/developer/forums/vddk).

## Requirements
  # The development version of python, pkg-config, and of course, the VDDK need to be installed.
  
  For Ubuntu users:
  * apt-get install pkg-config, python-dev
  * pip install cython, numpy
  
  If you find that when you try to import the module, you get an error something like:
  ImportError: libvixDiskLibVim.so.1: cannot open shared object file: No such file or directory
  You need to setup your library path to point to the location of your vix-disklib directory (usually in /usr/lib/vmware-vix-disklib/lib64 or /usr/lib/vmware-vix-disklib/lib32).  To do this, execute the following command:
  sudo ldconfig /usr/lib/vmware-vix-disklib/lib64/
  
  I've found this causes conflicts with other libraries on the system, so what I usually do is:
  
  $ cd /usr/lib/vmware-vix-disklib/lib64/
  $ mkdir removed
  $ mv libcrypto.so.* libcurl.so.* libglib-* libgobject-* libgthread-* libssl.so.* removed
  
  $ echo "/usr/lib/vmware-vix-disklib/lib64" > /etc/ld.so.conf.d/vmware-vix-disklib.conf
  $ ldconfig
  
## Installation
  This will be uploaded to the Python Package Index when it becomes more stable, but for now you can download the code from github, then run:
  $ sudo python ./setup.py install
  
## Features
  Calling vixDiskLib functions from python of course ;)

## TODO
  Add in Change Block Tracking
    
## Example
  from vixDiskLib import VixDisk, VixDiskLib_SectorSize, VixDiskOpenFlags, VixCredentials
    
  creds = VixCredentials("vcenter.domain.com", "myusername", "mysecretpassword")
    
  diskLib = VixDisk(vmxSpec, creds)
  diskLib.connect(snapshotRef, readonly=True)
  diskLib.open(disk.filename)

  info = diskLib.info()
  ...
    
  metadata = diskLib.getMetadata()
  ...
    
  fd = open("out.vdmk", 'w')
    
  for i in xrange(info['blocks']):
    buffer = diskLib.read(i)
      ...
        
      fd.write(buffer.data)
    
  fd.close()
    
  diskLib.close()
  diskLib.disconnect()

## Authors

  * Eric Plaster


## License 

(The MIT License)

Copyright (c) 2011 Eric Plaster &lt;plaster at gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.