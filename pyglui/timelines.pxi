cdef class Timeline(UI_element):
    cdef public RGBA color
    cdef public double point_size, xstart, xstop, ystart, ystop, ypad
    cdef object draw_data, draw_label
    cdef FitBox data_area

    def __cinit__(self, basestring label, object draw_data_callback,
                  object draw_label_callback=None, double content_height=30.,
                  xpad=Vec2(130, 30), ypad=5., *args, **kwargs):
        self.uid = id(self)
        self.label = label
        self.draw_data = draw_data_callback
        self.draw_label = draw_label_callback
        self.ypad = ypad
        self.outline = FitBox(Vec2(0, 0.), Vec2(0, content_height + 2*self.ypad))
        self.data_area = FitBox(Vec2(xpad[0], self.ypad), Vec2(-xpad[1], -self.ypad))

    def __init__(self, *args, **kwargs):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        self.outline.compute(parent)
        self.data_area.compute(self.outline)

        cdef int width, height
        width = int(self.data_area.size.x)
        height = int(self.data_area.size.y)
        if width < 1 or height < 1:
            return

        cdef int vp[4]  # current view port data
        gl.glGetIntegerv(gl.GL_VIEWPORT, &vp[0])
        gl.glPushAttrib(gl.GL_VIEWPORT_BIT)
        cdef int org_y = vp[3] - int(self.data_area.org.y) - int(self.data_area.size.y)

        # setup gl
        gl.glViewport(int(self.data_area.org.x), org_y, width, height)
        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glOrtho(0, width, height, 0, -1, 1)
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()

        self.draw_data(width, height, ui_scale)

        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPopMatrix()
        gl.glPopAttrib()

        width = int(self.data_area.org.x - self.outline.org.x - x_spacer * ui_scale)
        gl.glPushAttrib(gl.GL_VIEWPORT_BIT)
        gl.glViewport(int(self.outline.org.x), org_y, width, height)
        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glOrtho(0, width, height, 0, -1, 1)
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()

        if self.draw_label is None:
            self.draw_label_default(width, height, ui_scale)
        else:
            self.draw_label(width, height, ui_scale)

        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPopMatrix()
        gl.glPopAttrib()

        cdef tuple seperator = ((self.outline.org.x,
                                 self.outline.org.y + self.outline.size.y),
                                (self.outline.org.x + self.outline.size.x,
                                 self.outline.org.y + self.outline.size.y))
        utils.draw_polyline(seperator, color=RGBA(*color_line_default),
                            line_type=gl.GL_LINES, thickness=ui_scale)

    cpdef refresh(self):
        global should_redraw
        should_redraw = True

    @property
    def content_height(self):
        '''gets scale-independent timeline height excluding vertical padding'''
        return self.outline.design_size.y - 2 * self.ypad

    @content_height.setter
    def content_height(self, val):
        '''sets scale-independent timeline height excluding vertical padding'''
        if val != self.content_height:
            self.outline.design_size.y = val + 2 * self.ypad
            self.refresh()

    cpdef draw_label_default(self, width, height, scale):
        glfont.push_state()
        glfont.set_font('opensans')
        glfont.set_size(timeline_label_size * scale)
        glfont.set_blur(.1)
        glfont.set_color_float((1., 1., 1., .8))
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        glfont.draw_text(width, 0, self.label)
