cimport cgl as gl
from pyglui cimport Vec2


cdef inline test(int maxx):
    gl.glLineWidth(1)
    gl.glColor4f(0.,0.,0.,.5)
    gl.glBegin(gl.GL_LINES)
    cdef int x
    for x in range(maxx):
        gl.glVertex3f(x*3,500,0.0)
        gl.glVertex3f(0,0,0.0)
    gl.glEnd()


cdef inline rect(Vec2 org, Vec2 size):
    gl.glColor4f(0.,0.,0.,.1)
    gl.glLineWidth(1)
    gl.glBegin(gl.GL_POLYGON)
    gl.glVertex3f(org.x,org.y,0.0)
    gl.glVertex3f(org.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y,0.0)
    gl.glEnd()