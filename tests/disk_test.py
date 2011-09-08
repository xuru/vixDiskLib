'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest, os.path

from vixDiskLib.consts import VixDiskTransportModes
from vixDiskLib.vixExceptions import VixDiskLibError
from utils import test_dir, get_connection, create_local_disk, default_disk_path

class TestLocalDisk(unittest.TestCase):

    def setUp(self):
        self.test_disk = os.path.join(test_dir, "test.vmdk")
        self.block_size = 1024
        self.test_disk_blocks = 256000 # 250MB
        
        # open a local disk
        self.disk = get_connection(block_size=self.block_size)

    def tearDown(self):
        self.disk.disconnect()
        if os.path.exists(self.test_disk):
            os.unlink(self.test_disk)

    def testAvailableModes(self):
        # we haven't opened a disk, so we must assert
        with self.assertRaises(VixDiskLibError):
            modes = self.disk.available_modes
            print modes
    
    def testAvailableModesAfterOpen(self):
        create_local_disk(self.disk, blocks=self.test_disk_blocks)
        self.disk.open(default_disk_path)
        modes = self.disk.available_modes
        
        # as a minimum, we should have these modes available
        for mode in ['file', 'ndbssl', 'ndb']:
            self.assertIn('file', modes, 'Transport mode %s is not available' % mode)
        self.disk.close()
        
    def testGettingMode(self):
        # we haven't opened a disk, so we must assert
        with self.assertRaises(VixDiskLibError):
            mode = self.disk.transport_mode
            print mode
        
    def testGettingModeAfterOpen(self):
        create_local_disk(self.disk, blocks=self.test_disk_blocks)
        self.disk.open(default_disk_path)
        
        mode = self.disk.transport_mode
        self.assertIn(mode, VixDiskTransportModes, "Unsupported mode: %s" % mode)
        self.disk.close()
        
    def testBlockSize(self):
        self.assertEqual(self.disk.block_size, self.block_size, 
                         "Block sizes didn't match: %d %d" % (self.block_size, self.disk.block_size))
        
    def testCreate(self):
        create_local_disk(self.disk, blocks=self.test_disk_blocks)
        
        print "file size: %d" % os.stat(self.test_disk).st_size
        print "calculated size: %d" % (self.test_disk_blocks*self.block_size)
        
        # file sizes should be the same, but we'll give a little wiggle room in case header 
        # info is different with different filesystems
        size = self.test_disk_blocks*self.block_size
        self.assertAlmostEqual(os.stat(self.test_disk).st_size, size,
                           msg="File size doesn't match what we where aiming for...", delta=size*.001)
        

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testDisk']
    unittest.main()