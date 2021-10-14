# cython: language_level=3
from cython cimport view

from pyglui.ui import get_opensans_font_path, get_roboto_font_path

from pyglui.cygl cimport glew as gl
from pyglui.cygl.utils cimport RGBA
# pyfontstash needs to be import AFTER pyglui.cygl.glew
from pyglui.pyfontstash cimport fontstash as fs

from os import path

__version__ = "1.31.0"


# legacy push and pop

def push_view(int w, int h):
    pass

def pop_view():
    pass


cdef class Bar_Graph:
    cdef fs.Context glfont
    cdef double[::1] data
    cdef public float avg, bar_width, min_val, max_val
    cdef float scale
    cdef int idx,d_len
    cdef int x, y, win_height, win_width
    cdef basestring label
    cdef int s_idx,s_size
    cdef object data_source
    cdef public RGBA color

    def __cinit__(self,int data_points = 25,float min_val = 0, float max_val = 100):
        self.data = view.array(shape=(data_points,), itemsize=sizeof(double), format="d")
        self.d_len = data_points
        self.label = 'Title %0.2f units'
        self.bar_width = 4
        self.min_val = min_val
        self.max_val = max_val
        self.scale = 1

        self.glfont = fs.Context()
        self.glfont.add_font('opensans', get_opensans_font_path())
        self.glfont.set_size(int(18*self.scale))
        self.color = RGBA(0.5, 0.8, 0.75,.5)

    def __init__(self,int data_points = 25,float min_val = 0, float max_val = 100):
        cdef int x
        for x in range(data_points):
            self.data[x] = 0
        self.avg = 0
        self.data_source = lambda: 0

    def adjust_window_size(self, w, h):
        self.win_width = w
        self.win_height = h

    property label:
        def __get__(self):
            return self.label
        def __set__(self,new_label):
            self.label = new_label

    property scale:
        def __get__(self):
            return self.scale

        def __set__(self,val):
            self.scale = val
            self.glfont.set_size(int(18*self.scale))

    property pos:
        def __get__(self):
            return self.x,self.y

        def __set__(self,val):
            self.x,self.y = val

    property update_rate:
        def __set__(self,r):
            self.s_size = r
            self.s_idx = 0

        def __get__(self):
            return self.s_size

    property update_fn:
        def __set__(self,fn):
            self.data_source = fn

    def add(self,double val):
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(5./self.d_len)

    def update(self):
        cdef float val
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            val = self.data_source()
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(2./self.d_len)


    def draw(self):
        cdef int i
        cdef float x=0
        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glOrtho(0, self.win_width, self.win_height, 0, -1, 1)

        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glTranslatef(self.x*self.scale,self.y*self.scale,0)
        #scale such that a bar at max val is 100px high
        gl.glPushMatrix()
        gl.glScalef(1,-30.*self.scale/self.max_val,1)
        gl.glTranslatef(0,self.min_val*self.scale,0)

        ##draw background
        #gl.glColor4f(.0,.0,.0,.2)
        #gl.glBegin(gl.GL_POLYGON)
        #gl.glVertex3f(0,0,0.0)
        #gl.glVertex3f(100,0,0.0)
        #gl.glVertex3f(100,100,0.0)
        #gl.glVertex3f(0,100,0.0)
        #gl.glEnd()
        #draw bars
        gl.glLineWidth(self.bar_width*self.scale)
        gl.glColor4f(self.color.r,self.color.g,self.color.b,self.color.a)
        gl.glBegin(gl.GL_LINES)

        #if self.s_size:
        #    x -= self.s_idx/float(self.s_size) * 4

        for i in range(self.idx,self.d_len):
            gl.glVertex3f(x*self.scale,0,0)
            gl.glVertex3f(x*self.scale,self.data[i],0)
            x += self.bar_width

        for i in range(self.idx):
            gl.glVertex3f(x*self.scale,0,0)
            gl.glVertex3f(x*self.scale,self.data[i],0)
            x += self.bar_width

        gl.glEnd()
        gl.glPopMatrix()


        self.glfont.draw_text(0,-3,self.label%self.avg)
        gl.glPopMatrix()

        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_MODELVIEW)



cdef class Line_Graph:
    cdef fs.Context glfont
    cdef double[::1] data
    cdef public float avg,bar_width,min_val, max_val
    cdef float scale
    cdef int idx,d_len
    cdef int x, y, win_height, win_width
    cdef basestring label
    cdef int s_idx,s_size
    cdef object data_source
    cdef public RGBA color


    def __cinit__(self,int data_points = 50,float min_val = 0, float max_val = 100):
        self.data = view.array(shape=(data_points,), itemsize=sizeof(double), format="d")
        self.d_len = data_points
        self.label = 'Title %0.2f units'
        self.bar_width = 2
        self.min_val = min_val
        self.max_val = max_val
        self.scale = 1.

        self.glfont = fs.Context()
        self.glfont.add_font('opensans',get_opensans_font_path())
        self.glfont.set_size(int(18*self.scale))
        self.glfont.set_align(fs.FONS_ALIGN_LEFT | fs.FONS_ALIGN_MIDDLE)
        self.color = RGBA(0.5, 0.8, 0.75,.5)

    def __init__(self,int data_points = 25,float min_val = 0, float max_val = 100):
        cdef int x
        for x in range(data_points):
            self.data[x] = 0
        self.avg = 0
        self.data_source = lambda: 0

    def adjust_window_size(self, w, h):
        self.win_width = w
        self.win_height = h

    property scale:
        def __get__(self):
            return self.scale

        def __set__(self,val):
            self.scale = val
            self.glfont.set_size(int(18*self.scale))

    property label:
        def __get__(self):
            return self.label
        def __set__(self,new_label):
            self.label = new_label

    property pos:
        def __get__(self):
            return self.x,self.y

        def __set__(self,val):
            self.x,self.y = val

    property update_rate:
        def __set__(self,r):
            self.s_size = r
            self.s_idx = 0

        def __get__(self):
            return self.s_size

    property update_fn:
        def __set__(self,fn):
            self.data_source = fn


    def add(self,double val):
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(5./self.d_len)

    def update(self):
        cdef float val
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            val = self.data_source()
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(2./self.d_len)


    def draw(self):
        cdef int i
        cdef float x=0

        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glOrtho(0, self.win_width, self.win_height, 0, -1, 1)


        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glTranslatef(self.x*self.scale,self.y*self.scale,0)
        #scale such that a bar at max val is 100px high
        gl.glPushMatrix()
        gl.glScalef(1,-100.*self.scale/self.max_val,1)
        gl.glTranslatef(0,self.min_val*self.scale,0)


        gl.glLineWidth(self.bar_width*self.scale)
        gl.glColor4f(self.color.r,self.color.g,self.color.b,self.color.a)
        gl.glBegin(gl.GL_LINE_STRIP)


        for i in range(self.idx,self.d_len):
            gl.glVertex3f(x*self.scale,self.data[i],0)
            x += self.bar_width

        for i in range(self.idx):
            gl.glVertex3f(x*self.scale,self.data[i],0)
            x += self.bar_width

        gl.glEnd()
        gl.glPopMatrix()
        self.glfont.set_color_float(self.color[:])
        self.glfont.draw_text(x +10 ,-self.data[i],self.label%self.avg)
        gl.glPopMatrix()

        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_MODELVIEW)




cdef class Averaged_Value:
    cdef fs.Context glfont
    cdef double[::1] data
    cdef basestring label
    cdef int idx,d_len
    cdef public float avg
    cdef int s_idx,s_size
    cdef int x, y, font_size
    cdef float scale
    cdef object data_source
    cdef public RGBA color

    def __cinit__(self, int data_points=25, int font_size=18):
        self.data = view.array(shape=(data_points,), itemsize=sizeof(double), format="d")
        self.scale = 1.
        self.d_len = data_points
        self.label = 'Title %0.2f units'
        self.font_size = font_size
        self.glfont = fs.Context()
        self.glfont.add_font('opensans',get_opensans_font_path())
        self.glfont.set_size(int(self.font_size*self.scale))
        self.glfont.set_align(fs.FONS_ALIGN_LEFT | fs.FONS_ALIGN_MIDDLE)
        self.color = RGBA(1.,1.,1.,1.)

    def __init__(self, int data_points=25,int font_size=18):
        cdef int x
        for x in range(data_points):
            self.data[x] = 0
        self.avg = 0
        self.data_source = lambda: 0

    property label:
        def __get__(self):
            return self.label
        def __set__(self,new_label):
            self.label = new_label

    property pos:
        def __get__(self):
            return self.x,self.y
        def __set__(self,val):
            self.x,self.y = val

    property update_rate:
        def __set__(self,r):
            self.s_size = r
            self.s_idx = 0
        def __get__(self):
            return self.s_size

    property scale:
        def __get__(self):
            return self.scale

        def __set__(self,val):
            self.scale = val
            self.glfont.set_size(int(self.font_size*self.scale))

    def set_text_align(self,v_align='left',h_align='top'):
        v_align = {'left':fs.FONS_ALIGN_LEFT,'center':fs.FONS_ALIGN_CENTER,'right':fs.FONS_ALIGN_RIGHT}[v_align]
        h_align = {'top':fs.FONS_ALIGN_TOP,'middle':fs.FONS_ALIGN_MIDDLE,'bottom':fs.FONS_ALIGN_BOTTOM}[h_align]
        self.glfont.set_align(v_align | h_align)


    def add(self,double val):
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(5./self.d_len)

    def update(self):
        cdef float val
        self.s_idx = (self.s_idx +1) %self.s_size
        if self.s_idx == 0:
            val = self.data_source()
            self.data[self.idx] = val
            self.idx = (self.idx +1) %self.d_len
            #very rough avg estimation
            self.avg += (val-self.avg)*(2./self.d_len)

    def draw(self):
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        self.glfont.set_color_float(self.color[:])
        self.glfont.draw_text(self.x*self.scale,self.y*self.scale,self.label%self.avg)
        gl.glPopMatrix()
