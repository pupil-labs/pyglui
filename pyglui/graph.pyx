from cython cimport view
from cygl cimport cgl as gl
from cygl cimport utils
from pyfontstash cimport pyfontstash as fs


#global init of gl fonts
cdef fs.Context glfont = fs.Context()
glfont.add_font('opensans', 'OpenSans-Regular.ttf')
glfont.set_size(18)


cdef class Graph:
    cdef float[::1] data
    cdef float avg
    cdef int idx,d_len
    cdef int x,y
    cdef basestring lable,units

    def __cinit__(self,int data_points = 200):
        self.data = view.array(shape=(data_points,), itemsize=sizeof(float), format="f")
        self.d_len = data_points
        self.lable = 'test'
        self.units = '%'

    def __init__(self,int data_points = 200):
        cdef int x
        for x in range(data_points):
            self.data[x] = 0
        self.avg = 0

    property pos:
        def __get__(self):
            return self.x,self.y

        def __set__(self,val):
            self.x,self.y = val


    def update(self,int val):
        self.data[self.idx] = val
        self.idx = (self.idx +1) %self.d_len

        #very rough avg estimation
        self.avg += (val-self.avg)*(2./self.d_len)


    def draw(self):
        cdef int i,x=0
        gl.glPushMatrix()
        gl.glTranslatef(self.x,self.y,0)
        gl.glRotatef(180,0,0,0)
        gl.glLineWidth(1)
        gl.glColor4f(.0,0.0,.5,.3)
        gl.glBegin(gl.GL_LINES)

        for i in range(self.idx,self.d_len):
            gl.glVertex3f(x,0,0)
            gl.glVertex3f(x,self.data[i],0)
            x +=1

        for i in range(self.idx):
            gl.glVertex3f(x,0,0)
            gl.glVertex3f(x,self.data[i],0)
            x +=1

        gl.glEnd()

        gl.glRotatef(180,0,0,0)
        glfont.draw_text(0,0,bytes("%s %0.2f%s"%(self.lable,self.avg,self.units)))
        gl.glPopMatrix()






