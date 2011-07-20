'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest, os, os.path
from vixDiskLib import VixDisk, VixDiskLib_CreateParams, VixDiskLib_DefaultBlockSize
from vixDiskLib.consts import VixDiskLibDiskType, VixDiskLibAdapterType, VixDiskLibHwVersion, VixDiskTransportModes
import numpy as np

def setupConfigs():
    test_dir = os.path.abspath(os.path.dirname(__file__))
    vix_config = os.path.join( test_dir, 'vix_disklib.cfg')
    
    if not os.path.exists(vix_config):
        data = open( vix_config+'.in' ).read()
        data = data.replace('TRANSPORT_LOGLEVEL', '6')
        data = data.replace('NFC_LOGLEVEL', '4')
        data = data.replace('TEMP_DIR', test_dir)
        open( vix_config, 'w').write(data)
    return vix_config
        
class TestLocalDisk(unittest.TestCase):

    def setUp(self):
        vix_config = setupConfig() # make sure that the config file exists
        
        self.test_dir = os.path.abspath(os.path.dirname(__file__))
        self.test_disk = os.path.join(self.test_dir, "test.vmdk")
       
        self.block_size = 1024
        self.test_disk_blocks = 1048576 # 1GB
        
        # open a local disk
        self.disk = VixDisk(libdir="/usr/lib/vmware-vix-disklib/lib64", vix_config=config, block_size=self.block_size)
        self.disk.connect(readonly=False)

    def tearDown(self):
        self.disk.disconnect()
        if os.path.exists(self.test_disk):
            os.unlink(self.test_disk)

    def testAvailableModes(self):
        modes = self.disk.available_modes
        
        # as a minimum, we should have these modes available
        for mode in ['file', 'ndbssl', 'ndb']:
            self.assertIn('file', modes, 'Transport mode %s is not available' % mode)
        
    def testGettingMode(self):
        mode = self.disk.transport_mode
        self.assertIn(mode, VixDiskTransportModes, "Got an invalid transport mode: %s" % mode)
        
    def testBlockSize(self):
        self.assertEqual(self.disk.block_size, self.block_size, 
                         "Block sizes didn't match: %d %d" % (self.block_size, self.disk.block_size))
        
    def testCreate(self):
        params = VixDiskLib_CreateParams( disk_type = VixDiskLibDiskType['MONOLITHIC_SPARSE'],
                adapter_type = VixDiskLibAdapterType['SCSI_LSILOGIC'],
                hw_version = VixDiskLibHwVersion['CURRENT'], blocks = self.test_disk_blocks)
        
        self.disk.create(self.test_disk, params)
        self.disk.open(self.test_disk)
        
        # fill up a 1k block of data
        buffer = np.zeros(self.block_size, dtype=np.uint8)
        buffer.fill(42) # it's the answer
        
        for block in xrange(blocks):
            self.disk.write(block, 1, buffer)
            
        self.disk.close()
        
        # file sizes should be the same, but we'll give a little wiggle room in case header 
        # info is different with different filesystems
        self.assertAlmostEqual(os.stat(self.test_disk), 1073938432, 
                               "File size doesn't match what we where aiming for...", delta=1024)
        
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testDisk']
    unittest.main()