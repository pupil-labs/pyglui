cdef class UI:
    '''
    The UI context for a glfw window.
    '''
    cdef Input new_input
    cdef bint should_redraw
    cdef public list elements
    cdef Vec2 window_size

    def __cinit__(self):
        self.elements = []
        self.new_input = Input()
        self.window_size = Vec2(0,0)

    def __init__(self):
        pass

    def update_mouse(self,mx,my):
        self.new_input.dm.x,self.new_input.dm.y = mx-self.new_input.m.x,my-self.new_input.m.y
        self.new_input.m.x,self.new_input.m.y = mx,my

    def update_win_size(self,w,h):
        self.window_size.x,self.window_size.y = w,h
        self.should_redraw = True

    def input_key(self, key, scancode, action, mods):
        self.new_input.keys.append((key,scancode,action,mods))

    def input_char(self,c):
        self.new_input.chars.append(c)

    def input_button(self,button,action,mods):
        self.new_input.buttons.append((button,action,mods))

    def sync(self):
        cdef Menu e
        for e in self.elements:
            e.sync()

    cpdef handle_input(self):
        cdef Menu e
        if self.new_input:
            for e in self.elements:
                e.handle_input(self.new_input,self.window_size)
            self.new_input.purge()


    cpdef draw(self,context):
        cdef Menu e
        if self.should_redraw or 1:
            for e in self.elements:
                e.draw(context,self.window_size)

    def update(self,context):
        self.handle_input()
        self.sync()
        #self.draw(context)




cdef class Menu:
    '''
    Menu is a movable object on the canvas that contains other elements.
    '''
    cdef public list stacked_elements
    cdef public list elements
    cdef Vec2 origin,size
    cdef public bint iconified
    cdef public bint stacked
    cdef bytes label
    cdef long uid

    def __cinit__(self,label,pos=(0,0),size=(200,100)):
        self.uid = id(self)
        self.label = label
        self.origin = Vec2(*pos)
        self.size = Vec2(*size)
        self.stacked = False

    def __init__(self,label,pos=(0,0),size=(100,0)):
        self.elements = []
        self.stacked_elements = []

    cdef draw(self,context,parent_size):
        context.save()
        self.draw_menu(context)
        #translate to origin if not stacked
        context.translate(self.origin.x,self.origin.y)

        for e in self.elements:
            e.draw(context,self.size)

        #tranlate to stack start here:
        context.translate(0,20)

        for e in self.stacked_elements:
            e.draw(context,self.size)
            context.translate(0,e.h)

        context.restore()

    cdef draw_menu(self,context):
        context.beginPath()
        context.rect(self.origin.x,self.origin.y,self.size.x,self.size.y)
        context.stroke()


    cdef handle_input(self, Input new_input,Vec2 parent_size):
        new_input.m.push()
        #translate input coords to menu
        new_input.m -= self.origin

        for e in self.elements:
            e.handle_input(new_input,self.size)

        #translate to stack start here
        new_input.m -= Vec2(0,20)

        for e in self.stacked_elements:
            e.handle_input(new_input,self.size)
            new_input.m.x-=e.height

        new_input.m.pop()


    cdef sync(self):
        for e in self.elements:
            e.sync()

    property pos:
        def __get__(self):
            return self.outline.x,self.outline.y
        def __set__(self,val):
            cdef int x,y = val
            self.outline.x,self.outline.y = x,y

    property size:
        def __get__(self):
            return self.outline.w,self.outline.h
        def __set__(self,val):
            cdef int w,h = val
            self.outline.w,self.outline.h = w,h

cdef class Synced:
    '''
    an element that has a synced value
    '''
    cdef object attribute_context
    cdef bytes attribute_name
    cdef object value
    cdef object getter
    cdef object setter
    cdef readonly bytes label
    cdef readonly long  uid

    cpdef sync(self):
        if self.value != self.attribute_context.__dict__[self.attribute_name]:
            self.value == self.attribute_context.__dict__[self.attribute_name]
            global should_redraw
            should_redraw = True


cdef class Slider(Synced):
    cdef object minimum,maximum,step
    cdef public bint stacked
    cdef public int height

    def __cinit__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 10, step = 1):
        self.stacked = True
        self.uid = id(self)
        self.label = label or attribute_name
        self.attribute_context = attribute_context
        self.attribute_name = attribute_name
        self.minimum = min
        self.maximum = max
        self.step = step
        self.height = 40


    def __init__(self, bytes attribute_name, object attribute_context,label = None, min = 0, max = 10, step = 1):
        self.sync()

    cpdef draw(self,context,Vec2 parent_size):
        context.save()
        context.beginPath()
        context.rect(0,0,parent_size.x,self.height)
        context.circle(50,20,20)
        context.stroke()
        context.restore()

    cpdef handle_input(self,Input new_input,Vec2 parent_size):

        for b in new_input.buttons:
            pass
            #if self.target.over(new_input.mx,new_input.my):
                #print 'clicked',self.label,b
                #self.active = True

    property h:
        def __get__(self):
            return self.height



cdef class Toggle(Synced):
    pass



#cdef class Rect:
#    cdef public int x,y,w,h

#    def __cinit__(self,x,y,w,h):
#        self.x = x
#        self.y = y
#        self.w = w
#        self.h = h

#    def __init__(self,x,y,w,h):
#        pass

#    cpdef bint over(self,int mx, int my):
#        if self.x <= mx <= self.x+self.w and self.y <= my <= self.y+self.h:
#            return True
#        else:
#            return False

#    property rect:
#        def __get__(self):
#            return self.x, self.y, self.w, self.h
#        def __set__(self,tuple val):
#            self.x, self.y, self.w, self.h = val

#    property center:
#        def __get__(self):
#            return self.x+self.w/2, self.y+self.h/2
#        def __set__(self,tuple pos):
#            self.x, self.y = pos[0]-self.w/2, pos[1]-self.h/2

cdef class Input:
    cdef public list keys,chars,buttons
    cdef Vec2 dm
    cdef Stack2 m

    def __cinit__(self):
        self.keys = []
        self.buttons = []
        self.chars = []
        self.m = Stack2(0,0)
        self.dm = Vec2(0,0)

    def __init__(self):
        pass

    def __nonzero__(self):
        return bool(self.keys or self.chars or self.buttons or self.dm)

    def purge(self):
        self.keys = []
        self.buttons = []
        self.chars = []
        self.dm.x = 0
        self.dm.y = 0

cdef class Vec2:
    cdef public int x,y

    def __cinit__(self,int x, int y):
        self.x = x
        self.y = y

    def __init__(self,x,y):
        pass

    def __nonzero__(self):
        return bool(self.x or self.y)

    def __add__(self,Vec2 other):
        return Vec2(self.x+other.x,self.y+other.y)


    def __iadd__(self,Vec2 other):
        self.x +=other.x
        self.y += other.y
        return self

    def __sub__(self,Vec2 other):
        return Vec2(self.x-other.x,self.y-other.y)

    def __isub__(self,Vec2 other):
        self.x -=other.x
        self.y -= other.y
        return self

cdef class Stack2(Vec2):
    cdef list stack

    def __cinit__(self,int x, int y):
        self.x = x
        self.y = y

    def __init__(self,x,y):
        self.stack = []

    cpdef push(self):
        self.stack.append(Vec2(self.x,self.y))

    cpdef pop(self):
        cdef Vec2 vec = self.stack.pop()
        self.x = vec.x
        self.y = vec.y





