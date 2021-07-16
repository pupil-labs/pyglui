# cython: language_level=3
cimport pyglui.pyfontstash.cfontstash as fs


cdef int FONS_ALIGN_LEFT
cdef int FONS_ALIGN_CENTER
cdef int FONS_ALIGN_RIGHT
cdef int FONS_ALIGN_TOP
cdef int FONS_ALIGN_MIDDLE
cdef int FONS_ALIGN_BOTTOM
cdef int FONS_ALIGN_BASELINE
cdef int FONS_ZERO_TOPLEFT
cdef int FONS_ZERO_BOTTOMLEFT


cdef class Context:
    cdef fs.FONScontext * ctx
    cdef dict fonts

    cpdef draw_text(self,float x,float y ,object text)
    cpdef set_color_float(self,tuple color)

    #custom conviniece methods
    cpdef draw_limited_text(self, float x, float y, object text, float width)
    cpdef get_first_char_idx(self, object text, float width)
    cpdef draw_multi_line_text(self, float x, float y, object text, float line_height =*)
    cpdef compute_breaking_text(self, float x, float y, object text, float width,float height,float line_height =*)
    cpdef draw_breaking_text(self, float x, float y, object text, float width,float height,float line_height =*)
    cpdef vertical_metrics(self)
    cpdef char_cumulative_width(self, float x, float y, object text)
