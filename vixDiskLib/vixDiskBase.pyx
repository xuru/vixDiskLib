
import logging, os.path
from vixDiskLib.vixExceptions import VixDiskLibError, VixDiskUnimplemented

from common cimport *
from vddk cimport *
cimport vixBase
cimport numpy as np

# "cimport" is used to import special compile-time information
# about the numpy module (this is stored in a file numpy.pxd which is
# currently part of the Cython distribution).
import numpy as np


from vixBase cimport *

log = logging.getLogger("vixDiskLib.vixDiskBase")

# define our byte type for numpy
DTYPE  = np.uint8
ctypedef np.uint8_t DTYPE_t

cdef int DEFAULT_BLOCK_SIZE     = 1024
cdef uint32 SECTORS_PER_BLOCK   = DEFAULT_BLOCK_SIZE/VIXDISKLIB_SECTOR_SIZE

cdef unsigned short TRUE = 1
cdef unsigned short FALSE = 0

cdef truth(value):
    if value:
        return TRUE
    return FALSE

cdef class VixDiskBase(VixBase):
    """ A file IO interface to the vixDiskLib SDK """
    
    cdef VixDiskLibHandle handle
    cdef np.ndarray buff
    
    def __init__(self, credentials=None, libdir=None, config=None, block_size=DEFAULT_BLOCK_SIZE, callback=None):
        super(VixDiskBase, self).__init__(credentials, libdir, config, callback)
        
        self.vmdk_path = None
        self.opened = False
        self._transport_mode = None
        self._block_size = block_size
        self.sectors_per_block = self._block_size / VIXDISKLIB_SECTOR_SIZE
        
    def getTransportMode(self):
        """
        Returns the current transport mode.  Must be connected.
        
        :return: The transport mode
        """
        if not self.opened:
            raise VixDiskLibError("Transport mode is not available until a disk is opened.")
        return self._transport_mode
    transport_mode = property(getTransportMode)
    
    def getAvailableTransportModes(self):
        """
        Returns a list of available transport modes.
        
        :return: The list of available transport modes
        """
        if not self.opened:
            raise VixDiskLibError("Transport mode is not available until a disk is opened.")
        return VixDiskLib_ListTransportModes().split(":")
    available_modes = property(getAvailableTransportModes)
    
    def _getblocksize(self):
        return self._block_size
    
    def _setblocksize(self, size):
        if size % VIXDISKLIB_SECTOR_SIZE:
            raise VixDiskLibError("block size is not the integral multiple of sector size %d\n" % VIXDISKLIB_SECTOR_SIZE)
        self._block_size = size
    
    block_size = property(_getblocksize, _setblocksize,
                doc="The block size.")

    def open(self, path, single=False):
        """
        Open a vmdk for editing or reading (see readonly)
        
        :param path: Path to the vmdk.  Example: [System-Disk] DEV-BOX-01/DEV-BOX-01.vmdk
        :param single: Open the disk in single mode.
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
        
        :param offset: Absolute offset.
        :param nblocks: Number of blocks to read.
        :return: np.ndarray of bytes
        
        Note: SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE (1048576 or 1MB) / VIXDISKLIB_SECTOR_SIZE (512)
              SECTORS_PER_BLOCK = 2048 sectors
              1 block = 1048576 byts or 1MB
        """
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_read
        
        sectors_to_read = (nblocks * self.sectors_per_block)  # number of sectors to read
        sector_offset = offset * self.sectors_per_block       # from blocks to sectors
        
        nbytes = (sectors_to_read * VIXDISKLIB_SECTOR_SIZE)
        
        if self.buff == None:
            self.buff = np.empty(nbytes, dtype=DTYPE)
            
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
        
        :param offset: Absolute offset.
        :param nblocks: Number of blocks to read.
        :param buff: np.ndarray of bytes
        
        Note: SECTORS_PER_BLOCK = DEFAULT_BLOCK_SIZE (1048576 or 1MB) / VIXDISKLIB_SECTOR_SIZE (512)
              SECTORS_PER_BLOCK = 2048 sectors
              1 block = 1048576 bytes or 1MB
        """
        cdef VixDiskLibSectorType sector_offset
        cdef VixDiskLibSectorType sectors_to_write
        
        sectors_to_write = (nblocks * self.sectors_per_block)  # number of sectors to write
        sector_offset = offset * self.sectors_per_block        # from blocks to sectors
        
        #nbytes = (sectors_to_write * VIXDISKLIB_SECTOR_SIZE)
       
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
            vixError = VixDiskLib_ReadMetadata(self.handle, key, NULL, 0, &requiredLen)
            if vixError != VIX_OK and vixError != VIX_E_BUFFER_TOOSMALL:
                self._handleError("Error getting metadata", vixError)
            
            val = np.ndarray(requiredLen, dtype=np.uint8)
            vixError = VixDiskLib_ReadMetadata(self.handle, key, <char *>val.data, requiredLen, NULL)
            if vixError != VIX_OK:
                self._handleError("Error getting metadata", vixError)
                
            metadata[key] = val.tostring()[:-1]
            key += (1 + strlen(key))
        return metadata
    
    def setMetadata(self, metadata):
        """
        Writes the metadata to the drive.
        
        :param metadata: The metadata to be written to the drive.
        """
        log.debug("Getting metadata for the disk")
        
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        for name, value in metadata.items():
            vixError = VixDiskLib_WriteMetadata(self.handle, PyString_AsString(name), PyString_AsString(value))
            if vixError != VIX_OK:
                self._handleError("Error writing metadata: %s, %s" % (name, value), vixError)
    
    def create(self, path, create_params, local_path=None):
        """
        Creates a disk.
        
        :param path: The path where the disk will be created.
        :param create_params: The `:py:class:VixDiskLib_CreateParams` that will be used to create the disk.
        :param local_path: The path for the local disk, if creating a local disk.
        """
        if not self.connected:
            raise VixDiskLibError("Currently not connected, and trying to open vmdk")
        
        if self.is_remote:
            self._create_remote(path, local_path, create_params)
        else:
            self._create_local(path, create_params)
    
    def _create_local(self, path, create_params):
        cdef VixDiskLibCreateParams params

        params.adapterType  = <VixDiskLibAdapterType>create_params.adapter_type
        # total capacity in sectors
        params.capacity     = create_params.blocks * self.sectors_per_block
        params.diskType     = <VixDiskLibDiskType>create_params.disk_type
        params.hwVersion    = create_params.hw_version
        
        log.debug( "blocks: %d" % create_params.blocks )
        log.debug( "sec/block: %d" % self.sectors_per_block )
        log.debug( "sector size: %d" % VIXDISKLIB_SECTOR_SIZE )
        log.debug( "sectors: %d" % params.capacity )
        
        log.debug( "adapter: %s" % str(create_params.adapter_type) )
        log.debug( "disktype: %s" % str(create_params.disk_type) )
        log.debug( "hwversion: %s" % str(create_params.hw_version) )

        vixError = VixDiskLib_Create(self.conn, path, &params, <VixDiskLibProgressFunc>create_progress_func, NULL)
        if vixError != VIX_OK:
            self._handleError("Error creating vmdk", vixError)
            
    def _create_remote(self, dest_path, local_path, create_params):
        cdef VixDiskLibCreateParams params
        cdef VixDiskLibHandle srcHandle
        
        # 1) make a local connection
        cdef VixDiskLibConnection local_conn
        cdef VixDiskLibConnectParams cnx_params_local
        
        memset(&cnx_params_local, 0, sizeof(cnx_params_local))
        vixError = VixDiskLib_Connect(&cnx_params_local, &local_conn)
        if vixError != VIX_OK:
            self._handleError("Error creating vmdk", vixError)
        
        # 2) create the local disk
        memset(&params, 0, sizeof(params))
        params.adapterType  = <VixDiskLibAdapterType>create_params.adapter_type
        # total capacity in sectors
        params.capacity     = create_params.blocks * self.sectors_per_block
        params.diskType     = <VixDiskLibDiskType>create_params.disk_type
        params.hwVersion    = create_params.hw_version
        
        vixError = VixDiskLib_Create(local_conn, local_path, &(params), NULL, NULL)
        if vixError != VIX_OK:
            self._handleError("Error creating vmdk", vixError)
        
        # 3) Check how much space we'll need
        vixError = VixDiskLib_Open(local_conn, local_path, 0, &srcHandle)
        if vixError != VIX_OK:
            self._handleError("Error opening " + local_path, vixError)
            
        cdef uint64 spaceNeeded
        VixDiskLib_SpaceNeededForClone(srcHandle, VIXDISKLIB_DISK_VMFS_THIN, &spaceNeeded)
        if srcHandle:
            vixError = VixDiskLib_Close(srcHandle)
            if vixError != VIX_OK:
                self._handleError("Error closing "+local_path, vixError)
        print "Required space for cloning: %d" % spaceNeeded
        
        # 4) Start cloning the empty drive over
        vixError = VixDiskLib_Clone(self.conn, dest_path, local_conn, local_path,
                                 &params, <VixDiskLibProgressFunc>clone_progress_func, NULL, TRUE)
        if vixError != VIX_OK:
            self._handleError("Error cloning disk to %s" % dest_path, vixError)

        # 5) Clean up
        vixError = VixDiskLib_Unlink(local_conn, local_path)
        if vixError != VIX_OK:
            self._handleError("Error unlinking disk "+local_path, vixError)
            
        # 6) Disconnect
        VixDiskLib_Disconnect(local_conn)
        
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
        vixError = VixDiskLib_Grow(self.conn, PyString_AsString(path), 
                       size, truth(update_geometry), NULL, NULL)
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

    def needs_repair(self, filename, repair=False):
        """
        Check a sparse disk for internal consistency.
        """
        vixError = VixDiskLib_CheckRepair(self.conn, PyString_AsString(filename), truth(repair))
        if vixError != VIX_OK:
            self._handleError("Error renaming disk", vixError)
        return repair == TRUE



#
# Progress callback for shrink.
#
cdef Bool shrink_progress_func(void * data, int percent):
    return TRUE

#
# Progress callback for Clone.
#
cdef Bool clone_progress_func(void* data, int percent):
    return TRUE

#
# Progress callback for Create.
#
cdef Bool create_progress_func(void* data, int percent):
    print "percent: %d" % percent
    return TRUE

