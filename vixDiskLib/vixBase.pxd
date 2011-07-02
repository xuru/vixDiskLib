
cimport vddk
from vddk cimport *

cdef class VixBase(object):
    cdef VixDiskLibConnectParams params
    cdef VixDiskLibConnection conn
    cdef connected
    cdef cred
    
    cdef _handleError(self, msg, int error_num)