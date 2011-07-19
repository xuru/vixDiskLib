'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest, os, os.path, sys, shutil
from vixDiskLib import VixDisk, VixDiskLib_CreateParams, VixDiskLib_DefaultBlockSize
from vixDiskLib.consts import VixDiskLibDiskType, VixDiskLibAdapterType, VixDiskLibHwVersion
import numpy as np

gig = 1024*1024*1024
class TestDisk(unittest.TestCase):


    def setUp(self):
        # setup the config file...
        test_dir = os.path.dirname(__file__)
        config = os.path.join( test_dir, 'test.cfg')
        data = open( config+'.in' ).read()
        data = data.replace('TRANSPORT_LOGLEVEL', '6')
        data = data.replace('NFC_LOGLEVEL', '4')
        data = data.replace('TEMP_DIR', test_dir)
        open( config, 'w').write(data)
        
        # open a local disk
        self.disk = VixDisk(libdir="/usr/lib/vmware-vix-disklib/lib64", config=config)
        self.disk.connect(readonly=False)

    def tearDown(self):
        self.disk.disconnect()

    def testModes(self):
        modes = self.disk.available_modes
        print modes
        
    def testCreate(self):
        print gig
        params = VixDiskLib_CreateParams(
                disk_type = VixDiskLibDiskType['MONOLITHIC_SPARSE'],
                adapter_type = VixDiskLibAdapterType['SCSI_LSILOGIC'],
                hw_version = VixDiskLibHwVersion['CURRENT'],
                capacity = 4294967296)
        
        # if we already ran the test...  delete the test file
        if os.path.exists("test.vmdk"):
            os.unlink("test.vmdk")
        
        if os.path.exists("test.vmdk.lck"):
            shutil.rmtree("test.vmdk.lck")
            
        print "Connected: %s" % self.disk.connected
        self.disk.create("test.vmdk", params)
        self.disk.open("test.vmdk")
        
        block = np.zeros(VixDiskLib_DefaultBlockSize, dtype=np.uint8)
        blocks = (gig*4)/VixDiskLib_DefaultBlockSize
        for x in xrange(blocks):
            self.disk.write(x, 1, block)
        
        self.disk.close()
        
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testDisk']
    unittest.main()