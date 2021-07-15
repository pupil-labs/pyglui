# cython: language_level=3

cimport pyglui.cygl.glew as gl


cdef class Shader:
    cdef dict uniforms
    cdef bytes _vertex_code, _fragment_code, _geometry_code
    cdef public gl.GLuint handle
    cdef bint linked

    cdef _build_shader(self, const char * strings, shader_type)

    cdef _link(self)

    cpdef bind(self)

    cpdef unbind(self)

    cpdef uniformi(self, str name, vals)

    cpdef uniformf(self, str name, vals)

    cpdef uniform1f(self, str name,float val)

    cpdef uniform1i(self, str name,int val)

    cpdef uniform_matrixf(self, str name, float[:] mat)

    cdef _get_shader_info(self,gl.GLuint shader)

    cdef _get_program_info(self)
