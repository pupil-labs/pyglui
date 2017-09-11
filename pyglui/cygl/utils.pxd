from glew cimport *
from libcpp.vector cimport vector

cdef class RGBA:
    cdef public float r,g,b,a

cpdef init()

cpdef draw_polyline(verts,float thickness=*,RGBA color=*,line_type =*)
cpdef draw_polyline_norm(verts,float thickness=*,RGBA color=*,line_type =*)

cpdef draw_points(points,float size=*,RGBA color=*,float sharpness=*)
cpdef draw_circle(center_position=*,float radius=*,float stroke_width=*, RGBA color=*,float sharpness=*)
cpdef draw_points_norm(points,float size=*,RGBA color=*,float sharpness=*)


ctypedef struct fbo_tex_id:
    GLuint fbo_id
    GLuint tex_id

cdef class Render_Target:
    cdef fbo_tex_id fbo_tex

cdef class Named_Texture:
    cdef GLuint texture_id
    cdef bint use_yuv_shader

cdef class Sphere:
    cdef GLuint vertex_buffer_id
    cdef GLuint index_buffer_id
    cdef int vertex_buffer_size
    cdef int index_buffer_size
    cdef int indices_amount

cpdef push_ortho(int w,int h)
cpdef pop_ortho()
