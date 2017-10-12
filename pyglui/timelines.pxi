cdef class Timeline(UI_element):
    cdef public RGBA color
    cdef public float point_size, xstart, xstop, ystart, ystop
    cdef object draw_data

    def __cinit__(self, object draw_callback,
                  float height=30., *args, **kwargs):
        self.uid = id(self)
        self.draw_data = draw_callback
        self.outline = FitBox(Vec2(0., 0.), Vec2(0., height))

    def __init__(self, *args, **kwargs):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        self.outline.compute(parent)
        cdef int vp[4]  # current view port data
        gl.glGetIntegerv(gl.GL_VIEWPORT, &vp[0])
        gl.glPushAttrib(gl.GL_VIEWPORT_BIT)
        cdef int org_y = vp[3] - int(self.outline.org.y) - int(self.outline.size.y)
        gl.glViewport(int(self.outline.org.x), org_y,
                      int(self.outline.size.x), int(self.outline.size.y))
        self.draw_data()
        gl.glPopAttrib()

    cpdef update(self):
        global should_draw
        should_draw = True

    @property
    def height(self):
        return self.outline.design_size.y

    @height.setter
    def height(self, val):
        if val != self.height:
            self.outline.design_size.y = val
            self.update()
