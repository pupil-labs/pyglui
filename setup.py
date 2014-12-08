import os, platform
from stat import ST_MTIME

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

from pyglui.cygl.glew_pxd import generate_pxd
if platform.system() == 'Darwin':
    glew_header = '/usr/local/Cellar/glew/1.10.0/include/GL/glew.h'
    includes = ['/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/','pyglui/cygl']
    link_args = []
    libs = ['GLEW']
    libglew = [] #we are using the dylib
elif platform.system() == 'Linux':
    glew_header = '/usr/include/GL/glew.h'
    includes = ['/usr/include/GL','pyglui/cygl','pyglui/cygl']
    libs = ['GLEW']
    link_args = []
else:
    raise Exception('Platform build not implemented.')


if os.path.isfile('pyglui/cygl/glew.pxd') and os.stat('pyglui/cygl/glew.pxd')[ST_MTIME] > os.stat(glew_header)[ST_MTIME]:
    print "'glew.pxd' is up-to-date."
else:
    generate_pxd(glew_header,'pyglui/cygl')


extensions = [
	Extension(	name="pyglui.ui",
				sources=['pyglui/ui.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=["-Wno-strict-aliasing", "-O2"]),

	Extension(	name="pyglui.graph",
				sources=['pyglui/graph.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=["-Wno-strict-aliasing", "-O2"]),

	Extension(	name="pyglui.cygl.utils",
				sources=['pyglui/cygl/utils.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=[]),

	Extension(	name="pyglui.cygl.shader",
				sources=['pyglui/cygl/shader.pyx'],
				include_dirs = includes,
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=["-Wno-strict-aliasing", "-O2"]),

	Extension(	name="pyglui.pyfontstash.fontstash",
				sources=['pyglui/pyfontstash/fontstash.pyx'],
				include_dirs = includes+['pyglui/pyfontstash/fontstash/src'],
				libraries = libs,
				extra_link_args=link_args,
				extra_compile_args=["-Wno-strict-aliasing", "-O2"]+['-D FONTSTASH_IMPLEMENTATION','-D GLFONTSTASH_IMPLEMENTATION'])
]

setup( 	name="pyglui",
		version="0.0.1",
		packages = ['pyglui'],
		py_modules = ['pyglui.cygl.__init__','pyglui.pyfontstash.__init__'], #add  __init__.py files
		description="OpenGL UI powered by cython",
        package_dir={'pyglui':'pyglui'},
        package_data={'pyglui': ['*.ttf']}, #fonts
		ext_modules=cythonize(extensions)
)