'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest

class TestCore(unittest.TestCase):


    def setUp(self):
        pass


    def tearDown(self):
        pass


    def testCore(self):
        # do some sanity checks...
        import vixDiskLib
        
        for attr in vixDiskLib.__all__:
            self.assertTrue(hasattr(vixDiskLib, attr), "vixDiskLib doesn't have attribute: %s" % attr)
        
        self.assertEqual(vixDiskLib.VixDiskLib_DefaultBlockSize, 1048576, 
            "vixDiskLib doesn't have correct block size: %d" % vixDiskLib.VixDiskLib_DefaultBlockSize)
        
        self.assertEqual(vixDiskLib.VixDiskLib_SectorSize, 512,
            "vixDiskLib doesn't have correct sector size: %d" % vixDiskLib.VixDiskLib_SectorSize)
        
        # SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE (1048576 or 1MB) / VIXDISKLIB_SECTOR_SIZE (512)
        self.assertEqual(vixDiskLib.VixDiskLib_SectorsPerBlock, 1048576/512,
            "vixDiskLib doesn't have correct sector size: %d" % vixDiskLib.VixDiskLib_SectorsPerBlock)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testCore']
    unittest.main()