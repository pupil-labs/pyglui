import os, platform
import numpy

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

if platform.system() == 'Darwin':
	includes = []
	f = '-framework'
	link_args = [] # f, 'Cocoa', f, 'IOKit', f, 'CoreVideo'
	libs = []
else:
    includes = []
    libs = []
    link_args = []


# extra_objects=["../build/libnanovg.a"]

extensions = [
	Extension(	name="ui",
				sources=['ui.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				#backend is hardcoded. also look at the pyd and pyx files. ToDo: make this smart.
				# use any of the following: NANOVG_GL2_IMPLEMENTATION,NANOVG_GL3_IMPLEMENTATION,NANOVG_GLES2_IMPLEMENTATION,NANOVG_GLES3_IMPLEMENTATION
				extra_compile_args=[]),
]

setup( 	name="pyglui",
		version="0.0.1",
		description="OpenGL UI using Nanovg",
		ext_modules=cythonize(extensions)
)