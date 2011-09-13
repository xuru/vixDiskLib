
Example
=======

Here is an example of opening a disk, and writting it out to a file.::

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

