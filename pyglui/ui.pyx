# cython: profile=False
from pyglui.cygl cimport glew as gl
from pyglui.cygl cimport utils
from pyglui.cygl.utils cimport RGBA


from pyfontstash cimport fontstash as fs
include 'version.pxi'
include 'gldraw.pxi'
include 'helpers.pxi'
include 'design_params.pxi'

from os import path
from time import time
#global cdefs
cdef fs.Context glfont
cdef double ui_scale = 1.0
cdef bint should_redraw = True

def get_roboto_font_path():
    return path.join(path.dirname(__file__),'Roboto-Regular.ttf')

def get_opensans_font_path():
    return path.join(path.dirname(__file__),'OpenSans-Regular.ttf')

def get_fontawesome_font_path():
    return path.join(path.dirname(__file__),'fontawesome-webfont.ttf')

def get_all_font_paths():
    return get_roboto_font_path(),get_opensans_font_path(),get_fontawesome_font_path()

try:
    from six import unichr
except ImportError:
    pass
else:
    char = unichr


cdef class UI:
    '''
    The UI context for a glfw window.
    '''
    cdef Input new_input
    cdef bint should_redraw
    cdef public list elements
    cdef FitBox window
    cdef fbo_tex_id ui_layer

    def __cinit__(self):
        self.elements = []
        self.new_input = Input()
        self.window = FitBox(Vec2(0,0),Vec2(0,0))
        self.ui_layer = create_ui_texture(Vec2(200,200))

        #global init of gl fonts
        global glfont
        glfont = fs.Context()
        self.add_font('roboto',get_roboto_font_path() )
        self.add_font('opensans',get_opensans_font_path())
        self.add_font('fontawesome',get_fontawesome_font_path())

    def __init__(self):
        pass

    def add_font(self,font_name,font_path):
        if glfont:
            glfont.add_font(font_name,font_path)

    def terminate(self):
        global glfont
        glfont = None
        destroy_ui_texture(self.ui_layer)
        self.elements = []

    def update_mouse(self,mx,my):
        if self.window.mouse_over(Vec2(mx,my)):
            self.new_input.dm.x,self.new_input.dm.y = mx-self.new_input.m.x, my-self.new_input.m.y
            self.new_input.m.x,self.new_input.m.y = mx,my


    def update_window(self,w,h):
        global should_redraw
        should_redraw = True
        self.window.size.x,self.window.size.y = w,h
        gl.glScissor(0,0,int(w),int(h))
        resize_ui_texture(self.ui_layer,self.window.size)


    def update_scroll(self, sx,sy):
        self.new_input.s.x = sx
        self.new_input.s.y = sy

    def update_key(self, key, scancode, action, mods):
        self.new_input.keys.append((key,scancode,action,mods))

    def update_char(self,c):
        try:
            self.new_input.chars.append(chr(c))
        except:
            pass

    def update_button(self,button,action,mods):
        self.new_input.buttons.append((button,action,mods))

    cdef sync(self):
        for e in self.elements:
            e.sync()

    cdef handle_input(self):
        if self.new_input:
            #print self.new_input

            # Bring clicked element to front.
            # Fix https://github.com/pupil-labs/pupil/issues/363
            for e in self.elements[::-1]:
                if self.new_input.buttons and e.outline.mouse_over(self.new_input.m):
                    self.elements.insert(
                        len(self.elements),
                        self.elements.pop(
                            self.elements.index(e)
                        )
                    )
                    global should_redraw
                    should_redraw = True
                    break


            #let active elements deal with input first:
            for e in self.new_input.active_ui_elements:
                e.pre_handle_input(self.new_input)
            self.new_input.active_ui_elements = []

            #now everybody
            # ontop level in reverse so that menus drawn above other take precedence
            for e in self.elements[::-1]:
                e.handle_input(self.new_input,True)
            self.new_input.purge()

    cdef draw(self):
        global should_redraw
        global window_size
        window_size = self.window.size

        if should_redraw:

            should_redraw = False
            #print "UI is redrawing the screen"
            push_view(self.window.size)
            render_to_ui_texture(self.ui_layer)
            glfont.clear_state()
            glfont.set_font('opensans')
            glfont.set_size(int(ui_scale * text_size))
            glfont.set_color_float(color_text_default)
            glfont.set_blur(.1)
            glfont.set_align(fs.FONS_ALIGN_TOP)

            for e in self.elements:
                e.draw(self.window,nested=False)

            render_to_screen()
            pop_view()


        draw_ui_texture(self.ui_layer)


    def update(self):
        self.handle_input()
        self.sync()
        self.draw()

    def collect_menus(self):
        for e in self.elements:
            try:
                e.collect_in_window(self.window)
            except AttributeError:
                pass

    ###special methods to make UI behave like a list
    def append(self, obj):
        if not issubclass(obj.__class__,UI_element):
            raise Exception("Can only append UI elements, not: '%s'"%obj )
        self.elements.append(obj)
        global should_redraw
        should_redraw = True

    def extend(self, objs):
        for obj in objs:
            if not issubclass(obj.__class__,UI_element):
                raise Exception("Can only append UI elements, not: '%s'"%obj )
        self.elements.extend(objs)
        global should_redraw
        should_redraw = True

    def remove(self, obj):
        del self.elements[self.elements.index(obj)]
        global should_redraw
        should_redraw = True


    #identical to base_menu method
    cdef get_submenu_config(self):
        '''
        Growing menus are sometimes emebedded in Other menues. We load their configurations recursively.
        '''
        cdef dict submenus = {}
        for e in self.elements:
            if isinstance(e,(Growing_Menu,Scrolling_Menu,Stretching_Menu)):
                submenus[e.label] = submenus.get(e.label,[]) + [e.configuration] #we could have two submenues with same label so we use a list for each submenu label cotaining the conf dicts for each menu
        return submenus

    #identical to base_menu method
    cdef set_submenu_config(self, object submenus):
        '''
        Growing menus are sometimes emebedded in Other menues. We save their configurations recursively.
        '''
        if submenus:
            # submenus is an Immutable_Dict with tuples as values.
            # Keep state of current submenu entry with iterators
            conf_iters = {k: iter(submenus[k]) for k in submenus.keys()}
            for e in self.elements:
                if isinstance(e,(Growing_Menu,Scrolling_Menu,Stretching_Menu)):
                    e.configuration = next(conf_iters[e.label]) if e.label in conf_iters else {}

    property configuration:
        def __get__(self):
            cdef dict submenus = self.get_submenu_config()
            return {'submenus':submenus}

        def __set__(self,new_conf):
            self.set_submenu_config(new_conf.get('submenus',{}))



    def __len__ (self):
        return len(self.elements)

    def __getitem__ (self,x):
        return self.elements[x]

    def __setitem__ (self,x,obj):
        self.elements[x] = obj

    def __delitem__ (self,x):
        del self.elements[x]


    def __contains__ (self,obj):
        return obj in self.elements

    property scale:
        def __get__(self):
            return ui_scale

        def __set__(self, float val):
            global ui_scale
            ui_scale = val

include 'ui_elements.pxi'
include 'menus.pxi'

#below are classes used by menu and ui_elements.
cdef class Synced_Value:
    '''
    an element that has a synced value
    attributes will be accecd through the attribute context unless you supply a getter.
    '''
    cdef object attribute_context
    cdef bint use_dict
    cdef str attribute_name
    cdef object _value
    cdef object getter
    cdef object setter
    cdef object on_change

    def __cinit__(self,str attribute_name, object attribute_context = None, getter=None, setter=None, on_change=None):
        assert attribute_context is not None or getter is not None
        self.attribute_context = attribute_context

        if isinstance(attribute_context,dict):
            self.use_dict = True
        else:
            self.use_dict = False

        self.attribute_name = attribute_name
        self.getter = getter
        self.setter = setter
        self.on_change = on_change

    def __init__(self,str attribute_name, object attribute_context = None, getter=None, setter=None, on_change=None):
        if self.attribute_context is not None:
            if self.use_dict:
                try:
                    _ = self.attribute_context[self.attribute_name]
                except KeyError:
                    raise Exception("Dict: '%s' has no entry '%s'"%(self.attribute_context,self.attribute_name))
            else:
                try:
                    _ = getattr(self.attribute_context,self.attribute_name)
                except KeyError:
                    raise Exception("'%s' has no attribute '%s'"%(self.attribute_context,self.attribute_name))
        self.sync()



    cdef sync(self):
        global should_redraw
        if self.getter is not None:
            val = self.getter()
            if val != self._value:
                self._value = val
                should_redraw = True
                if self.on_change is not None:
                    self.on_change(self.value)

        elif self.use_dict:
            if self._value != self.attribute_context[self.attribute_name]:
                self._value = self.attribute_context[self.attribute_name]
                should_redraw = True
                if self.on_change is not None:
                    self.on_change(self._value)

        elif self._value != getattr(self.attribute_context,self.attribute_name):
            self._value = getattr(self.attribute_context,self.attribute_name)
            should_redraw = True
            if self.on_change is not None:
                self.on_change(self._value)

    property value:
        def __get__(self):
            return self._value
        def __set__(self,new_val):
            if self.setter is not None:
                self.setter(new_val)
            elif self.use_dict:
                self.attribute_context[self.attribute_name] = new_val
            else:
                setattr(self.attribute_context,self.attribute_name,new_val)


cdef class Input:
    '''
    Holds accumulated user input collect during a frame.
    '''

    cdef public list keys,chars,buttons,active_ui_elements
    cdef Vec2 dm,m,s

    def __cinit__(self):
        self.keys = []
        self.buttons = []
        self.chars = []
        self.active_ui_elements = []
        self.m = Vec2(0,0)
        self.dm = Vec2(0,0)
        self.s = Vec2(0,0)

    def __init__(self):
        pass

    def __nonzero__(self):
        return bool(self.keys or self.chars or self.buttons or self.dm or self.s)

    def purge(self):
        self.keys = []
        self.buttons = []
        self.chars = []
        self.dm.x = 0
        self.dm.y = 0
        self.s.x = 0
        self.s.y = 0

    def __str__(self):
        return 'Current Input: \n   Mouse pos  : %s\n   Mouse delta: %s\n   Scroll: %s\n   Buttons: %s\n   Keys: %s\n   Chars: %s' %(self.m,self.dm,self.s,self.buttons,self.keys,self.chars)


DEF drag_threshold = 10
cdef class Draggable:
    '''
    A rectangle that can be dragged.
    Does not move itself but the drag vector is added to 'value'
    Mouse postions units are scaled by 1/ui_scale
    '''
    cdef FitBox outline
    cdef Vec2 touch_point,drag_accumulator
    cdef bint selected,zero_crossing,dragged,catch_input
    cdef Vec2 value
    cdef int arrest_axis
    cdef object click_cb

    def __cinit__(self,Vec2 pos, Vec2 size, Vec2 value, arrest_axis = 0,zero_crossing=True,click_cb = None,catch_input=True):
        self.outline = FitBox(pos,size)
        self.value = value
        self.selected = False
        self.touch_point = Vec2(0,0)
        self.drag_accumulator = Vec2(0,0)

        self.arrest_axis = arrest_axis
        self.zero_crossing = zero_crossing
        self.click_cb = click_cb
        self.dragged = False
        self.catch_input = catch_input

    def __init__(self,Vec2 pos, Vec2 size, Vec2 value, arrest_axis = 0,zero_crossing=True,click_cb = None,catch_input=True):
        pass

    cdef draw(self, FitBox parent_size,bint nested=True):
        self.outline.compute(parent_size)
        self.outline.sketch()


    cpdef pre_handle_input(self,Input new_input):
        # we need to check for new clicks as touch pads can isse
        # a button down that is not follow by a button up.
        for b in new_input.buttons:
            if b[1] == 1:
                if not self.outline.mouse_over(new_input.m):
                    self.selected = False


    cdef handle_input(self,Input new_input, bint visible):
        global should_redraw

        if self.selected and new_input.dm:
            self.value -= self.drag_accumulator
            self.drag_accumulator = (new_input.m-self.touch_point)
            self.drag_accumulator *= 1/ui_scale

            if (abs(self.drag_accumulator.x) + abs(self.drag_accumulator.y))  > drag_threshold:
                self.dragged  = True

            if self.arrest_axis == 1:
                self.drag_accumulator.x = 0
            elif self.arrest_axis == 2:
                self.drag_accumulator.y = 0

            if not self.zero_crossing:
                if self.value.x > 0 and self.value.x + self.drag_accumulator.x <= 0:
                    self.drag_accumulator.x = .001 - self.value.x
                elif self.value.x < 0 and self.value.x + self.drag_accumulator.x >= 0:
                    self.drag_accumulator.x = -.001 - self.value.x
                elif self.value.x ==0:
                    self.drag_accumulator.x = 0
                if self.value.y > 0 and self.value.y + self.drag_accumulator.y <= 0:
                    self.drag_accumulator.y = .001 - self.value.y
                elif self.value.y < 0 and self.value.y + self.drag_accumulator.y >= 0:
                    self.drag_accumulator.y = -.001 - self.value.y
                elif self.value.y ==0:
                    self.drag_accumulator.y = 0

            self.value += self.drag_accumulator

            should_redraw = True

        for b in new_input.buttons[:]:#we need to make a copy for remove to work as desired
            if b[1] == 1 and visible:
                if self.outline.mouse_over(new_input.m):
                    self.selected = True
                    self.dragged  = False
                    self.touch_point.x = new_input.m.x
                    self.touch_point.y = new_input.m.y
                    self.drag_accumulator = Vec2(0,0)
                    if self.catch_input:
                        new_input.buttons.remove(b)
            if self.selected and b[1] == 0:
                self.selected = False
                if self.click_cb and not self.dragged:
                    self.click_cb()

        if self.selected:
            new_input.active_ui_elements.append(self)

    cdef sync(self):
        pass

cdef class FitBox:
    '''
    A box that will fit itself into a context.
    Specified by rules for x and y respectively:
        size positive -> size from self.org
        size 0 -> span into parent context and lock it like this. If you want it draggable use -.001 or .001
        size negative -> make the box to up to size pixels to the parent container.
        position negative -> align to the opposite side of context
        position 0  -> span into parent context and lock it like this. If you want it draggable use -.001 or .001

    This is quite expressive but does have a limitation:
        You cannot design a box that is outside of the parent context.

    Its made of 4 Vec2
        "design_org" "design_size" define the rules for placement and size

        "org" and "size" are the computed results of the box
            fitted and translated by its parent context

    Vec2 min_size is optional.


    Vec2 size and org will be computed when calling .compute(context,[nested])
        the globl UI scale factor will be applied to these vectors.

    '''
    cdef Vec2 design_org,org,design_size,size,min_size

    def __cinit__(self,Vec2 position,Vec2 size, Vec2 min_size = Vec2(0,0)):
        self.design_org = Vec2(position.x,position.y)
        self.design_size = Vec2(size.x,size.y)
        self.min_size = Vec2(min_size.x,min_size.y)
        # The values below are just temporay
        # and will be overwritten by compute.
        self.org = Vec2(position.x,position.y)
        self.org *= ui_scale
        self.size = Vec2(size.x,size.y)
        self.size *=ui_scale


    def __init__(self,Vec2 position,Vec2 size, Vec2 min_size = Vec2(0,0)):
        pass

    cdef collapse(self):

        #object is positioned from left(resp. top) and sized from object org
        if self.design_org.x >= 0 and  self.design_size.x  > 0:
            self.design_size.x = self.min_size.x
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.x < 0 and self.design_size.x <= 0:
            self.design_org.x = self.design_size.x - self.min_size.x
            #self.design_size.x = self.min_size.x
        #object is positioned from left (top) and sized from context size:
        elif self.design_org.x >= 0 and self.design_size.x <= 0:
            pass
        #object is positioned from right and sized from object org
        elif self.design_org.x < 0 and self.design_size.x > 0:
            self.design_size.x = self.min_size.x
        else:
            pass

        #object is positioned from left(resp. top) and sized from object org
        if self.design_org.y >= 0 and self.design_size.y  > 0:
            self.design_size.y = self.min_size.y
        #object is positions from right (resp. bottom) and sized from context size
        elif self.design_org.y < 0 and self.design_size.y <= 0:
            self.design_org.y = self.design_size.y -self.min_size.y
            #self.design_size.y = self.min_size.y
        #object is positioned from left (top) and sized from context size:
        elif self.design_org.y >= 0 and self.design_size.y <= 0:
            pass
        #object is positioned from right and sized from object org
        elif self.design_org.y < 0 and self.design_size.y > 0:
            self.design_size.y = self.min_size.y
        else:
            pass


    cdef inflate(self,FitBox target):

        #object is positioned from left(resp. top) and sized from object org
        if self.design_org.x >= 0 and  self.design_size.x  > 0:
            self.design_size.x = target.design_size.x
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.x < 0 and self.design_size.x <= 0:
            self.design_org.x = target.design_org.x
            #self.design_size.x = self.min_size.x
        #object is positioned from left (top) and sized from context size:
        elif self.design_org.x >= 0 and self.design_size.x <= 0:
            pass
        #object is positioned from right and sized from object org
        elif self.design_org.x < 0 and self.design_size.x > 0:
            self.design_size.x = target.design_size.x
        else:
            pass

        #object is positioned from left(resp. top) and sized from object org
        if self.design_org.y >= 0 and  self.design_size.y  > 0:
            self.design_size.y = target.design_size.y
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.y < 0 and self.design_size.y <= 0:
            self.design_org.y = target.design_org.y
            #self.design_size.y = self.min_size.y
        #object is positioned from left (top) and sized from context size:
        elif self.design_org.y >= 0 and self.design_size.y <= 0:
            pass
        #object is positioned from right and sized from object org
        elif self.design_org.y < 0 and self.design_size.y > 0:
            self.design_size.y = target.design_size.y
        else:
            pass


    cdef compute(self,FitBox context):

        # all x
        if self.design_org.x >=0:
            self.org.x = self.design_org.x * ui_scale
        else:
            self.org.x = context.size.x+self.design_org.x * ui_scale #design org is negative - double subtraction
        if self.design_size.x > 0:
            # size is direcly specified
            self.size.x = self.design_size.x * ui_scale
        else:
            self.size.x = context.size.x - self.org.x + self.design_size.x * ui_scale #design size is negative - double subtraction

        self.size.x = max(self.min_size.x * ui_scale,self.size.x)
        # finally translate into scene by parent org
        self.org.x +=context.org.x


        if self.design_org.y >=0:
            self.org.y = self.design_org.y * ui_scale
        else:
            self.org.y = context.size.y+self.design_org.y * ui_scale #design size is negative - double subtraction
        if self.design_size.y > 0:
            # size is direcly specified
            self.size.y = self.design_size.y * ui_scale
        else:
            self.size.y = context.size.y - self.org.y + self.design_size.y * ui_scale #design size is negative - double subtraction


        self.size.y = max(self.min_size.y * ui_scale,self.size.y)
        # finally translate into scene by parent org
        self.org.y +=context.org.y


    property rect:
        def __get__(self):
            return self.org.x,self.org.y,self.size.x,self.size.y

    property ellipse:
        def __get__(self):
            return self.org.x+self.size.x/2,self.org.y+self.size.y/2, self.size.x,self.size.y

    property center:
        def __get__(self):
            return self.org.x+self.size.x/2,self.org.y+self.size.y/2

    cpdef bint mouse_over(self,Vec2 m):
        return self.org.x <= m.x <= self.org.x+self.size.x and self.org.y <= m.y <=self.org.y+self.size.y

    def __str__(self):
        return "FitBox:\n   design org: %s size: %s\n   comptd org: %s size: %s"%(self.design_org,self.design_size,self.org,self.size)

    cdef same_design(self,FitBox other):
        return bool(self.design_org == other.design_org and self.design_size == other.design_size)

    cdef design_distance(self,FitBox other):
        cdef float d = 0
        d += abs(self.design_size.x-other.design_size.x)
        d += abs(self.design_size.y-other.design_size.y)
        d += abs(self.design_org.x-other.design_org.x)
        d += abs(self.design_org.y-other.design_org.y)
        return d

    cdef sketch(self):
        rect(self.org,self.size,RGBA(*rect_color_default))

    cdef copy(self):
        return FitBox( Vec2(*self.design_org), Vec2(*self.design_size), Vec2(*self.min_size) )

    cdef has_area(self):
        return 1 < self.size.x*self.size.y



cdef class Vec2:
    cdef public float x,y

    def __cinit__(self,float x, float y):
        self.x = x
        self.y = y

    def __init__(self,x,y):
        pass

    def __nonzero__(self):
        return bool(self.x or self.y)

    def __add__(self,Vec2 other):
        return Vec2(self.x+other.x,self.y+other.y)

    def __imul__(self,float factor):
        self.x *=factor
        self.y *=factor
        return self

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

    def __len__(self):
        return 2

    def __str__(self):
        return 'x: %s y: %s'%(self.x,self.y)

    def __richcmp__(self,Vec2 other,int op):
        '''
        <   0
        ==  2
        >   4
        <=  1
        !=  3
        >=  5
        '''
        if op == 2:
            return bool(self.x == other.x and self.y == other.y)
        else:
            return NotImplemented

    def __getitem__(self,idx):
        if isinstance(idx,slice):
            return (self.x,self.y)[idx]
        else:
            if idx==0:
                return self.x
            elif idx==1:
                return self.y
            raise IndexError()

    def __setitem__(self,idx,obj):
        if isinstance(idx,slice):
            self.x,self.y = obj[0], obj[1] #we should be more specific about the kind of slice
        else:
            if idx ==0:
                self.x = obj
            elif idx == 1:
                self.y == obj
            else:
                raise IndexError()
