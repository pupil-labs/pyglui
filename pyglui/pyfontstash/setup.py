import platform

from Cython.Build import cythonize
from setuptools import Extension, setup

if platform.system() == "Darwin":
    includes = ["/System/Library/Frameworks/OpenGL.framework/Versions/Current/Headers/"]
    f = "-framework"
    link_args = [f, "OpenGL"]
    libs = []
    compile_args = ["-D FONTSTASH_IMPLEMENTATION", "-D GLFONTSTASH_IMPLEMENTATION"]
elif platform.system() == "Windows":
    includes = []
    libs = ["OpenGL32"]
    link_args = []
    compile_args = [
        "/DFONTSTASH_IMPLEMENTATION",
        "/DGLFONTSTASH_IMPLEMENTATION",
    ]  # http://msdn.microsoft.com/de-de/library/hhzbb5c8.aspx
else:
    includes = [
        "/usr/include/GL",
    ]
    libs = ["GL"]
    link_args = []
    compile_args = ["-D FONTSTASH_IMPLEMENTATION", "-D GLFONTSTASH_IMPLEMENTATION"]

extensions = [
    Extension(
        name="fontstash",
        sources=["fontstash.pyx"],
        include_dirs=includes + ["fontstash/src"],
        libraries=libs,
        extra_link_args=link_args,
        extra_compile_args=compile_args,
    )
]

# this package will be compiled into a single.so file.
setup(
    name="pyfontstash",
    version="0.2",
    author="Moritz Kassner",
    license="MIT",
    description="OpenGL font rendering. This module can also be used as a submodule for other cython projects that want to use OpenGL.",
    ext_modules=cythonize(extensions),
)
