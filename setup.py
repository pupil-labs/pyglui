import os
import pathlib
import platform
import sys
from stat import ST_MTIME

import numpy
import pkgconfig
from Cython.Build import cythonize
from setuptools import Extension, setup

includes = ["src/pyglui/cygl/", ".", numpy.get_include()]
glew_binaries = []
lib_dir = []
link_args = []
fontstash_compile_args = [
    "-D FONTSTASH_IMPLEMENTATION",
    "-D GLFONTSTASH_IMPLEMENTATION",
]


def get_cysignals_include():
    import cysignals

    return cysignals.__path__[0]


if platform.system() == "Darwin":
    # find glew irrespective of version
    pkgconfig_glew = pkgconfig.parse("glew")
    includes += pkgconfig_glew["include_dirs"]
    lib_dir += pkgconfig_glew["library_dirs"]
    libs = pkgconfig_glew["libraries"]
    extra_compile_args = ["-Wno-strict-aliasing", "-O2"]

    # OpenGL + cysignal headers
    includes += [
        "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/",
        "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/OpenGL.framework/Headers/",
        get_cysignals_include(),
    ]

    # find glew.h to generate glew.pxd later
    for include in pkgconfig_glew["include_dirs"]:
        for glew_header in pathlib.Path(include).rglob("glew.h"):
            # convert from Path to str
            glew_header = str(glew_header)
            break

elif platform.system() == "Linux":
    glew_header = "/usr/include/GL/glew.h"
    includes += ["/usr/include/GL", get_cysignals_include()]
    libs = ["GLEW", "GL"]  # GL needed for fonstash
    extra_compile_args = ["-Wno-strict-aliasing", "-O2"]
elif platform.system() == "Windows":
    glew_header = "src/pyglui/cygl/win_glew/gl/glew.h"
    includes += ["src/pyglui/cygl/win_glew"]
    libs = ["glew32", "OpenGL32"]
    lib_dir = ["src/pyglui/cygl/win_glew"]
    link_args = []
    gl_compile_args = []  # ['/DGL_GLEXT_PROTOTYPES']
    extra_compile_args = ["-O2"]
    fontstash_compile_args = [
        "/DFONTSTASH_IMPLEMENTATION",
        "/DGLFONTSTASH_IMPLEMENTATION",
    ]
else:
    raise Exception("Platform build not implemented.")

includes_fontstash = ["src/pyglui/pyfontstash/fontstash/src"]

extensions = [
    Extension(
        name="pyglui.ui",
        sources=["src/pyglui/ui.pyx"],
        include_dirs=includes + includes_fontstash,
        libraries=libs,
        library_dirs=lib_dir,
        extra_link_args=link_args,
        extra_compile_args=extra_compile_args,
        language="c++",
        define_macros=[("GL_SILENCE_DEPRECATION", "1")],
    ),
    Extension(
        name="pyglui.graph",
        sources=["src/pyglui/graph.pyx"],
        include_dirs=includes + includes_fontstash,
        libraries=libs,
        library_dirs=lib_dir,
        extra_link_args=link_args,
        extra_compile_args=extra_compile_args,
        language="c++",
        define_macros=[("GL_SILENCE_DEPRECATION", "1")],
    ),
    Extension(
        name="pyglui.cygl.utils",
        sources=["src/pyglui/cygl/utils.pyx"],
        include_dirs=includes,
        libraries=libs,
        library_dirs=lib_dir,
        extra_link_args=link_args,
        extra_compile_args=extra_compile_args,
        language="c++",
    ),
    Extension(
        name="pyglui.cygl.shader",
        sources=["src/pyglui/cygl/shader.pyx"],
        include_dirs=includes,
        libraries=libs,
        library_dirs=lib_dir,
        extra_link_args=link_args,
        extra_compile_args=extra_compile_args,
        language="c++",
    ),
    Extension(
        name="pyglui.pyfontstash.fontstash",
        sources=["src/pyglui/pyfontstash/fontstash.pyx"],
        include_dirs=includes + includes_fontstash,
        libraries=libs,
        library_dirs=lib_dir,
        extra_link_args=link_args,
        extra_compile_args=extra_compile_args + fontstash_compile_args,
        define_macros=[("GL_SILENCE_DEPRECATION", "1")],
    ),
]

should_cythonize = any(
    not pathlib.Path(sfile)
    .with_suffix(".cpp" if extension.language == "c++" else ".c")
    .exists()
    for extension in extensions
    for sfile in extension.sources
    if pathlib.Path(sfile).suffix == ".pyx"
)
if should_cythonize:
    # 1. generate additional cython files
    print(f"Generating glew.pxd based on {glew_header}")

    dir_glew_generator = pathlib.Path("scripts")
    dir_glew_destination = pathlib.Path("src", "pyglui", "cygl")

    print(f"Adding {dir_glew_generator} to sys.path")
    sys.path.append(str(dir_glew_generator))
    from glew_pxd import generate_pxd

    print(f"Removing {dir_glew_generator} from sys.path")
    sys.path.remove(str(dir_glew_generator))
    print(f"Writing glew.pxd to {dir_glew_destination}")
    generate_pxd(glew_header, dir_glew_destination)

    # 2. cythonize
    extensions = cythonize(extensions)
else:
    # Replace cython files with compiled c(++) sources
    # https://cython.readthedocs.io/en/latest/src/userguide/source_files_and_compilation.html
    for extension in extensions:
        sources = []
        for sfile in extension.sources:
            sfile = pathlib.Path(sfile)
            path, ext = os.path.splitext(sfile)
            if sfile.suffix == ".pyx":
                ext = ".cpp" if extension.language == "c++" else ".c"
                sfile = sfile.with_suffix(ext)
            sources.append(str(sfile))
        extension.sources[:] = sources

setup(ext_modules=extensions)
