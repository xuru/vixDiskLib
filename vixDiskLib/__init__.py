#!/usr/bin/env python
"""
This package wraps up the vix-disklib library from vmware, and creates binding for python.
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
    'VixDiskLibError', 'VixDiskUnimplemented', 'VixDiskLibAdapterType', 'VixDiskLibDiskType', 
    'VixDiskOpenFlags', 'VixDiskLibHwVersion', 'VixCredentials', 'VixDiskLibCreateParams', 'VixDisk',
    'VixDiskBase'
]

from vixExceptions import VixDiskLibError, VixDiskUnimplemented
from consts import VixDiskLibAdapterType, VixDiskLibDiskType, VixDiskOpenFlags, VixDiskLibHwVersion

from vixBase import VixBase
from vixDiskBase import VixDiskBase
from vixDisk import VixDisk

# expose some of these to python
VixDiskLib_SectorSize           = 512
VixDiskLib_DefaultBlockSize     = 1048576
VixDiskLib_SectorsPerBlock      = VixDiskLib_DefaultBlockSize/VixDiskLib_SectorSize

class VixCredentials(object):
    """ VixDiskLib Credentials to log into a vcenter or ESX server """
    def __init__(self, vmxSpec, host, username, password):
        self.vmxSpec = vmxSpec
        self.host = host
        self.username = username
        self.password = password

class VixDiskLib_CreateParams(object):
    """ Disk creation parameters """
    def __init__(self, disk_type, adapter_type, hw_version, blocks):
        self.disk_type = disk_type
        self.adapter_type = adapter_type
        self.hw_version = hw_version
        self.blocks = blocks

    def __str__(self):
        return "%d, %d, %d, %d" % (self.disk_type, self.adapter_type, self.hw_version, self.blocks)

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
