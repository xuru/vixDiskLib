
# vixDiskLib - vixDiskLib wrapper in Python

  [vixDiskLib](http://xuru.github.com/vixDiskLib) is a Python wrapper to access the [VMware Virtual Disk Development Kit API](http://communities.vmware.com/community/developer/forums/vddk).

## Requirements
  Currently I'm using pkg-config in order to determine the location of libraries on the system.  This is available on linux and can be apt-get installed (or yum).
  
  For Ubuntu users:
  * apt-get install pkg-config
  * apt-get install python-dev
  * apt-get install python-numpy
  * apt-get install python-numpy-dev
  
## Installation
  This will be uploaded to the Python Package Index when it becomes more stable, but for now you can download the code from github, then run:
  $ sudo python ./setup.py install
  
## Features
    Calling vixDiskLib functions from python of course ;)

## TODO
    Add in Change Block Tracking
    
## Example
    from vixDiskLib import VixDiskLib, VixDiskLibSectorSize, VixDiskOpenFlags
    
    diskLib = VixDiskLib(vmxSpec, self.options.server, self.options.username, self.options.password)
    diskLib.connect(snapshotRef, readonly=True)
    diskLib.open(disk.filename)

    info = diskLib.getInfo()
    ...
    
    metadata = diskLib.getMetadata()
    ...
    
    
    for i in range(maxops):
        buffer = self.diskLib.read(i, bufsize)
        ...
    
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