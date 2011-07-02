'''
Created on Jul 1, 2011

@author: eplaster
'''
from exceptions import Exception

class VixDiskLibError(Exception):
    """ VixDiskLib exception class """
    pass

class VixDiskUnimplemented(Exception):
    """ VixDiskLib exception class for unimplemented features """
    pass
