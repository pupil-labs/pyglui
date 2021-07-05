"""
Script taken from: https://github.com/orlp/pygrafix
Appropriate Licence applies!
"""

import argparse
import os
import pathlib
import re


def generate_pxd(glew_header_loc, dest="."):
    with open(glew_header_loc) as fin:
        data = fin.read()

    # cython doesn't support const
    data = re.sub(r"\bconst\b", "", data)

    lines = data.split("\n")

    handled_lines = set()
    function_types = {}
    export_functions = {}
    function_defs = []
    enums = []

    # read in function types
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"typedef\s+([^(]+)\([^*]+\*\s*([a-zA-Z_][a-zA-Z0-9_]+)\)\s*(\(.+\))\s*;",
                line,
            )[0]
        except IndexError:
            continue

        function_types[result[1]] = (result[0].strip(), result[2])
        handled_lines.add(linenr)

    # read in exported functions
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"GLEW_FUN_EXPORT\s+([a-zA-Z_][a-zA-Z0-9_]+)\s+([a-zA-Z_][a-zA-Z0-9_]+)",
                line,
            )[0]
        except IndexError:
            continue

        export_functions[result[1]] = result[0]
        handled_lines.add(linenr)

    # match exported functions with function types
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"#define\s+([a-zA-Z_][a-zA-Z0-9_]+)\s+GLEW_GET_FUN\s*\(\s*([a-zA-Z_][a-zA-Z0-9_]+)\s*\)",
                line,
            )[0]
        except IndexError:
            continue

        export_func = export_functions[result[1]]
        function_defs.append(
            function_types[export_func][0]
            + " "
            + result[0]
            + function_types[export_func][1]
        )
        handled_lines.add(linenr)

    # add GLAPIENTRY functions
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"GLAPI\s+([a-zA-Z_][a-zA-Z0-9_]+)[^a-zA-Z_]+GLAPIENTRY[^a-zA-Z_]+([a-zA-Z_][a-zA-Z0-9_]+)\s*(\(.+\))\s*;",
                line,
            )[0]
        except IndexError:
            continue

        function_defs.append(" ".join(result))
        handled_lines.add(linenr)

    # read in numeric defines as enums
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"#define\s+([a-zA-Z_][a-zA-Z0-9_]+)\s+(?:(?:0x[0-9a-fA-F]+)|[0-9]+)",
                line,
            )[0]
        except IndexError:
            continue

        enums.append(result)
        handled_lines.add(linenr)

    # read in GLEW vars as enums
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"#define\s+([a-zA-Z_][a-zA-Z0-9_]+)\s+GLEW_GET_VAR\(.+\)", line
            )[0]
        except IndexError:
            continue

        enums.append(result)
        handled_lines.add(linenr)

    # also accept GL to GL defines as enums
    for linenr, line in enumerate(lines):
        try:
            result = re.findall(
                r"#define\s+(GL_[a-zA-Z0-9_]+)\s+GL_[a-zA-Z0-9_]+", line
            )[0]
        except IndexError:
            continue

        enums.append(result)
        handled_lines.add(linenr)

    pxdheader = """# cython: language_level=3
from libc.stdint cimport int64_t, uint64_t

cdef extern from "include_glew.h":
    ctypedef struct _cl_context:
        pass
    ctypedef struct _cl_event:
        pass
    ctypedef struct __GLsync:
        pass

    ctypedef unsigned short wchar_t
    ctypedef int ptrdiff_t

    ctypedef unsigned int GLenum
    ctypedef unsigned int GLbitfield
    ctypedef unsigned int GLuint
    ctypedef int GLint
    ctypedef int GLsizei
    ctypedef char GLchar
    ctypedef unsigned char GLboolean
    ctypedef signed char GLbyte
    ctypedef short GLshort
    ctypedef unsigned char GLubyte
    ctypedef unsigned short GLushort
    ctypedef unsigned long GLulong
    ctypedef float GLfloat
    ctypedef float GLclampf
    ctypedef double GLdouble
    ctypedef double GLclampd
    ctypedef int GLfixed
    ctypedef int GLclampx
    ctypedef void GLvoid

    ctypedef int64_t GLint64EXT
    ctypedef uint64_t GLuint64EXT
    ctypedef GLint64EXT GLint64
    ctypedef GLuint64EXT GLuint64
    ctypedef __GLsync *GLsync
    ctypedef char GLcharARB
    ctypedef ptrdiff_t GLintptr
    ctypedef ptrdiff_t GLsizeiptr
    ctypedef _cl_context *cl_context
    ctypedef _cl_event *cl_event
    ctypedef unsigned int GLhandleARB
    ctypedef ptrdiff_t GLintptrARB
    ctypedef ptrdiff_t GLsizeiptrARB
    ctypedef void* GLeglClientBufferEXT
    ctypedef unsigned short GLhalf
    ctypedef GLintptr GLvdpauSurfaceNV
    ctypedef long GLVULKANPROCNV

    ctypedef void *GLeglImageOES  # GL_EXT_EGL_image_storage

    ctypedef void (__stdcall *GLDEBUGPROCAMD)(GLuint id, GLenum category, GLenum severity, GLsizei length, GLchar *message, GLvoid *userParam)
    ctypedef void (__stdcall *GLDEBUGPROCARB)(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, GLchar *message, GLvoid *userParam)

    ctypedef void (__stdcall *GLDEBUGPROC)(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message, GLvoid* userParam)
    ctypedef void (__stdcall *GLLOGPROCREGAL)(GLenum stream, GLsizei length, const GLchar *message, GLvoid *context)


    GLenum glewInit()
    GLboolean glewIsSupported(char *name)
    GLboolean glewIsExtensionSupported(char *name)
    GLboolean glewGetExtension(char* name)
    GLubyte *glewGetErrorString(GLenum error)
    GLubyte *glewGetString(GLenum name)


"""

    dest = pathlib.Path(dest)
    dest.mkdir(exist_ok=True, parents=True)
    with (dest / "glew.pxd").open("w") as fout:
        data = pxdheader

        data += "    enum:\n"
        data += "\n".join("        " + enum for enum in set(enums))
        data += "\n\n"

        def mod_func(func):
            keywords = [
                "and",
                "del",
                "for",
                "is",
                "raise",
                "assert",
                "elif",
                "from",
                "lambda",
                "return",
                "break",
                "else",
                "global",
                "not",
                "try",
                "class",
                "except",
                "if",
                "or",
                "while",
                "continue",
                "exec",
                "import",
                "pass",
                "yield",
                "def",
                "finally",
                "in",
                "print",
            ]

            # beautify functions
            func = re.sub(r"\s+", " ", func)  # collapse whitespace
            func = re.sub(r"\s*([()])\s*", r"\1", func)  # no whitespace near brackets
            func = re.sub(r"\s*,\s*", r", ", func)  # only whitespace __after__ comma
            func = re.sub(
                r"\s*(\*+)\s*", r" \1", func
            )  # beautify pointers in functions

            # cython doesn't support (void), need to do () for no arguments instead
            func = re.sub(r"\(void\)", "()", func)

            # keywords...
            for keyword in keywords:
                func = re.sub(r"\b%s\b" % keyword, keyword + "_", func)

            return func

        data += "\n".join("    " + mod_func(func) for func in function_defs)

        fout.write(data)

    with (dest / "unhandled_glew.h").open("w") as fout:
        data = "\n".join(
            lines[linenr] for linenr in range(len(lines)) if linenr not in handled_lines
        )
        data = re.sub("\n\n+", "\n", data)
        fout.write(data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("glew_header_loc")
    parser.add_argument("destination")
    args = parser.parse_args()
    generate_pxd(args.glew_header_loc, dest=args.destination)
