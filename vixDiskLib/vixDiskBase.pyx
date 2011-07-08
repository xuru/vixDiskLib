
import logging
from vixExceptions import VixDiskLibError, VixDiskUnimplemented

from common cimport *
from vddk cimport *

cimport vixBase
from vixBase cimport *

log = logging.getLogger("vixDiskLib.vixDiskBase")

# define our byte type for numpy
DTYPE  = np.uint8
ctypedef np.uint8_t DTYPE_t

cdef int DEFAULT_BLOCK_SIZE     = 1048576 # 1MB
cdef uint32 SECTORS_PER_BLOCK   = DEFAULT_BLOCK_SIZE/VIXDISKLIB_SECTOR_SIZE

cdef unsigned short TRUE = 1
cdef unsigned short FALSE = 0

cdef truth(value):
    if value:
        return TRUE
    return FALSE

# expose some of these to python
VixDiskLib_SectorSize           = VIXDISKLIB_SECTOR_SIZE
VixDiskLib_DefaultBlockSize     = DEFAULT_BLOCK_SIZE 
VixDiskLib_SectorsPerBlock      = SECTORS_PER_BLOCK 


cdef class VixDiskBase(VixBase):
    """ A file IO interface to the vixDiskLib SDK """
    
    cdef VixDiskLibHandle handle
    cdef np.ndarray buff
    
    cdef VixDiskLibCreateParams create_params
    
    def __init__(self, vmxSpec, credentials, libdir=None, config=None, callback=None):
        super(VixDiskBase, self).__init__(vmxSpec, credentials, libdir, config, callback)
        
        self.vmdk_path = None
        self.opened = False
        self._transport_mode = None
        self.buff = np.zeros(VIXDISKLIB_SECTOR_SIZE, dtype=DTYPE)
        
    def _getTransportMode(self):
        return self._transport_mode
    transport_mode = property(_getTransportMode)
    
    def _getAvailableTransportModes(self):
        return VixDiskLib_ListTransportModes()
    available_modes = property(_getAvailableTransportModes)
    
    def open(self, path, single=False):
        """
        Open a vmdk for editing or reading (see readonly)
        @param path: Path to the vmdk.  Example: [System-Disk] DEV-BOX-01/DEV-BOX-01.vmdk
        """
        if not self.vmdk_path:
            self.vmdk_path = path
        
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        if self.opened:
            raise VixDiskLibError("Currently have disk %s opened.  Can not open another drive until this one is closed." % self.vmdk_path)
        
        if self.readonly:
            _flag = VIXDISKLIB_FLAG_OPEN_READ_ONLY
        else:
            _flag = VIXDISKLIB_FLAG_OPEN_UNBUFFERED
            if single:
                _flag |= VIXDISKLIB_FLAG_OPEN_SINGLE_LINK
        log.debug("Opening drive: [flags: %d] %s" % (_flag, self.vmdk_path))
        
        vix_error = VixDiskLib_Open(self.conn, self.vmdk_path, _flag, &(self.handle))
        if vix_error != VIX_OK:
            self._handleError("Error opening %s" % self.vmdk_path, vix_error)
        self.opened = True
        
        self._transport_mode = VixDiskLib_GetTransportMode(self.handle)
        
    def close(self):
        """
        Closes the disk.
        """
        log.debug("Closing drive...")
        
        if not self.opened:
            raise VixDiskLibError("Need to open a disk before closing it")
        
        vix_error = VixDiskLib_Close(self.handle)
        if vix_error != VIX_OK:
            self._handleError("Error closing the disk", vix_error)
        self.opened = False
        self._transport_mode = None
        
    def reopen(self):
        """
        Closes and re-opens the current disk.
        """
        self.close()
        self.open(self.vmdk_path)
        
    def info(self):
        """
        Retrieves information about a disk.
        """
        log.debug("Getting info for the disk %s" % self.vmdk_path)
        if not self.opened:
            raise VixDiskLibError("Need to open a disk before calling getInfo")
        
        cdef VixDiskLibInfo *info
        vix_error = VixDiskLib_GetInfo(self.handle, &info)
        if vix_error != VIX_OK:
            VixDiskLib_FreeInfo(info)
            self._handleError("Error getting info for: %s" % self.vmdk_path, vix_error)
            
        VixDiskLib_FreeInfo(info)
        
        biosGeo = {
            "cylinders": info.biosGeo.cylinders, 
            "heads": info.biosGeo.heads, 
            "sectors": info.biosGeo.sectors }
        
        physGeo = {
            "cylinders":info.physGeo.cylinders,
            "heads":info.physGeo.heads,
            "sectors": info.physGeo.sectors }
        
        pyinfo = { 
            'bios': biosGeo,
            'physGeo': physGeo, 
            'capacity': info.capacity,
            'adapterType': info.adapterType,
            'links' : info.numLinks,
            'blocks' : info.capacity / SECTORS_PER_BLOCK}
        return pyinfo
        
    def read(self, VixDiskLibSectorType offset, uint32 nblocks=1):
        """
        Reads a sector range.
        @param offset: Absolute offset.
        @param nblocks: Number of blocks to read.
        @return: np.ndarray of bytes
        Note: SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE (1048576 or 1MB) / VIXDISKLIB_SECTOR_SIZE (512)
              SECTORS_PER_BLOCK = 2048 sectors
              1 block = 1048576 byts or 1MB
        """
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_read
        
        sectors_to_read = (nblocks * SECTORS_PER_BLOCK)  # number of sectors to read
        sector_offset = offset * SECTORS_PER_BLOCK       # from blocks to sectors
        
        nbytes = (sectors_to_read * VIXDISKLIB_SECTOR_SIZE)
        
        log.debug("Reading %d bytes..." % nbytes)
        if self.buff.size != nbytes:
            log.debug("Resizing buffer to %d" % nbytes)
            self.buff.resize(nbytes)
            
        vix_error = VixDiskLib_Read(self.handle, sector_offset, sectors_to_read, <uint8 *>self.buff.data)
        if vix_error != VIX_OK:
            self._handleError("Error reading the disk: %s" % self.vmdk_path, vix_error)
            
        return self.buff
    
    def write(self, VixDiskLibSectorType offset, VixDiskLibSectorType nblocks, np.ndarray[dtype=DTYPE_t] buff):
        """
        Writes a sector range.
        @param offset: Absolute offset.
        @param nblocks: Number of blocks to read.
        @param buff: np.ndarray of bytes
        Note: SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE (1048576 or 1MB) / VIXDISKLIB_SECTOR_SIZE (512)
              SECTORS_PER_BLOCK = 2048 sectors
              1 block = 1048576 byts or 1MB
        """
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_write
        
        sector_offset = offset * SECTORS_PER_BLOCK       # from blocks to sectors
        sectors_to_write = (nblocks * SECTORS_PER_BLOCK)  # number of sectors to write
        
        nbytes = (sectors_to_write * VIXDISKLIB_SECTOR_SIZE)
       
        log.debug("Writing %d bytes..." % nbytes)
        vix_error = VixDiskLib_Write(self.handle, sector_offset, sectors_to_write, <uint8 *>buff.data)
        if vix_error != VIX_OK:
            self._handleError("Error reading the disk: %s" % self.vmdk_path, vix_error)

    def getMetadata(self):
        """
        Retrieves the metadata for the drive.
        """
        log.debug("Getting metadata for the disk")
        metadata = {}
        
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        cdef size_t requiredLen
        cdef np.ndarray buffer = np.ndarray(1024, dtype=np.uint8)
        cdef np.ndarray val
       
        # it will fail the first time, but will give us the required length...
        vixError = VixDiskLib_GetMetadataKeys(self.handle, NULL, 0, &requiredLen)
        if vixError != VIX_OK and vixError != VIX_E_BUFFER_TOOSMALL:
            self._handleError("Error getting metadata", vixError)
            
        vixError = VixDiskLib_GetMetadataKeys(self.handle, <char *>buffer.data, requiredLen, NULL)
        if vixError != VIX_OK:
            self._handleError("Error getting metadata", vixError)
        
        cdef char *key = <char *>buffer.data
        while key[0]:
            vixError = VixDiskLib_ReadMetadata(self.handle, key, NULL, 0, &requiredLen);
            if vixError != VIX_OK and vixError != VIX_E_BUFFER_TOOSMALL:
                self._handleError("Error getting metadata", vixError)
            
            val = np.ndarray(requiredLen, dtype=np.uint8)
            vixError = VixDiskLib_ReadMetadata(self.handle, key, <char *>val.data, requiredLen, NULL);
            if vixError != VIX_OK:
                self._handleError("Error getting metadata", vixError)
                
            metadata[key] = val.tostring()[:-1]
            key += (1 + strlen(key));
        return metadata
    
    def setMetadata(self, metadata):
        """
        Writes the metadata to the drive.
        """
        log.debug("Getting metadata for the disk")
        
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        for name, value in metadata.items():
            vixError = VixDiskLib_WriteMetadata(self.handle, PyString_AsString(name), PyString_AsString(value))
            if vixError != VIX_OK:
                self._handleError("Error writing metadata: %s, %s" % (name, value), vixError)
    
    def create(self, path, create_params):
        """
        Creates a local disk. Remote disk creation is not supported.
        """
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        self.create_params.diskType     = create_params.disk_type
        self.create_params.adapterType  = create_params.adapter_type
        self.create_params.hwVersion    = create_params.hw_version
        self.create_params.capacity     = create_params.capacity
        
        vixError = VixDiskLib_Create(self.conn, PyString_AsString(path), &(self.create_params), NULL, NULL)
        if vixError != VIX_OK:
            self._handleError("Error creating vmdk", vixError)

    def createChild(self):
        """
        Creates a redo log from a parent disk.
        """
        raise VixDiskUnimplemented("Currently unimplemented")

    def unlink(self, path):
        """
        Deletes all extents of the specified disk link. If the path refers to a
        parent disk, the child (redo log) will be orphaned.
        Unlinking the child does not affect the parent.
        """
        vixError = VixDiskLib_Unlink(self.conn, PyString_AsString(path))
        if vixError != VIX_OK:
            self._handleError("Error unlinking disk", vixError)
            
    def shrink(self):
        """
        Shrinks an existing disk, only local disks are shrunk.
        """
        vixError = VixDiskLib_Shrink(self.handle, NULL, NULL)
        if vixError != VIX_OK:
            self._handleError("Error shrinking disk", vixError)
        
    def grow(self, path, size, update_geometry=False):
        """
        Grows an existing disk, only local disks are grown.
        """
        if update_geometry:
            truth = TRUE
        else:
            truth = FALSE
        vixError = VixDiskLib_Grow(self.conn, PyString_AsString(path), 
                       size, truth, NULL, NULL)
        if vixError != VIX_OK:
            self._handleError("Error growing disk", vixError)

    def defragment(self):
        """
        Defragments an existing disk.
        """
        vixError = VixDiskLib_Defragment(self.handle, NULL, NULL)
        if vixError != VIX_OK:
            self._handleError("Error defragementing disk", vixError)

    def rename(self, source, destination):
        """
        Renames a virtual disk.
        """
        vixError = VixDiskLib_Rename(PyString_AsString(source), PyString_AsString(destination))
        if vixError != VIX_OK:
            self._handleError("Error renaming disk", vixError)
        

    def clone(self, path, source_connection, source_path, create_params, over_write=True):
        """
        Copies a disk with proper conversion.
        """
        raise VixDiskUnimplemented("Currently unimplemented")

    def attach(self):
        """
        Attaches the child disk chain to the parent disk chain. Parent handle is
        invalid after attaching and child represents the combined disk chain.
        """
        raise VixDiskUnimplemented("Currently unimplemented")

    def needs_repair(self, filename):
        """
        Check a sparse disk for internal consistency.
        """
        cdef bint repair
        vixError = VixDiskLib_CheckRepair(self.conn, PyString_AsString(filename), repair)
        if vixError != VIX_OK:
            self._handleError("Error renaming disk", vixError)
        return repair == TRUE


