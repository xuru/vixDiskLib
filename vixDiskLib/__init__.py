#!/usr/bin/env python
"""
This package defines classes that...
"""


__licence__ = """
The MIT License

Copyright (c) 2006-2011 Scott Griffiths (scott@griffiths.name)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

__version__ = "0.2.1"

__author__ = "Eric Plaster"

__all__ = [
    'VixDiskLib_SectorSize', 'VixDiskLib_DefaultBlockSize', 'VixDiskLib_SectorsPerBlock',
    'VixDiskOpenFlags', 'VixDiskLibError', 'VixDiskUnimplemented',
    'VixCredentials', 'VixDisk',
]

from vixDiskBase import VixDiskBase, VixDiskLib_SectorSize, VixDiskLib_DefaultBlockSize, VixDiskLib_SectorsPerBlock
from vixExceptions import VixDiskLibError, VixDiskUnimplemented

class VixDiskOpenFlags:
    UNBUFFERED = 1
    SINGLE_LINK = 2
    READ_ONLY = 4

class VixCredentials(object):
    """ VixDiskLib Credentials to log into a vcenter or ESX server """
    def __init__(self, host, username, password):
        self.host = host
        self.username = username
        self.password = password

class VixDisk(VixDiskBase):
    """ A file IO interface to the vixDiskLib SDK """
    
    def __init__(self, vmxSpec, credentials, libdir=None, config=None, callback=None):
        VixDiskBase.__init__(vmxSpec, credentials, libdir, config, callback)

    def iter(self, nblocks=1):
        if not self.open:
            raise VixDiskLibError("Disk must be open to use the generator method")
        
        _info = self.info()
        for b in xrange(0, _info['blocks'], step=nblocks):
            yield self.read(b, nblocks)
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
