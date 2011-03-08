
# vixDiskLib - vixDiskLib wrapper in Python

  [vixDiskLib](http://xuru.github.com/vixDiskLib) is a Python wrapper to access the [VMware Virtual Disk Development Kit API](http://communities.vmware.com/community/developer/forums/vddk).

## Installation
  This will be uploaded to the Python Package Index when it becomes more stable, but for now you can download the code from github, then run:
  $ sudo python ./setup.py install
  
## Features
    Calling vixDiskLib functions from python of course ;)

## TODO
    Add in Change Block Tracking
    
## Example
    import vddk
    
    diskLib = vddk.VixDiskLib("vcenter.company.com", "username", "password")
    diskLib.connect(vm.name, snapshotRef, readonly=True)

    info = self.diskLib.getInfo()
    
    self.diskLib.copyFromVMDK(disk.filename, destination_filename)
    
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