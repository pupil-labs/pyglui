import os, platform
import numpy

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

if platform.system() == 'Darwin':
	includes = ['/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/']
	f = '-framework'
	link_args = [f, 'OpenGL']
	libs = []
else:
    includes = ['/usr/include/GL',]
    libs = ['GL']
    link_args = []


extensions = [
	Extension(	name="ui",
				sources=['ui.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]),
]

setup( 	name="pyglui",
		version="0.0.1",
		description="OpenGL UI using Nanovg",
		ext_modules=cythonize(extensions)
)