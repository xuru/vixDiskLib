#!/usr/bin/python

# Copyright (c) 2011 Eric Plaster http://ogremountain.com/
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish, dis-
# tribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the fol-
# lowing conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABIL-
# ITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
'''
vixDiskLib - python wrapper for vixDiskLib (in C)
'''

from distutils.core import setup
import platform
from Cython.Build import cythonize

# we need to make sure we have these to python modules in our path
install_requires = ["Cython", "numpy"]

bits, _ = platform.architecture()
if bits == '32bit':
    libdir = "/usr/lib/vmware-vix-disklib/lib32"
else:
    libdir = "/usr/lib/vmware-vix-disklib/lib64"
    
setup( 
    name = 'vixDiskLib',
    version = open('VERSION').read(),
    description = "vixDiskLib wrapper in Python",
    author = "Eric Plaster",
    author_email = "plaster at gmail.com",
    long_description = "vSphere SDK for Python",
    url = "https://github.com/xuru/vixDiskLib",
    platforms=["any"],
    license = "MIT",
    requires = install_requires,
    ext_modules = cythonize(['vixDiskLib/vixBase.pyx', 'vixDiskLib/vixDiskBase.pyx'], aliases={'VMWARE_LIBDIR': libdir}),
    packages = ["vixDiskLib"],
    classifiers = ['Development Status :: 4 - Beta',
                   'Framework :: VMWare',
                   'Intended Audience :: Developers',
                   'License :: OSI Approved :: MIT License',
                   'Operating System :: OS Independent',
                   'Programming Language :: Python',
                   'Topic :: Software Development :: Libraries :: Python Modules',
                   ],
    )


