
import logging, time

from common cimport *
from vddk cimport *

from vixDiskLib.vixExceptions import VixDiskLibError, VixDiskUnimplemented
from vddk cimport *

log = logging.getLogger("vixDiskLib.base")

# using a function because cython still has issues with lambdas
def usleep(x):
    return time.sleep(x/1000000.0)

cdef int VIXDISKLIB_VERSION_MAJOR = 1
cdef int VIXDISKLIB_VERSION_MINOR = 2

# Add callback for logging
cdef void LogFunc(char *format, va_list args):
    cdef char buffer[1000]
    PyOS_vsnprintf(buffer, 1000, format, args)
    out = PyString_FromString(buffer)
    log.debug(out)

cdef class VixBase(object):
    
    def __init__(self, credentials=None, libdir=None, config=None, callback=None):
        """
        vixBase - Setup, and connect to the vcenter or ESX server.  Note: vix-disklib 
        requires a vmspec to connect.
        """
        self.cred       = credentials # save for log output
        self.connected  = False
        self._read_only = False
        self.is_remote  = False
        self._libdir    = None
        self._config    = None
        
        if credentials:
            if credentials.vmxSpec:
                
                if not credentials.vmxSpec.startswith("moref="):
                    credentials.vmxSpec = "moref=" + credentials.vmxSpec
                    
            # build up the connect structure
            self.params.vmxSpec             = strdup(PyString_AsString(credentials.vmxSpec))
            self.params.serverName          = strdup(PyString_AsString(credentials.host))
            self.params.creds.uid.userName  = strdup(PyString_AsString(credentials.username))
            self.params.creds.uid.password  = strdup(PyString_AsString(credentials.password))
            self.params.credType            = VIXDISKLIB_CRED_UID
            self.params.port                = 0
            self.is_remote = True
        else:
            memset(&self.params, 0, sizeof(self.params))
        
        if libdir:
            self._libdir = libdir
            
        if config:
            self._config = config
            
        self.initialize()
    
    cdef _handleError(self, msg, int error_num):
        """
        Get the error string from the vix-disklib library using the error number.  Then format the
        information and raise a VixDiskLibError.
        """
        cdef char *cerror = VixDiskLib_GetErrorText(error_num, NULL)
        error = "[%d] %s.  %s" % (error_num, PyString_FromString(cerror), PyString_FromString(msg))
        VixDiskLib_FreeErrorText(cerror)
        raise VixDiskLibError(error)
        
    def cleanup(self):
        """
        Perform a cleanup after an unclean shutdown of an application using vix-disklib.
        """
        cdef uint32 numCleanedUp, numRemaining
        VixDiskLib_Cleanup(&(self.params), &numCleanedUp, &numRemaining)

    def initialize(self):
        """
        Initialize the vix-disklib library and setup logging 
        """
        log.debug("Initializing vixDiskLib")
        if self.is_remote:
            vix_error = VixDiskLib_InitEx(VIXDISKLIB_VERSION_MAJOR, VIXDISKLIB_VERSION_MINOR, 
                                          <VixDiskLibGenericLogFunc*>&LogFunc, 
                                          <VixDiskLibGenericLogFunc*>&LogFunc, 
                                          <VixDiskLibGenericLogFunc*>&LogFunc, 
                                          PyString_AsString(self._libdir), 
                                          PyString_AsString(self._config))
        else:
            vix_error = VixDiskLib_InitEx(VIXDISKLIB_VERSION_MAJOR, VIXDISKLIB_VERSION_MINOR,
                                          NULL, NULL, NULL, NULL, NULL);
        
        if vix_error != VIX_OK:
            self._handleError("Error initializing the vixDiskLib library", vix_error)
        
        # perform a cleanup operation just in case something bad happened last time around...
        self.cleanup()
      
    def finalize(self):
        """
        Frees any memory that we maybe hanging on too.
        """
        if self.connected:
            self.disconnect()
            
        if self.params.vmxSpec != NULL:
            free(self.params.vmxSpec)
        if self.params.serverName != NULL:
            free(self.params.serverName)
        if self.params.creds.uid.userName != NULL:
            free(self.params.creds.uid.userName)
        if self.params.creds.uid.password != NULL:
            free(self.params.creds.uid.password)

        VixDiskLib_Exit()
        
    def __del__(self):
        log.debug("Closing any open connections and exiting")
        self.finalize()
            
    def reset(self):
        """
        Closes any open connections, cleans up, and then reconnects.
        """
        self.finalize()
        usleep(100)
        self.connect()
        
    def connect(self, snapshotRef=None, transport=None, readonly=True):
        """
        Connects the library to the drive using the snapshot reference if provided.
        
        :param snapshotRef: The reference to a snapshot.  This is only needed if we are connecting to a remote disk.
        :param transport: The transport to use.  If not provided, the best match will be selected.
        :param readonly: If true, opens the disk in read only mode.  This is the default.

        """
        
        if hasattr(self.cred, "host"):
            log.debug("Connecting to %s as %s" % (self.cred.host, self.cred.username))
        cdef char *_transport
        cdef char *_snapshotRef
        
        if self.connected:
            raise VixDiskLibError("Already Connected, and trying to connect...")
        
        self._read_only = readonly
        self.initialize()

        _transport = NULL
        if transport:
            _transport = PyString_AsString(transport)
        
        _snapshotRef = NULL
        if snapshotRef:
            _snapshotRef = snapshotRef
            
        vix_error = VixDiskLib_ConnectEx(&(self.params), self._read_only, _snapshotRef, _transport, &(self.conn))
        if vix_error != VIX_OK:
            self._handleError("Error connecting to %s" % self.params.serverName, vix_error)
            
        self.connected = True
        
    def disconnect(self):
        """
        Disconnects the library from the drive.  This will call `:py:meth:VixBase.cleanup`.
        """

        if hasattr(self.cred, "host"):
            log.debug("Disconnecting from %s" % self.cred.host)
        
        if not self.connected:
            raise VixDiskLibError("Not Connected, and trying to disconnect...")
        
        VixDiskLib_Disconnect(self.conn)
        
        # clean up after disconnecting just in case...
        self.cleanup()
        
        self.connected = False
        
    ################################################################################
    # Properties    
    ################################################################################
    def _getconfig(self):
        return self._config
    
    def _setconfig(self, path):
        self._config = path
                
    def _getlibdir(self):
        return self._libdir
    
    def _setlibdir(self, path):
        self._libdir = path
                
    def _getreadonly(self):
        return self._read_only
    
    def _setreadonly(self, truth):
        self._read_only = truth
                
    readonly = property(_getreadonly, _setreadonly,
                doc="The read only flag upon connection.")
    libdir = property(_getlibdir, _setlibdir,
                doc="The location of the vix-disklib libraries.")
    config = property(_getconfig, _setconfig,
                doc="The location of the vix-disklib configuration file.")
        
        
        
        
