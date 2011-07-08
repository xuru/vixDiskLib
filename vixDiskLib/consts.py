'''
Created on Feb 15, 2011

@author: eplaster
'''
import collections

class Enum(collections.Mapping):
    """Enum is a subclass of :class:`collections.Mapping`, implementing comparison
    methods adhering to precedence rules."""
    
    def __init__(self, *argv, **kwargs):
        super(Enum, self).__init__(*argv, **kwargs)
        self.data = {}

    def labels(self, *args, **kwargs):
        for item in args:
            self.data[item] = item
        for n,v in kwargs.items():
            self.data[n] = v
        return self
        
    def compare(self, other, fun, default=False):
        return fun(self.precedence(self), self.precedence(other))

    def __gt__(self, other):
        return self.compare(other, lambda a, b: a < b, True)

    def __ge__(self, other):
        return self.compare(other, lambda a, b: a <= b, True)

    def __lt__(self, other):
        return self.compare(other, lambda a, b: a > b, False)

    def __le__(self, other):
        return self.compare(other, lambda a, b: a >= b, False)
    
    def __len__(self):
        return len([x for x in self.data.values() if x[0] != "_"])
    
    def __iter__(self):
        return iter(self.data)
    
    def __getitem__(self, item):
        return self.data[item]
    
    def __getattr__(self, item):
        return self.data[item]
    
    def precedence(self, item):
        """Get the precedence index for item.
    
        Lower index means higher precedence.
    
        """
        try:
            return self.PRECEDENCE.index(item)
        except ValueError:
            return self.PRECEDENCE.index(None)
    
VixDiskLibDiskType = Enum().labels( 
        "VIXDISKLIB_DISK_MONOLITHIC_SPARSE",
        "VIXDISKLIB_DISK_MONOLITHIC_FLAT",
        "VIXDISKLIB_DISK_SPLIT_SPARSE",
        "VIXDISKLIB_DISK_SPLIT_FLAT",
        "VIXDISKLIB_DISK_VMFS_FLAT",
        "VIXDISKLIB_DISK_STREAM_OPTIMIZED",
        "VIXDISKLIB_DISK_VMFS_THIN",
        "VIXDISKLIB_DISK_VMFS_SPARSE",
        VIXDISKLIB_DISK_UNKNOWN=256)
    
# Disk adapter types
VixDiskLibAdapterType = Enum().labels(
        "VIXDISKLIB_ADAPTER_IDE",
        "VIXDISKLIB_ADAPTER_SCSI_BUSLOGIC",
        "VIXDISKLIB_ADAPTER_SCSI_LSILOGIC",
        VIXDISKLIB_ADAPTER_UNKNOWN=256)

VixDiskOpenFlags = Enum().labels( "UNBUFFERED", "SINGLE_LINK", READ_ONLY = 4)


