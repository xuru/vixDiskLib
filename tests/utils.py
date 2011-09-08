'''
Created on Jul 21, 2011

@author: eplaster

Unittest utility methods
'''
import os.path, platform
from vixDiskLib import VixDisk, VixDiskLib_CreateParams
from vixDiskLib.consts import VixDiskLibDiskType, VixDiskLibAdapterType, VixDiskLibHwVersion
import numpy as np

test_dir = os.path.abspath(os.path.dirname(__file__))
default_block_size = 1024
default_disk_blocks = 256000 # 250MB
default_disk_path = os.path.join(test_dir, "test.vmdk")

if platform.architecture()[0] == "64bit":
    libdir = "/usr/lib/vmware-vix-disklib/lib64"
else:
    libdir = "/usr/lib/vmware-vix-disklib/lib32"
    
def setupConfigs():
    vix_config = os.path.join( test_dir, 'vix_disklib.cfg')
    
    if not os.path.exists(vix_config):
        data = open( vix_config+'.in' ).read()
        data = data.replace('TRANSPORT_LOGLEVEL', '6')
        data = data.replace('NFC_LOGLEVEL', '4')
        data = data.replace('TEMP_DIR', test_dir)
        open( vix_config, 'w').write(data)
    return vix_config

def get_connection(block_size=default_block_size):
    vix_config = setupConfigs()
    
    disk = VixDisk(libdir="/usr/lib/vmware-vix-disklib/lib64", config=vix_config, block_size=block_size)
    disk.connect(readonly=False)
    return disk

def create_local_disk(
            vix_disk=None,
            path = default_disk_path,
            disk_type=VixDiskLibDiskType['MONOLITHIC_SPARSE'], 
            adapter_type = VixDiskLibAdapterType['SCSI_LSILOGIC'], 
            hw_version = VixDiskLibHwVersion['CURRENT'],
            blocks = default_disk_blocks, blocksize = default_block_size, fill=True):
    
    if not vix_disk:
        vix_disk = get_connection()
    
    params = VixDiskLib_CreateParams( disk_type = disk_type, adapter_type = adapter_type,
            hw_version = hw_version, blocks = blocks)
    
    vix_disk.create(path, params)
    vix_disk.open(path)
    
    if fill:
        # fill up a 1k block of data
        buffer = np.zeros(vix_disk.block_size, dtype=np.uint8)
        buffer.fill(42) # it's the answer
    
        for block in xrange(blocks):
            vix_disk.write(block, 1, buffer)
        
    vix_disk.close()
    return vix_disk

def create_remote_disk( vm, remote_disk, name="test.vmdk",
            disk_type=VixDiskLibDiskType['MONOLITHIC_SPARSE'],
            adapter_type = VixDiskLibAdapterType['SCSI_LSILOGIC'],
            hw_version = VixDiskLibHwVersion['CURRENT'],
            blocks = default_disk_blocks, blocksize = default_block_size, fill=True):
    
    config_location = None
    disk_location = None
        
    # gather information
    for _file in vm.layoutEx.file:
        if _file.type == "config":
            config_location = _file.name[:_file.name.rfind('/')]
        if _file.type == "diskDescriptor":
            disk_location = _file.name[:_file.name.rfind('/')]
            break
    
    # check if we have a different data store for storing disks
    if disk_location:
        path = os.path.join(disk_location, name)
    else:
        path = os.path.join(config_location, name)
                
    params = VixDiskLib_CreateParams( 
            disk_type = disk_type, adapter_type = adapter_type,
            hw_version = hw_version, blocks = blocks)
    
    print "path: %s" % path
    print "params: %s" % params
    print "local path: %s" % os.path.join(test_dir, name)
    remote_disk.create(path, params, local_path=os.path.join(test_dir, name))
    
    remote_disk.open(path)
    
    if fill:
        # fill up a 1k block of data
        buffer = np.zeros(remote_disk.block_size, dtype=np.uint8)
        buffer.fill(42) # it's the answer
        
        for block in xrange(blocks):
            remote_disk.write(block, 1, buffer)
            
    remote_disk.close()
    return remote_disk











