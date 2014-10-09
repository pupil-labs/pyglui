from cygl cimport cgl as gl
from ui cimport Vec2


cdef inline adjust_view(Vec2 size):
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glLoadIdentity()
    gl.glOrtho(0, size.x, size.y, 0, -1, 1)
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glLoadIdentity()


cdef inline rect(Vec2 org, Vec2 size):
    gl.glColor4f(0.,0.,0.,.05)
    gl.glLineWidth(1)
    gl.glBegin(gl.GL_LINE_LOOP)
    gl.glVertex3f(org.x,org.y,0.0)
    gl.glVertex3f(org.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y,0.0)
    gl.glEnd()
    gl.glBegin(gl.GL_POLYGON)
    gl.glVertex3f(org.x,org.y,0.0)
    gl.glVertex3f(org.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y,0.0)
    gl.glEnd()


