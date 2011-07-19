'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest, os, os.path
from vixDiskLib import VixDisk, VixDiskLib_CreateParams, VixDiskLib_DefaultBlockSize
from vixDiskLib.consts import VixDiskLibDiskType, VixDiskLibAdapterType, VixDiskLibHwVersion
import numpy as np

class TestLocalDisk(unittest.TestCase):

    def setUp(self):
        # setup the config file...
        self.test_dir = os.path.abspath(os.path.dirname(__file__))
        config = os.path.join( self.test_dir, 'test.cfg')
        data = open( config+'.in' ).read()
        data = data.replace('TRANSPORT_LOGLEVEL', '6')
        data = data.replace('NFC_LOGLEVEL', '4')
        data = data.replace('TEMP_DIR', self.test_dir)
        open( config, 'w').write(data)
        
        self.block_size = 1024
        
        # open a local disk
        self.disk = VixDisk(libdir="/usr/lib/vmware-vix-disklib/lib64", config=config, block_size=self.block_size)
        self.disk.connect(readonly=False)

    def tearDown(self):
        self.disk.disconnect()

    def testModes(self):
        modes = self.disk.available_modes
        
        # as a minimum, we should have these modes available
        for mode in ['file', 'ndbssl', 'ndb']:
            self.assertIn('file', modes, 'Transport mode %s is not available' % mode)
        
    def testCreate(self):
        blocks = 1048576 # should be about a 1G disk
        params = VixDiskLib_CreateParams(
                disk_type = VixDiskLibDiskType['MONOLITHIC_SPARSE'],
                adapter_type = VixDiskLibAdapterType['SCSI_LSILOGIC'],
                hw_version = VixDiskLibHwVersion['CURRENT'],
                blocks = blocks)
        
        filename = os.path.join(self.test_dir, "test.vmdk")
        
        # if we already ran the test...  delete the test files
        if os.path.exists(filename):
            os.unlink(filename)
        
        if os.path.exists(filename+".lck"):
            os.unlink(filename+".lck")
        
        self.disk.create(filename, params)
        self.disk.open(filename)
        
        # fill up a 1k block of data
        buffer = np.zeros(self.block_size, dtype=np.uint8)
        buffer.fill(42) # it's the answer
        
        for block in xrange(blocks):
            self.disk.write(block, 1, buffer)
            
        self.disk.close()
        
        # file sizes should be the same, but we'll give a little wiggle room in case header 
        # info is different with different filesystems
        self.assertAlmostEqual(os.stat(filename), 1073938432, 
                               "File size doesn't match what we where aiming for...", delta=1024)
        
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testDisk']
    unittest.main()