
from exceptions import Exception
import logging

from common cimport *
from vixDiskLib_headers cimport *
import numpy as np
# "cimport" is used to import special compile-time information
# about the numpy module (this is stored in a file numpy.pxd which is
# currently part of the Cython distribution).
cimport numpy as np

log = logging.getLogger(__name__)

logging_callback = None

class VixDiskLibError(Exception):
    pass

# Add some default callbacks (from the sample application in the VDDK)
cdef void LogFunc(char *format, va_list args):
    cdef char buffer[1000]
    PyOS_vsnprintf(buffer, 1000, format, args)
    #if logging_callback:
    #    logging_callback(logging.INFO, buffer.strip() + "\n")
    #else:
    log.debug(buffer.strip())

cdef void WarnFunc(char *format, va_list args):
    cdef char buffer[1000]
    PyOS_vsnprintf(buffer, 1000, format, args)
    #if logging_callback:
    #    logging_callback(logging.WARN, buffer.strip() + "\n")
    #else:
    log.warn(buffer.strip())

cdef void PanicFunc(char *format, va_list args):
    cdef char buffer[1000]
    PyOS_vsnprintf(buffer, 1000, format, args)
    #if logging_callback:
    #    logging_callback(logging.CRITICAL, buffer.strip() + "\n")
    #else:
    log.error(buffer.strip())
    
cdef bint progressCallback(void *data, int percentComplete): 
    cdef char buffer[1000]
    if data != NULL:
        sprintf(buffer, "%s: %d% complete", <char *>data, percentComplete)
    else:
        sprintf(buffer, "%d% complete", percentComplete)
    log.info(buffer)

DTYPE  = np.uint8
ctypedef np.uint8_t DTYPE_t

VixDiskLibSectorSize = VIXDISKLIB_SECTOR_SIZE
cdef int DEFAULT_BLOCK_SIZE = 1048576 # 1MB

cdef uint32 SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE/VIXDISKLIB_SECTOR_SIZE

cdef int VIXDISKLIB_VERSION_MAJOR = 1
cdef int VIXDISKLIB_VERSION_MINOR = 2

class VixCredentials(object):
    def __init__(self, host, username, password):
        self.host = host
        self.username = username
        self.password = password
    
class VixDiskOpenFlags:
    UNBUFFERED = VIXDISKLIB_FLAG_OPEN_UNBUFFERED
    SINGLE_LINK = VIXDISKLIB_FLAG_OPEN_SINGLE_LINK
    READ_ONLY = VIXDISKLIB_FLAG_OPEN_READ_ONLY

class VDDKError(Exception):
    pass


cdef class VixDiskLib(object):
    cdef VixDiskLibHandle handle
    cdef np.ndarray buff
    cdef VixDiskLibConnectParams params
    cdef VixDiskLibConnection conn
    
    cdef info
    cdef connected
    cdef opened
    cdef cred
    cdef ro
    cdef char *libdir
    cdef char *config
    cdef vmdk_path
    
    def __init__(self, vmxSpec, params, libdir=None, conf=None, callback=None):
        log.debug("Initializing vixDiskLib")
        
        global logging_callback
        logging_callback = callback
        
        if not vmxSpec.startswith("moref="):
            vmxSpec = "moref=" + vmxSpec
        
        self.params.vmxSpec = strdup(vmxSpec)
        self.params.serverName = strdup(params.host)
        self.params.credType = VIXDISKLIB_CRED_UID
        self.params.creds.uid.userName = strdup(params.username)
        self.params.creds.uid.password = strdup(params.password)
        self.params.port = 0
        self.cred = params
        self.buff = np.zeros(VIXDISKLIB_SECTOR_SIZE, dtype=DTYPE)
        
        if libdir:
            self.libdir = strdup(libdir)
            log.debug("  Using libdir: %s" % self.libdir)
        else:
            self.libdir = NULL
            
        if conf:
            self.config = strdup(conf)
            log.debug("  Using config: %s" % self.config)
        else:
            self.config = NULL
        
        self.initialize()
        
                
    def initialize(self):
        self.connected = False
        self.opened = False
        self.ro = False
        self.info = ""
        self.vmdk_path = ""
        vixError = VixDiskLib_InitEx(VIXDISKLIB_VERSION_MAJOR, VIXDISKLIB_VERSION_MINOR, 
                <VixDiskLibGenericLogFunc*>&LogFunc, <VixDiskLibGenericLogFunc*>&WarnFunc, 
                <VixDiskLibGenericLogFunc*>&PanicFunc, self.libdir, self.config)
        if vixError != VIX_OK:
            self._logError("Error initializing the vixDiskLib library", vixError)
      
    def finallize(self):
        if self.opened:
            self.close()
        if self.connected:
            self.disconnect()
            
        free(self.params.vmxSpec)
        free(self.params.serverName)
        free(self.params.creds.uid.userName)
        free(self.params.creds.uid.password)

        VixDiskLib_Exit()
        
    def __del__(self):
        log.debug("Closing any open connections and exiting")
        self.finallize()
            
    def reset(self):
        self.disconnect()
        self.finalize()
        self.initialize()
        self.connect()
        
    cdef _logError(self, msg, error_num):
        cdef char *error = VixDiskLib_GetErrorText(error_num, NULL)
        out = "[%d] " % error_num
        out += error
        ex = VixDiskLibError(out)
        VixDiskLib_FreeErrorText(error)
        raise ex
    
    def connect(self, snapshotRef, transport=None, readonly=True):
        log.debug("Connecting to %s as %s" % (self.cred.host, self.cred.username))
        self.ro = readonly

        cdef char *_transport
        if transport:
            _transport = strdup(transport)
        else:
            _transport = NULL

        # let's do a clean up just in case we had a bad run last time...
        cdef uint32 numCleanedUp, numRemaining
        VixDiskLib_Cleanup(&(self.params), &numCleanedUp, &numRemaining)
        
        vixError = VixDiskLib_ConnectEx(&(self.params), self.ro, snapshotRef, _transport, &(self.conn))
        if vixError != VIX_OK:
            self._logError("Error connecting to %s" % self.params.serverName, vixError)
        self.connected = True
        
    def disconnect(self):
        log.debug("Disconnecting from %s" % self.cred.host)
        if self.connected is False:
            raise VDDKError("Need to connect to the esx server before calling disconnect")
        if self.opened:
            self.close()
        VixDiskLib_Disconnect(self.conn)
        
        cdef uint32 numCleanedUp, numRemaining
        VixDiskLib_Cleanup(&(self.params), &numCleanedUp, &numRemaining)
        self.connected = False
    
    def open(self, path, single=False):
        if not self.vmdk_path:
            self.vmdk_path = path
        
        if self.connected is False:
            raise VDDKError("Need to connect to the esx server before calling open")
        
        if self.ro:
            _flag = VIXDISKLIB_FLAG_OPEN_READ_ONLY
        else:
            _flag = VIXDISKLIB_FLAG_OPEN_UNBUFFERED
            if single:
                _flag |= VIXDISKLIB_FLAG_OPEN_SINGLE_LINK
            
        log.debug("Opening drive: [flags: %d] %s" % (_flag, self.vmdk_path))
        vixError = VixDiskLib_Open(self.conn, self.vmdk_path, _flag, &(self.handle))
        if vixError != VIX_OK:
            self._logError("Error opening %s" % self.vmdk_path, vixError)
        self.opened = True
        
    def close(self):
        log.debug("Closing drive...")
        if self.opened is False:
            raise VDDKError("Need to open a disk before closing it")
        vixError = VixDiskLib_Close(self.handle)
        if vixError != VIX_OK:
            self._logError("Error closing the disk", vixError)
        self.opened = False
        
    def reopen(self):
        self.close()
        self.open(self.vmdk_path)
        
    def getMetadata(self):
        log.debug("Getting metadata for the disk")
        cdef size_t requiredLen
        cdef np.ndarray buffer = np.ndarray(1024, dtype=np.uint8)
        cdef np.ndarray val
        metadata = {}
       
        # it will fail the first time, but will give us the required length...
        vixError = VixDiskLib_GetMetadataKeys(self.handle, NULL, 0, &requiredLen)
        if vixError != VIX_OK and vixError != VIX_E_BUFFER_TOOSMALL:
            self._logError("Error getting metadata", vixError)
            
        vixError = VixDiskLib_GetMetadataKeys(self.handle, <char *>buffer.data, requiredLen, NULL)
        if vixError != VIX_OK:
            self._logError("Error getting metadata", vixError)
        
        cdef char *key = <char *>buffer.data
        while key[0]:
            vixError = VixDiskLib_ReadMetadata(self.handle, key, NULL, 0, &requiredLen);
            if vixError != VIX_OK and vixError != VIX_E_BUFFER_TOOSMALL:
                self._logError("Error getting metadata", vixError)
            
            val = np.ndarray(requiredLen, dtype=np.uint8)
            vixError = VixDiskLib_ReadMetadata(self.handle, key, <char *>val.data, requiredLen, NULL);
            if vixError != VIX_OK:
                self._logError("Error getting metadata", vixError)
            #print "%s = %s" % (key, val.tostring())
            metadata[key] = val.tostring()[:-1]
            key += (1 + strlen(key));
        return metadata
    
    def setMetadata(self, metadata):
        pass
        
    def getInfo(self):
        log.debug("Getting info for the disk")
        if self.opened is False:
            raise VDDKError("Need to open a disk before calling getInfo")
        
        cdef VixDiskLibInfo *info
        vixError = VixDiskLib_GetInfo(self.handle, &info)
        if vixError != VIX_OK:
            self._logError("Error getting info for: %s" % self.vmdk_path, vixError)
            
            
        biosGeo = {"cylinders":info.biosGeo.cylinders, "heads":info.biosGeo.heads, "sectors": info.biosGeo.sectors}
        physGeo = {"cylinders":info.physGeo.cylinders, "heads":info.physGeo.heads, "sectors": info.physGeo.sectors}
        pyinfo = { 
            'bios': biosGeo,
            'physGeo': physGeo, 
            'capacity': info.capacity,
            'links' : info.numLinks,
            'blocks' : info.capacity / SECTORS_PER_BLOCK }
    
        VixDiskLib_FreeInfo(info)
        return pyinfo
    
    def getTransportModesAvailable(self):
        return VixDiskLib_ListTransportModes()
        
    def getTransportMode(self):
        return VixDiskLib_GetTransportMode(self.handle)
        
    def read(self, VixDiskLibSectorType offset, uint32 nblocks=1):
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_read
        
        sectors_to_read = (nblocks * SECTORS_PER_BLOCK)  # number of sectors to read
        sector_offset = offset * SECTORS_PER_BLOCK       # from blocks to sectors
        
        nbytes = (sectors_to_read * VIXDISKLIB_SECTOR_SIZE)
        
        if self.buff.size != nbytes:
            self.buff.resize(nbytes)
            
        vixError = VixDiskLib_Read(self.handle, sector_offset, sectors_to_read, <uint8 *>self.buff.data)
        if vixError != VIX_OK:
            self._logError("Error reading the disk: %s" % self.vmdk_path, vixError)
        return self.buff
    
    
    def write(self, VixDiskLibSectorType offset, VixDiskLibSectorType nblocks, np.ndarray[dtype=DTYPE_t] buff):
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_write
        
        sector_offset = offset * SECTORS_PER_BLOCK       # from blocks to sectors
        sectors_to_write = (nblocks * SECTORS_PER_BLOCK)  # number of sectors to write
        
        vixError = VixDiskLib_Write(self.handle, sector_offset, sectors_to_write, <uint8 *>buff.data)
        if vixError != VIX_OK:
            self._logError("Error reading the disk: %s" % self.vmdk_path, vixError)
    
    
    def shrinkVmdk(self):
        vixError = VixDiskLib_Shrink(self.handle, progressCallback, NULL);
        if vixError != VIX_OK:
            self._logError("Error shrinking disk: %s" % self.vmdk_path, vixError)
    
    def createVmdkFile(self, char *localpath, char *path, VixDiskLibAdapterType adapterType, int64 nBlocks, int64 blockSize):
        pass
    
# ----------------------------------------------------------------------
# vim: set filetype=python expandtab shiftwidth=4:
# [X]Emacs local variables declaration - place us into python mode
# Local Variables:
# mode:python
# py-indent-offset:4
# End:





