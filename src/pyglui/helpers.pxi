
cdef inline double lmap(double value, double istart, double istop, double ostart, double ostop):
    '''
    linear mapping of val from space 1 to space 2
    '''
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

cdef inline double clamp(double value, double minium, double maximum):
    return max(min(value,maximum),minium)

cdef inline double clampmap(double value, double istart, double istop, double ostart, double ostop):
    return clamp(lmap(value,istart,istop,ostart,ostop),ostart,ostop)

cdef inline bint mouse_over_center(Vec2 center, double w, double h, Vec2 m):
    return center.x-w/2 <= m.x <=center.x+w/2 and center.y-h/2 <= m.y <=center.y+h/2

cdef inline double step(double value, double start, double stop, double step):
    cdef double rest
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
