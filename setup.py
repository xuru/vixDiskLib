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
from Cython.Distutils import extension, build_ext
import subprocess, os, time, sys
import os.path

# make sure when we import vixDiskLib that it's the one in the current directory
sys.path.insert(0, os.path.abspath(__file__))

#################################################################################
# Helper functions for setup
#################################################################################
def run(cmd, wait=True, timeout=30):
    result = ""

    p = subprocess.Popen(cmd, shell=False, env=os.environ, stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if wait:
        result = p.communicate("\n")[0].strip()
        if p.returncode != 0:
            raise RuntimeError('Error executing %r: %r' % (cmd, result))
    else:
        p.stdin.write("\n")
        for x in range(timeout):
            rc = p.poll()
            if rc == None:
                # process hasn't terminated yet...
                print "%d seconds and still running..." % x
                time.sleep(1)
            else:
                break
    return result.strip()

def run_pkg_config(packages):
    args = ['pkg-config', '--libs', '--cflags'] + list(packages)
    return run(args)

def pkgconfig(*packages, **kwargs):
    flag_map = {'-I': 'include_dirs', '-L': 'library_dirs', '-l': 'libraries'}
    for token in run_pkg_config(packages).split():
        kwargs.setdefault(flag_map.get(token[:2]), []).append(token[2:])
    return kwargs

#################################################################################
# Setup the libraries and include paths for vixDiskLib (VDDK)
#################################################################################
kw = pkgconfig('vix-disklib')
# we need to make sure that we include the vixDiskLibVim library
kw['libraries'].append('vixDiskLibVim')
kw['include_dirs'].append('vixDiskLib')
print kw
ext_modules = [
    extension.Extension('vixDiskLib.vixBase', ['vixDiskLib/vixBase.pyx'], **kw), #IGNORE:W0142
    extension.Extension('vixDiskLib.vixDiskBase', ['vixDiskLib/vixDiskBase.pyx'], **kw), #IGNORE:W0142
]

# we need to make sure we have these to python modules in our path
install_requires = ["cython"]

setup( 
    name = 'vixDiskLib',
    version = open('VERSION').read(),
    description = "vixDiskLib wrapper in Python",
    author = "Eric Plaster",
    author_email = "plaster at gmail.com",
    long_description = "vSphere SDK for Python",
    url = "https://github.com/xuru/vixDiskLib",
    platforms=["any"],
    zip_safe=False,
    license = "MIT",
    cmdclass = {'build_ext': build_ext},
    ext_modules = ext_modules,
    install_requires = install_requires,
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


