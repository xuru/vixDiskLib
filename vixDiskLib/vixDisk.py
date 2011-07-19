'''
Created on Jul 8, 2011

@author: eplaster
'''

from vixDiskLib.vixExceptions import VixDiskLibError
from vixDiskBase import VixDiskBase
        
class VixDisk(VixDiskBase):
    """ A file IO interface to the vixDiskLib SDK """
    
    def iter(self, nblocks=1):
        if not self.open:
            raise VixDiskLibError("Disk must be open to use the generator method")
        
        _info = self.info()
        for b in xrange(0, _info['blocks'], step=nblocks):
            yield self.read(b, nblocks)
    
