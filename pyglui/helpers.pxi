
cdef inline float lmap(float value, float istart, float istop, float ostart, float ostop):
    '''
    linear mapping of val from space 1 to space 2
    '''
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

cdef inline float clamp(float value, float minium, float maximum):
    return max(min(value,maximum),minium)

cdef inline float clampmap(float value, float istart, float istop, float ostart, float ostop):
    return clamp(lmap(value,istart,istop,ostart,ostop),ostart,ostop)

cdef inline bint mouse_over_center(Vec2 center, float w, float h, Vec2 m):
    return center.x-w/2 <= m.x <=center.x+w/2 and center.y-h/2 <= m.y <=center.y+h/2

cdef inline float step(float value, float start, float stop, float step):
    cdef float rest
    if step:
        value -=start
        rest = value%step
        #round down
        if rest < step/2.:
            value -=rest
        #round up
        else:
            value += step-rest
        value +=start
    return value

def frange(start, stop, step):
    '''
    todo: translate to cython function
    '''
    while start < stop:
        yield start
        start += step