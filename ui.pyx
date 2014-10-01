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
        self.should_redraw = True

    def update_mouse(self,mx,my):
        if 0 <= mx <= self.window_size.x and 0 <= my <= self.window_size.y:
            self.new_input.dm.x,self.new_input.dm.y = mx-self.new_input.m.x,my-self.new_input.m.y
            self.new_input.m.x,self.new_input.m.y = mx,my

    def update_window(self,w,h):
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
                e.handle_input(self.new_input,True)
            self.new_input.purge()


    cpdef draw(self,context):
        cdef Menu e
        if self.should_redraw:
            for e in self.elements:
                e.draw(context,self.window_size)
            self.should_redraw = True

    def update(self,context):
        global should_redraw
        should_redraw = self.should_redraw
        self.handle_input()
        self.sync()
        self.should_redraw = should_redraw
        self.draw(context)



cdef class Menu:
    '''
    Menu is a movable object on the canvas that contains other elements.
    '''
    cdef public list elements
    cdef FitBox outline
    cdef public bint iconified
    cdef bytes label
    cdef long uid

    def __cinit__(self,label,pos=(0,0),size=(200,100)):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size))

    def __init__(self,label,pos=(0,0),size=(200,100)):
        self.elements = []

    cdef draw(self,context,parent_size):
        self.outline.fit(parent_size)
        context.save()
        self.draw_menu(context)
        #translate to origin of this menu
        context.translate(self.outline.org.x,self.outline.org.y)

        for e in self.elements:
            e.draw(context,self.outline.size)

        context.restore()

    cdef draw_menu(self,context):
        context.beginPath()
        context.rect(*self.outline.xywh)
        context.stroke()


    cdef handle_input(self, Input new_input,bint m_close):
        new_input.m.push()
        #translate input coords to menu
        new_input.m -= self.outline.org
        for e in self.elements:
            e.handle_input(new_input,True)
        new_input.m.pop()

    cdef sync(self):
        for e in self.elements:
            e.sync()


cdef class StackBox:
    '''
    An element that contains stacks of other elements
    It will be scrollable if the content does not fit.
    '''
    cdef FitBox outline
    cdef int scroll_y
    cdef public list elements

    def __cinit__(self):
        self.outline = FitBox(Vec2(0,0),Vec2(0,0))
        self.scroll_y = 0
    def __init__(self):
        self.elements = []

    cpdef sync(self):
        for e in self.elements:
            e.sync()


    cpdef handle_input(self,Input new_input,visible=True):
        new_input.m.push()
        #translate input coords to menu
        new_input.m -= self.outline.org
        cdef bint mouse_over_menue = 0 <= new_input.m.y <= +self.outline.size.y

        new_input.m.y -= self.scroll_y
        for e in self.elements:
            e.handle_input(new_input, mouse_over_menue)
            new_input.m.y-=e.height

        new_input.m.pop()

    cpdef draw(self,context,parent_size):
        self.outline.fit(parent_size)

        #do we need a scollbar?
        h = sum([e.height for e in self.elements])
        if h:
            scroll_factor = float(self.outline.size.y)/h
        else:
            scroll_factor = 2

        if scroll_factor < 1:
            self.outline.size.x -=20
            #do all things scrollbar draw here.

        context.save()
        # dont show the stuff that does not fit.
        context.scissor(*self.outline.xywh)

        #translate to origin of this menu
        context.translate(self.outline.org.x,self.outline.org.y)

        context.translate(0,self.scroll_y)
        for e in self.elements:
            e.draw(context,self.outline.size)
            context.translate(0,e.height)

        context.restore()




cdef class Slider:
    cdef readonly bytes label
    cdef readonly long  uid
    cdef float minimum,maximum,step
    cdef public FitBox outline
    cdef bint selected
    cdef Vec2 slider_pos
    cdef Synced_Value sync_val

    def __cinit__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.minimum = min
        self.maximum = max
        self.step = step
        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.slider_pos = Vec2(0,20)
        self.selected = False

    def __init__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,context,Vec2 parent_size):
        #update apperance:
        self.outline.fit(parent_size)

        # map slider value
        self.slider_pos.x = int( clampmap(self.sync_val.value,self.minimum,self.maximum,0,self.outline.size.x) )

        #then transform locally and render the UI element
        context.save()
        context.beginPath()
        context.textAlign(1<<4)
        context.text(20.0, 20.0, self.label)

        context.rect(*self.outline.xywh)
        if self.selected:
            context.circle(self.slider_pos.x,self.slider_pos.y,14)
        else:
            context.circle(self.slider_pos.x,self.slider_pos.y,18)
        context.textAlign(1<<1 | 1<<4)
        context.text(self.slider_pos.x,self.slider_pos.y, str(self.sync_val.value))

        context.stroke()
        context.restore()

    cpdef handle_input(self,Input new_input,bint m_close):
        global should_redraw

        if self.selected and new_input.dm:
            self.sync_val.value = clampmap(new_input.m.x,0,self.outline.size.x,self.minimum,self.maximum)
            should_redraw = True

        for b in new_input.buttons:
            if b[1] == 1 and m_close:
                if mouse_over_center(self.slider_pos,self.height,self.height,new_input.m):
                    self.selected = True
                    should_redraw = True
            if self.selected and b[1] == 0:
                self.selected =False


        #for c in new_input.chars:
        #    pass

        #for k in new_input.keys:
        #    pass


    property height:
        def __get__(self):
            return self.outline.size.y

cdef class FitBox:
    '''
    size 0 will span into parent context
    size negative will move Box org to the other side
    position negative will align to the opposite side of context

    '''
    cdef Vec2 design_org,org,design_size,size

    def __cinit__(self,Vec2 position,Vec2 size):
        self.design_org = Vec2(position.x,position.y)
        self.design_size = Vec2(size.x,size.y)
        self.org = Vec2(0,0)
        self.size = Vec2(0,0)

    def __init__(self,Vec2 position,Vec2 size):
        pass

    cdef fit(self,Vec2 context):
        # all x
        if self.design_size.x > 0:
            # size is direcly specified
            self.size.x = self.design_size.x
        elif self.design_size.x < 0:
            # size is set but origin is mirrored
            self.size.x = - self.design_size.x
        else:
            # span parent context
            self.size.x = context.x

        if self.design_org.x < 0:
            self.org.x = context.x+self.design_org.x
        else:
            self.org.x = self.design_org.x

        # mir origin if design size is negative
        if self.design_size.x < 0:
            self.org.x += self.design_size.x

        # account for positon is span
        if self.design_size.x == 0:
            self.size.x -= self.org.x

        self.size.x = max(0,self.size.x)


        # copy replace for y
        if self.design_size.y > 0:
            # size is direcly specified
            self.size.y = self.design_size.y
        elif self.design_size.y < 0:
            # size is set but origin is mirrored
            self.size.y = - self.design_size.y
        else:
            # span parent context
            self.size.y = context.y

        if self.design_org.y < 0:
            self.org.y = context.y+self.design_org.y
        else:
            self.org.y = self.design_org.y

        # mir origin if design size is negative
        if self.design_size.y < 0:
            self.org.y += self.design_size.y

        # account for positon is span
        if self.design_size.y == 0:
            self.size.y -= self.org.y

        self.size.y = max(0,self.size.y)


    property xywh:
        def __get__(self):
            return self.org.x,self.org.y,self.size.x,self.size.y


cdef class Synced_Value:
    '''
    an element that has a synced value
    '''
    cdef object attribute_context
    cdef bytes attribute_name
    cdef object _value
    cdef object getter
    cdef object setter

    def __cinit__(self,bytes attribute_name, object attribute_context,getter=None,setter=None):
        self.attribute_context = attribute_context
        self.attribute_name = attribute_name
        self.getter = getter
        self.setter = setter

    def __init__(self,bytes attribute_name, object attribute_context,getter=None,setter=None):
        self.sync()


    cdef sync(self):

        if self.getter:
            val = self.getter()
            if val != self._value:
                self._value = val
                global should_redraw
                should_redraw = True

        elif self._value != self.attribute_context.__dict__[self.attribute_name]:
            self._value = self.attribute_context.__dict__[self.attribute_name]
            global should_redraw
            should_redraw = True


    property value:
        def __get__(self):
            return self._value
        def __set__(self,val):
            #conserve the type
            t = type(self._value)
            self._value = t(val)

            if self.setter:
                self.setter(self._value)

            self.attribute_context.__dict__[self.attribute_name] = self._value



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


cdef inline float lmap(float value, float istart, float istop, float ostart, float ostop):
    '''
    linear mapping of val from space1 to space 2
    '''
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

cdef inline float clamp(float value, float minium, float maximum):
    return max(min(value,maximum),minium)

cdef inline float clampmap(float value, float istart, float istop, float ostart, float ostop):
    return clamp(lmap(value,istart,istop,ostart,ostop),ostart,ostop)

cdef inline bint mouse_over_center(Vec2 center, int w, int h, Stack2 m):
    return center.x-w/2 <= m.x <=center.x+w/2 and center.y-h/2 <= m.y <=center.y+h/2

