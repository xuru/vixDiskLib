'''
Created on Jul 8, 2011

@author: eplaster
'''
import unittest, os.path
from vixDiskLib import VixDisk, VixDiskLib_CreateParams, VixDiskLib_DefaultBlockSize, VixCredentials
from vixDiskLib.consts import VixDiskLibDiskType, VixDiskLibAdapterType, VixDiskLibHwVersion, VixDiskTransportModes
from vixDiskLib.vixExceptions import VixDiskLibError
from utils import setupConfigs, test_dir, create_local_disk, libdir, create_remote_disk
import numpy as np

from pyvisdk import Vim, Options

# if we don't have credentials in ~/.visdkrc.vcenter, we can't do these tests
skip_tests = not os.path.exists( os.path.expanduser("~/.visdkrc.vcenter") )
print "skip_tests: %s" % skip_tests
        
class TestRemoteCreate(unittest.TestCase):

    def setUp(self):
        self.block_size = 1024
        self.test_disk_blocks = 256000 # 250MB
        global skip_tests
        
        if not skip_tests:
            vixconfig = setupConfigs() # make sure that the vix configuration file exists
            self.options = Options()
            # we must have a ~/.visdkrc.vcenter file for this to work
            try:
                self.options.load("~/.visdkrc.esxi-prod-01.vm.kingsolutions.local")
            except:
                skip_tests = True
                raise
            
            print self.options
            # make a VISDK connection to the vcenter
            self.vim = Vim(self.options.VI_SERVER)
            self.vim.login(self.options.VI_USERNAME, self.options.VI_PASSWORD)

            # get the virtual machine that we want to test with...
            self.vm = self.vim.getVirtualMachine("puppetTestAppServer")
            
            # Connect to the vcenter with the vix_disk_lib using the managed object reference of the vm we will use
            creds = VixCredentials( vmxSpec=self.vm.ref.value, host=self.options.VI_SERVER, username=self.options.VI_USERNAME,
                password=self.options.VI_PASSWORD, )
            
            self.disk = VixDisk(creds, libdir=libdir, config=vixconfig)
            self.disk.connect(readonly=False)

    def tearDown(self):
        if not skip_tests:
            self.disk.disconnect()

    @unittest.skipIf(skip_tests, "Remote connection is not configured")
    def testCreate(self):
        create_remote_disk(self.vm, self.disk, blocks=self.test_disk_blocks, blocksize=self.block_size)
        
        # refresh the layout information
        self.vm.update('layoutEx')
        
        size = self.test_disk_blocks*self.block_size
        remote_size = 0
        for _file in self.vm.layoutEx.file:
            if (_file.type == "diskExtent") and (_file.name.find('test.vmdk') != -1):
                remote_size = _file.size

        self.assertAlmostEqual(remote_size, size,
               msg="Remote file size doesn't match what we where aiming for...", delta=size*.001)
        
        


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testDisk']
    unittest.main()