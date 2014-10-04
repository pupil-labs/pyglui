cimport cgl as gl

cdef inline test(int maxx):
    gl.glLineWidth(2)
    gl.glColor4f(1.,1.,0,1.)
    gl.glBegin(gl.GL_LINES)
    cdef int x
    for x in range(maxx):
        gl.glVertex3f(x*3,500,0.0)
        gl.glVertex3f(0,0,0.0)
    gl.glEnd()

