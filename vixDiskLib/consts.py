'''
Created on Feb 15, 2011

@author: eplaster
'''

VixDiskLibDiskType = dict(
        MONOLITHIC_SPARSE=1,
        MONOLITHIC_FLAT=2,
        SPLIT_SPARSE=3,
        SPLIT_FLAT=4,
        VMFS_FLAT=5,
        STREAM_OPTIMIZED=6,
        VMFS_THIN=7,
        VMFS_SPARSE=8,
        UNKNOWN=256)
    
# Disk adapter types
VixDiskLibAdapterType = dict(
        IDE=1,
        SCSI_BUSLOGIC=2,
        SCSI_LSILOGIC=3,
        UNKNOWN=256)

#   Currently the default is VIXDISKLIB_HWVERSION_WORKSTATION_6, although this could change.
#   VMware Workstation 6.5 and VMware Server 2.0 use virtual hardware version 7 for hot-plug devices.
#   Virtual hardware version 5 was never public. 

VixDiskLibHwVersion = dict(
        WORKSTATION_4 = 3,
        WORKSTATION_5 = 4,
        ESX30 = 4,
        WORKSTATION_6 = 6,
        ESXi4x = 7,
        CURRENT = 7 )

VixDiskOpenFlags = dict( UNBUFFERED = 0, SINGLE_LINK = 1, READ_ONLY = 4)


VixDiskTransportModes = ['file', 'san', 'hotadd', 'ndbssl', 'ndb']
