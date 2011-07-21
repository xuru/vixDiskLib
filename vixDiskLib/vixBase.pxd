# distutils: language = C
# distutils: libraries = vixDiskLib vixMntapi
# distutils: include_dirs = /usr/lib/vmware-vix-disklib/include

from common cimport *
from vddk cimport *


cdef class VixBase(object):
    cdef VixDiskLibConnectParams params
    cdef VixDiskLibConnection conn
    
    cdef _handleError(self, msg, int error_num)
    