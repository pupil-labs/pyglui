import os, platform
from stat import ST_MTIME

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

from pyglui.cygl.glew_pxd import generate_pxd


includes = ['pyglui/cygl/','.']
if platform.system() == 'Darwin':
    glew_header = '/usr/local/Cellar/glew/1.10.0/include/GL/glew.h'
    includes += ['/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/']
    link_args = []
    libs = ['GLEW']
    libglew = [] #we are using the dylib
elif platform.system() == 'Linux':
    glew_header = '/usr/include/GL/glew.h'
    includes += ['/usr/include/GL']
    libs = ['GLEW']
    link_args = []
else:
    raise Exception('Platform build not implemented.')


if os.path.isfile('pyglui/cygl/glew.pxd') and os.stat('pyglui/cygl/glew.pxd')[ST_MTIME] > os.stat(glew_header)[ST_MTIME]:
    print "'glew.pxd' is up-to-date."
else:
    print "generating glew.pxd based on '%s'"%glew_header
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

from pyglui import __version__ as pyglui_version
# from pyglui.pyfontstash import __version__ as fs_version
# from pyglui.cygl import __version__ as cygl_version



setup( 	name="pyglui",
		version=pyglui_version,
		packages = ['pyglui'],
		py_modules = ['pyglui.cygl.__init__','pyglui.pyfontstash.__init__'], #add  __init__.py files
		description="OpenGL UI powered by Cython",
		url="https://github.com/pupil-labs/pyglui",
		author='Pupil Labs',
		author_email='info@pupil-labs.com',
		license='MIT',
        package_dir={'pyglui':'pyglui'},
        package_data={'pyglui': ['*.ttf']}, #fonts
		ext_modules=cythonize(extensions)
)
