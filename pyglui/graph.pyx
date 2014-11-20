from cython cimport view
from cygl cimport cgl as gl
from cygl cimport utils
from pyfontstash cimport pyfontstash as fs


#global init of gl fonts
cdef fs.Context glfont

cdef double win_width, win_height

def adjust_view(w,h):
    '''
    Sets up pixel based gl coord system.
    Use this to prepare rendering of graphs.
    '''
    global win_height
    global win_width
    win_width,win_height = w,h

cdef class Graph:
    cdef double[::1] data
    cdef public float avg,bar_width,min_val, max_val
    cdef int idx,d_len
    cdef int x,y
    cdef basestring label
    cdef int s_idx,s_size
    cdef object data_source

    def __cinit__(self,int data_points = 25,float min_val = 0, float max_val = 100):
        self.data = view.array(shape=(data_points,), itemsize=sizeof(double), format="d")
        self.d_len = data_points
        self.label = 'Tile %0.2f units'
        self.bar_width = 4
        self.min_val = min_val
        self.max_val = max_val

        global glfont
        glfont = fs.Context()
        glfont.add_font('opensans', 'Roboto-Regular.ttf')
        glfont.set_size(18)

    def __init__(self,int data_points = 25,float min_val = 0, float max_val = 100):
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
        gl.glOrtho(0, win_width, win_height, 0, -1, 1)
        gl.glMatrixMode(gl.GL_MODELVIEW)
        gl.glPushMatrix()
        gl.glLoadIdentity()
        gl.glTranslatef(self.x,self.y,0)
        gl.glRotatef(180,0,0,0)
        #scale such that a bar at max val is 100px high
        gl.glPushMatrix()
        gl.glScalef(1,100./self.max_val,1)
        gl.glTranslatef(0,self.min_val,0)
        gl.glLineWidth(self.bar_width)
        gl.glColor4f(.0,0.0,.5,.3)
        gl.glBegin(gl.GL_LINES)

        #if self.s_size:
        #    x -= self.s_idx/float(self.s_size) * 4

        for i in range(self.idx,self.d_len):
            gl.glVertex3f(x,0,0)
            gl.glVertex3f(x,self.data[i],0)
            x +=self.bar_width

        for i in range(self.idx):
            gl.glVertex3f(x,0,0)
            gl.glVertex3f(x,self.data[i],0)
            x +=self.bar_width

        gl.glEnd()
        gl.glPopMatrix()


        gl.glRotatef(180,0,0,0)
        glfont.draw_text(0,0,bytes(self.label%self.avg))
        gl.glPopMatrix()
        gl.glMatrixMode(gl.GL_PROJECTION)
        gl.glPopMatrix()

