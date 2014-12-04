import os, platform

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

if platform.system() == 'Darwin':
    includes = ['/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/']
    f = '-framework'
    link_args = [f, 'OpenGL']
    libs = []
    gl_compile_args = []


else:
    includes = ['/usr/include/GL',]
    libs = ['GL']
    link_args = []
    gl_compile_args = ['-D GL_GLEXT_PROTOTYPES']



extensions = [
	Extension(	name="pyglui.ui",
				sources=['pyglui/ui.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]+gl_compile_args),

	Extension(	name="pyglui.graph",
				sources=['pyglui/graph.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]+gl_compile_args),

	Extension(	name="pyglui.cygl.utils",
				sources=['pyglui/cygl/utils.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]+gl_compile_args),

	Extension(	name="pyglui.cygl.shader",
				sources=['pyglui/cygl/shader.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]+gl_compile_args),

	Extension(	name="pyglui.pyfontstash.fontstash",
				sources=['pyglui/pyfontstash/fontstash.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=['-D FONTSTASH_IMPLEMENTATION','-D GLFONTSTASH_IMPLEMENTATION'])
]

setup( 	name="pyglui",
		version="0.0.1",
		packages = ['pyglui'],
		py_modules = ['pyglui.cygl.__init__','pyglui.pyfontstash.__init__'], #add  __init__.py files
		description="OpenGL UI powered by cython",
		ext_modules=cythonize(extensions)
)