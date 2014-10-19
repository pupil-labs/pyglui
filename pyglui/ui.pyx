'''
TODO:

GL Backend and functions
[x] make gl.h pxd file
[x] implement shader based lines and points in gl backend
[x] add render to texture option if nessesay

GL Fonts:
[x] Select GL Font Lib : https://github.com/memononen/fontstash
[x] Write cython binding
[x] use in this lib

UI features
[ ] implement selector box
[ ] implement toggle
[x] make menu move resize and minimize fn selectable and lockalbe in x or y
[ ] design the UI and implement using gl calls above
[ ] Optional: Add global UI scale option
[x] Implement Perf graph in cython
[x] Implement scrolling

Done:
UI interaction
UI layouting
UI value syncing

'''


from cygl cimport cgl as gl
from cygl cimport utils
from pyfontstash cimport pyfontstash as fs

include 'gldraw.pxi'
include 'helpers.pxi'

#global init of gl fonts
cdef fs.Context glfont = fs.Context()
glfont.add_font('opensans', 'Roboto-Regular.ttf')

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

    def __init__(self):
        self.should_redraw = True


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
        self.new_input.chars.append(chr(c))

    def update_button(self,button,action,mods):
        self.new_input.buttons.append((button,action,mods))

    cdef sync(self):
        for e in self.elements:
            e.sync()

    cdef handle_input(self):
        if self.new_input:
            #print self.new_input
            for e in self.elements:
                e.handle_input(self.new_input,True)
            self.new_input.purge()

    cdef draw(self):
        global should_redraw
        global window_size
        window_size = self.window.size

        if should_redraw:
            render_to_ui_texture(self.ui_layer)
            gl.glPushMatrix()
            adjust_view(self.window.size)

            glfont.clear_state()
            glfont.set_size(18)
            glfont.set_color_float(1.,1,1,1)
            glfont.set_align(fs.FONS_ALIGN_TOP)

            for e in self.elements:
                e.draw(self.window,nested=False)


            gl.glPopMatrix()
            render_to_screen()

            should_redraw = False

        draw_ui_texture(self.ui_layer)


    def update(self):
        global should_redraw
        self.handle_input()
        self.sync()
        self.draw()

cdef class Growing_Menu:
    '''
    Menu is a movable object on the canvas that contains other elements.
    '''
    cdef public list elements
    cdef FitBox outline, element_space
    cdef bint is_collapsed
    cdef bytes label
    cdef long uid
    cdef int header_pos_id
    cdef Draggable handlebar, resize_corner

    def __cinit__(self,label,pos=(0,0),size=(200,100),min_size = (25,0),header_pos = 'top'):
        self.uid = id(self)
        self.label = label
        #design height will be overwritten in draw.
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=Vec2(*min_size))
        self.elements = []


    def __init__(self,label,pos=(0,0),size=(200,100),min_size = (25,0),header_pos = 'top'):
        self.header_pos = header_pos


    property header_pos:
        def __get__(self):
            header_pos_list = ['top','botton','left','right','hidden']
            return header_pos_list[self.header_pos_id]

        def __set__(self, header_pos):
            if header_pos == 'top':
                self.element_space = FitBox(Vec2(0,25),Vec2(0,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(0,25),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-25,-25),Vec2(0,0),
                                                self.outline.design_size,
                                                arrest_axis=2,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'bottom':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,-25))
                self.handlebar = Draggable(Vec2(0,-25),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(25,25),
                                                self.outline.design_org,
                                                arrest_axis=2,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'right':
                self.element_space = FitBox(Vec2(0,0),Vec2(-25,0))
                self.handlebar = Draggable(Vec2(-25,0),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org.x:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(25,25),
                                                self.outline.design_org,
                                                arrest_axis=2,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'left':
                self.element_space = FitBox(Vec2(25,0),Vec2(0,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(25,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-25,-25),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=2,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.handlebar = None


            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom', was %s "%header_pos)

            self.header_pos_id = ['top','botton','left','right','hidden'].index(header_pos)



    cpdef draw(self,FitBox parent,bint nested=True):
        #here we compute the requred design height of this menu.
        self.outline.design_size.y  = self.height
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        self.draw_menu(nested)

        cdef float org_y = self.element_space.org.y
        #if elements are not visible, no need to draw them.
        if self.element_space.size.x and self.element_space.size.y:
            for e in self.elements:
                e.draw(self.element_space)
                self.element_space.org.y+= e.height
            self.outline.org.y = org_y

    cdef draw_menu(self,bint nested):
        if nested:
            pass
        else:
            self.element_space.sketch()

        if self.handlebar:
            self.handlebar.outline.compute(self.outline)
            if 2<= self.header_pos_id <= 3:
                tripple_v(self.handlebar.outline.org,Vec2(25,25))
            else:
                tripple_h(self.handlebar.outline.org,Vec2(25,25))
                glfont.draw_text(self.handlebar.outline.org.x+30,
                                 self.handlebar.outline.org.y+4,self.label)

        if self.resize_corner:
            self.resize_corner.outline.compute(self.outline)
            self.resize_corner.draw(self.outline)


    cpdef handle_input(self, Input new_input,bint visible):
        global should_redraw

        if self.resize_corner:
            self.resize_corner.handle_input(new_input,visible)
        if self.handlebar:
            self.handlebar.handle_input(new_input,visible)

        #if elements are not visible, no need to interact with them.
        if self.element_space.size.x and self.element_space.size.y:
            for e in self.elements:
                e.handle_input(new_input, visible)


    cpdef sync(self):
        if self.element_space.size.x and self.element_space.size.y:
            for e in self.elements:
                e.sync()

    property height:
        def __get__(self):
            cdef float height = 0
            #space from outline to element space at top
            height += self.element_space.design_org.y
            #space from elementspace to outline at bottom
            height -= self.element_space.design_size.y #double neg
            if self.is_collapsed:
                #elemnt space is 0
                pass
            else:
                height += sum([e.height for e in self.elements])
            return height


    def toggle_iconified(self):
        global should_redraw
        should_redraw = True
        self.is_collapsed = not self.is_collapsed

cdef class Scrolling_Menu:
    '''
    Menu is a movable object on the canvas that contains other elements.
    '''
    cdef public list elements
    cdef FitBox outline, uncollapsed_outline, element_space
    cdef bytes label
    cdef long uid
    cdef int header_pos_id
    cdef Draggable handlebar, resize_corner, scrollbar
    cdef Vec2 scrollstate
    cdef float scroll_factor

    def __cinit__(self,label,pos=(0,0),size=(200,100),min_size = (25,25),header_pos = 'top'):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=Vec2(*min_size))
        self.uncollapsed_outline = self.outline.copy()
        self.elements = []

        self.scrollstate = Vec2(0,0)
        self.scrollbar = Draggable(Vec2(0,0),Vec2(0,0),self.scrollstate,arrest_axis=1,zero_crossing=True)
        self.scroll_factor = 1.

    def __init__(self,label,pos=(0,0),size=(200,100),min_size = (25,25),header_pos = 'top'):
        self.header_pos = header_pos


    property header_pos:
        def __get__(self):
            header_pos_list = ['top','botton','left','right','hidden']
            return header_pos_list[self.header_pos_id]

        def __set__(self, header_pos):
            if header_pos == 'top':
                self.element_space = FitBox(Vec2(0,25),Vec2(0,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(0,25),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                if self.outline.design_size:
                    self.resize_corner = Draggable(Vec2(-25,-25),Vec2(0,0),
                                                self.outline.design_size,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'bottom':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,-25))
                self.handlebar = Draggable(Vec2(0,-25),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(25,25),
                                                self.outline.design_org,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'right':
                self.element_space = FitBox(Vec2(0,0),Vec2(-25,0))
                self.handlebar = Draggable(Vec2(-25,0),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(25,25),
                                                self.outline.design_org,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'left':
                self.element_space = FitBox(Vec2(25,0),Vec2(0,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(25,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_size:
                    self.resize_corner = Draggable(Vec2(-25,-25),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=0,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.handlebar = None


            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom', was %s "%header_pos)

            self.header_pos_id = ['top','botton','left','right','hidden'].index(header_pos)



    cpdef draw(self,FitBox parent,bint nested=True):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        self.draw_menu(nested)

        #if elements are not visible, no need to draw them.
        if self.element_space.size.x and self.element_space.size.y:
            self.draw_scroll_window_elements()

    cdef draw_scroll_window_elements(self):

        # dont show the stuff that does not fit.
        gl.glPushAttrib(gl.GL_SCISSOR_BIT)
        gl.glEnable(gl.GL_SCISSOR_TEST)
        cdef int sb[4]
        global window_size
        gl.glGetIntegerv(gl.GL_SCISSOR_BOX,sb)
        sb[1] = window_size.y-sb[1]-sb[3] # y-flipped coord system
        #deal with nested scissors
        cdef float org_x = max(sb[0],self.element_space.org.x)
        cdef float size_x = min(sb[0]+sb[2],self.element_space.org.x+self.element_space.size.x)
        size_x = max(0,size_x-org_x)
        cdef float org_y = max(sb[1],self.element_space.org.y)
        cdef float size_y = min(sb[1]+sb[3],self.element_space.org.y+self.element_space.size.y)
        size_y = max(0,size_y-org_y)
        gl.glScissor(int(org_x),window_size.y-int(org_y)-int(size_y),int(size_x),int(size_y))


        self.scrollbar.outline.compute(self.element_space)

        #compute scroll stack height: The stack elemets always have a fixed height.
        h = sum([e.height for e in self.elements])

        if h:
            self.scroll_factor = float(self.element_space.size.y)/h
        else:
            self.scroll_factor = 1

        #display that we have scrollable content
        #if self.scroll_factor < 1:
        #    self.element_space.size.x -=20


        #If the scollbar is not active make sure the content is not scrolled away:
        if not self.scrollbar.selected:
            #self.scrollstate.y = clamp(self.scrollstate.y,min(-h,self.element_space.size.y-h),0)
            self.scrollstate.y = clamp(self.scrollstate.y,-h+35,0)

        self.element_space.org.y += self.scrollstate.y
        for e in self.elements:
            e.draw(self.element_space)
            self.element_space.org.y+= e.height

        self.element_space.org.y -= self.scrollstate.y
        self.element_space.org.y -= h

        #restore scissor state
        gl.glPopAttrib()


    cdef draw_menu(self,bint nested):
        if nested:
            pass
        else:
            self.element_space.sketch()

        if self.handlebar:
            self.handlebar.outline.compute(self.outline)
            if 2<= self.header_pos_id <= 3:
                tripple_v(self.handlebar.outline.org,Vec2(25,25))
            else:
                tripple_h(self.handlebar.outline.org,Vec2(25,25))
                glfont.draw_text(self.handlebar.outline.org.x+30,
                                 self.handlebar.outline.org.y+4,self.label)

        if self.resize_corner:
            self.resize_corner.outline.compute(self.outline)
            self.resize_corner.draw(self.outline)


    cpdef handle_input(self, Input new_input,bint visible):
        global should_redraw
        cdef bint mouse_over_menu = 0

        if self.resize_corner:
            self.resize_corner.handle_input(new_input,visible)
        if self.handlebar:
            self.handlebar.handle_input(new_input,visible)

        #if elements are not visible, no need to interact with them.
        if self.element_space.size.x and self.element_space.size.y:
            # let the elements know that the mouse should be ignored
            # if outside of the visible scroll section
            mouse_over_menu =  self.element_space.org.y <= new_input.m.y <= self.element_space.org.y+self.element_space.size.y
            mouse_over_menu = mouse_over_menu and visible
            for e in self.elements:
                e.handle_input(new_input, mouse_over_menu)

        # handle scrollbar interaction after menu items
        # so grabbing a slider does not trigger scrolling
        #mouse:
        self.scrollbar.handle_input(new_input,visible)
        #scrollwheel:
        if new_input.s.y and visible and self.element_space.mouse_over(new_input.m):
            self.scrollstate.y += new_input.s.y * 3
            new_input.s.y = 0
            should_redraw = True



    cpdef sync(self):
        if self.element_space.size.x and self.element_space.size.y:
            for e in self.elements:
                e.sync()

    property height:
        def __get__(self):
            return self.outline.size.y


    def toggle_iconified(self):
        global should_redraw
        should_redraw = True

        if self.outline.is_collapsed():
            self.outline.inflate(self.uncollapsed_outline)
        else:
            self.uncollapsed_outline = self.outline.copy()
            self.outline.collapse()


cdef class Slider:
    cdef readonly bytes label
    cdef readonly long  uid
    cdef float minimum,maximum,step
    cdef public FitBox outline,field
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
        self.field = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.slider_pos = Vec2(0,20)
        self.selected = False

    def __init__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent, bint nested=True):
        #update apperance:
        self.outline.compute(parent)
        self.field.compute(self.outline)

        # map slider value
        self.slider_pos.x = clampmap(self.sync_val.value,self.minimum,self.maximum,0,self.field.size.x)
        self.outline.sketch()
        self.field.sketch()


        gl.glPushMatrix()
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)

        glfont.push_state()
        glfont.draw_text(10,0,self.label)
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        if type(self.sync_val.value) == float:
            glfont.draw_text(self.field.size.x-10,0,bytes('%0.2f'%self.sync_val.value) )
        else:
            glfont.draw_text(self.field.size.x-10,0,bytes(self.sync_val.value ))
        glfont.pop_state()

        if self.selected:
            utils.draw_points(((self.slider_pos.x,10),),size=40, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.slider_pos.x,10),),size=30, color=(.5,.5,.9,.9))
        else:
            utils.draw_points(((self.slider_pos.x,10),),size=30, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.slider_pos.x,10),),size=20, color=(.5,.5,.5,.9))

        gl.glPopMatrix()



    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw

        if self.selected and new_input.dm:
            self.sync_val.value = clampmap(new_input.m.x-self.field.org.x,0,self.field.size.x,self.minimum,self.maximum)
            should_redraw = True

        for b in new_input.buttons:
            if b[1] == 1 and visible:
                if mouse_over_center(self.slider_pos+self.field.org,self.height,self.height,new_input.m):
                    new_input.buttons.remove(b)
                    self.selected = True
                    should_redraw = True
            if self.selected and b[1] == 0:
                self.selected = False
                should_redraw = True



    property height:
        def __get__(self):
            return self.outline.size.y


cdef class Switch:
    cdef readonly bytes label
    cdef readonly long  uid
    cdef public FitBox outline,field
    cdef bint selected
    cdef Synced_Value sync_val
    cdef obj

    def __cinit__(self,bytes attribute_name, object attribute_context, on_val = 1, off_val = 0,label = None, setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)

        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.field = FitBox(Vec2(10,10),Vec2(20,-10))
        self.slider_pos = Vec2(0,20)
        self.selected = False

    def __init__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True):
        #update apperance:
        self.outline.compute(parent)
        self.field.compute(self.outline)

        # map slider value
        self.slider_pos.x = clampmap(self.sync_val.value,self.minimum,self.maximum,0,self.field.size.x)
        self.outline.sketch()
        self.field.sketch()


        gl.glPushMatrix()
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)
        cdef FitBox s
        if self.selected:
            s = FitBox(Vec2(self.slider_pos.x-9,1),Vec2(18,18))
        else:
            s = FitBox(Vec2(self.slider_pos.x-10,0),Vec2(20,20))
        s.sketch()

        glfont.push_state()
        glfont.draw_text(10,0,self.label)
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        if type(self.sync_val.value) == float:
            glfont.draw_text(self.field.size.x-10,0,bytes('%0.2f'%self.sync_val.value) )
        else:
            glfont.draw_text(self.field.size.x-10,0,bytes(self.sync_val.value ))
        glfont.pop_state()
        gl.glPopMatrix()



    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw

        if self.selected and new_input.dm:
            self.sync_val.value = clampmap(new_input.m.x-self.field.org.x,0,self.field.size.x,self.minimum,self.maximum)
            should_redraw = True

        for b in new_input.buttons:
            if b[1] == 1 and visible:
                if mouse_over_center(self.slider_pos+self.field.org,self.height,self.height,new_input.m):
                    new_input.buttons.remove(b)
                    self.selected = True
                    should_redraw = True
            if self.selected and b[1] == 0:
                self.selected = False


    property height:
        def __get__(self):
            return self.outline.size.y





cdef class TextInput:
    cdef readonly bytes label
    cdef readonly long  uid
    cdef public FitBox outline,textfield
    cdef bint selected
    cdef Vec2 slider_pos
    cdef Synced_Value sync_val
    cdef bytes preview
    cdef int caret


    def __cinit__(self,bytes attribute_name, object attribute_context,label = None,setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.textfield = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.selected = False
        self.preview = str(self.sync_val.value)
        self.caret = len(self.preview)-1

    def __init__(self,bytes attribute_name, object attribute_context,label = None,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True):
        #update apperance:
        self.outline.compute(parent)

        gl.glPushMatrix()
        gl.glTranslatef(self.outline.org.x,self.outline.org.y,0)
        dx = glfont.draw_text(10,10,self.label)
        dx += 10
        self.textfield.design_org.x = dx
        self.textfield.compute(self.outline)
        gl.glPopMatrix()

        gl.glPushMatrix()
        #then transform locally and render the UI element
        self.textfield.sketch()
        gl.glTranslatef(self.textfield.org.x,self.textfield.org.y,0)
        glfont.draw_text(10,0,self.preview)
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw

        if self.selected:
            for c in new_input.chars:
                self.preview = self.preview[:self.caret+1] + c + self.preview[self.caret+1:]
                self.caret +=1
                should_redraw = True

            for k in new_input.keys:
                if k == (257,36,0,0): #Enter and key up:
                    self.finish_input()
                elif k == (259,51,0,0) or k ==(259,51,2,0): #Delete and key up:
                    self.preview = self.preview[:self.caret] + self.preview[self.caret+1:]
                    self.caret -=1
                    self.caret = max(0,self.caret)
                elif k == (263,123,0,0): #Delete and key up:
                    self.caret -=1
                    self.caret = max(0,self.caret)
                elif k == (262,124,0,0): #Delete and key up:
                    self.caret +=1
                    self.caret = min(len(self.preview)-1,self.caret)


            for b in new_input.buttons:
                if b[1] == 1:
                    self.finish_input()

        else:
            for b in new_input.buttons:
                if b[1] == 1 and visible:
                    if self.textfield.mouse_over(new_input.m):
                        new_input.buttons.remove(b)
                        self.selected = True
                        should_redraw = True

    cdef finish_input(self):
        global should_redraw
        should_redraw = True
        self.selected = False
        self.caret = len(self.preview)-1
        self.sync_val.value = self.preview

    property height:
        def __get__(self):
            return self.outline.size.y



cdef class Button:
    cdef readonly bytes label
    cdef readonly long  uid
    cdef public FitBox outline
    cdef FitBox button
    cdef bint selected
    cdef object function

    def __cinit__(self,label, setter):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.button = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.selected = False
        self.function = setter

    def __init__(self,label, setter):
        pass

    cpdef sync(self):
        pass

    cpdef draw(self,FitBox parent,bint nested=True):
        #update apperance:
        self.outline.compute(parent)
        self.button.compute(self.outline)

        self.outline.sketch()
        if self.selected:
            pass
        else:
            self.button.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(self.button.org.x,self.button.org.y,0)
        glfont.draw_text(10,0,self.label)
        gl.glPopMatrix()


    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw

        for b in new_input.buttons:
            if  visible and self.button.mouse_over(new_input.m):
                if b[1] == 1:
                    new_input.buttons.remove(b)
                    self.selected = True
                    should_redraw = True
            if self.selected and b[1] == 0:
                new_input.buttons.remove(b)
                self.selected = False
                should_redraw = True
                self.function()

    property height:
        def __get__(self):
            return self.outline.size.y


cdef class Draggable:
    '''
    A rectable that can be dragged.
    Does not move itself but the drag vector is added to 'value'
    '''
    cdef FitBox outline
    cdef Vec2 touch_point,drag_accumulator
    cdef bint selected,zero_crossing,dragged
    cdef Vec2 value
    cdef int arrest_axis
    cdef object click_cb

    def __cinit__(self,Vec2 pos, Vec2 size, Vec2 value, arrest_axis = 0,zero_crossing=True,click_cb = None):
        self.outline = FitBox(pos,size)
        self.value = value
        self.selected = False
        self.touch_point = Vec2(0,0)
        self.drag_accumulator = Vec2(0,0)

        self.arrest_axis = arrest_axis
        self.zero_crossing = zero_crossing
        self.click_cb = click_cb
        self.dragged = False

    def __init__(self,Vec2 pos, Vec2 size, Vec2 value, arrest_axis = 0,zero_crossing=True,click_cb = None):
        pass

    cdef draw(self, FitBox parent_size,bint nested=True):
        self.outline.compute(parent_size)
        self.outline.sketch()

    cdef handle_input(self,Input new_input, bint visible):
        global should_redraw
        if self.selected and new_input.dm:
            self.value -= self.drag_accumulator
            self.drag_accumulator = new_input.m-self.touch_point
            if self.drag_accumulator.x < 2 or self.drag_accumulator.y  < 2:
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

        for b in new_input.buttons:
            if b[1] == 1 and visible:
                if self.outline.mouse_over(new_input.m):
                    self.selected = True
                    self.dragged  = False
                    new_input.buttons.remove(b)
                    self.touch_point.x = new_input.m.x
                    self.touch_point.y = new_input.m.y
                    self.drag_accumulator = Vec2(0,0)
            if self.selected and b[1] == 0:
                self.selected = False
                if self.click_cb and not self.dragged:
                    self.click_cb()

    cdef sync(self):
        pass

cdef class FitBox:
    '''
    A box that will fit itself into a context.
    Specified by rules for x and y respectivly:
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
    '''
    cdef Vec2 design_org,org,design_size,size,min_size

    def __cinit__(self,Vec2 position,Vec2 size, Vec2 min_size = Vec2(0,0)):
        self.design_org = Vec2(position.x,position.y)
        self.design_size = Vec2(size.x,size.y)
        # The values below are just temporay
        # and will be overwritten by compute.
        self.org = Vec2(position.x,position.y)
        self.size = Vec2(size.x,size.y)
        self.min_size = Vec2(min_size.x,min_size.y)


    def __init__(self,Vec2 position,Vec2 size, Vec2 min_size = Vec2(0,0)):
        pass

    cdef collapse(self):

        #object is positioned from left(resp. top) and sized from obct org
        if self.design_org.x >= 0 and  self.design_size.x  > 0:
            self.design_size.x = self.min_size.x
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.x < 0 and self.design_size.x <= 0:
            self.design_org.x = self.design_size.x - self.min_size.x
            #self.design_size.x = self.min_size.x
        #object is positiond from left (top) and sized from context size:
        elif self.design_org.x >= 0 and self.design_size.x <= 0:
            pass
        #object is positioned from right and sized deom object org
        elif self.design_org.x < 0 and self.design_size.x > 0:
            self.design_size.x = self.min_size.x
        else:
            pass

        #object is positioned from left(resp. top) and sized from obct org
        if self.design_org.y >= 0 and self.design_size.y  > 0:
            self.design_size.y = self.min_size.y
        #object is positions from right (resp. bottom) and sized from context size
        elif self.design_org.y < 0 and self.design_size.y <= 0:
            self.design_org.y = self.design_size.y -self.min_size.y
            #self.design_size.y = self.min_size.y
        #object is positiond from left (top) and sized from context size:
        elif self.design_org.y >= 0 and self.design_size.y <= 0:
            pass
        #object is positioned from right and sized deom object org
        elif self.design_org.y < 0 and self.design_size.y > 0:
            self.design_size.y = self.min_size.y
        else:
            pass


    cdef inflate(self,FitBox target):

        #object is positioned from left(resp. top) and sized from obct org
        if self.design_org.x >= 0 and  self.design_size.x  > 0:
            self.design_size.x = target.design_size.x
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.x < 0 and self.design_size.x <= 0:
            self.design_org.x = target.design_org.x
            #self.design_size.x = self.min_size.x
        #object is positiond from left (top) and sized from context size:
        elif self.design_org.x >= 0 and self.design_size.x <= 0:
            pass
        #object is positioned from right and sized deom object org
        elif self.design_org.x < 0 and self.design_size.x > 0:
            self.design_size.x = target.design_size.x
        else:
            pass

        #object is positioned from left(resp. top) and sized from obct org
        if self.design_org.y >= 0 and  self.design_size.y  > 0:
            self.design_size.y = target.design_size.y
        #object is positioned from right (resp. bottom) and sized from context size
        elif self.design_org.y < 0 and self.design_size.y <= 0:
            self.design_org.y = target.design_org.y
            #self.design_size.y = self.min_size.y
        #object is positiond from left (top) and sized from context size:
        elif self.design_org.y >= 0 and self.design_size.y <= 0:
            pass
        #object is positioned from right and sized deom object org
        elif self.design_org.y < 0 and self.design_size.y > 0:
            self.design_size.y = target.design_size.y
        else:
            pass


    cdef is_collapsed(self,float slack = 30):
        cdef FitBox collapser = self.copy()
        collapser.collapse()
        return slack >= self.design_distance(collapser)



    cdef compute(self,FitBox context):

        # all x
        if self.design_org.x >=0:
            self.org.x = self.design_org.x
        else:
            self.org.x = context.size.x+self.design_org.x #design org is negative - double substaction
        if self.design_size.x > 0:
            # size is direcly specified
            self.size.x = self.design_size.x
        else:
            self.size.x = context.size.x - self.org.x + self.design_size.x #design size is negative - double substaction

        self.size.x = max(self.min_size.x,self.size.x)
        # finally translate into scene by parent org
        self.org.x +=context.org.x


        if self.design_org.y >=0:
            self.org.y = self.design_org.y
        else:
            self.org.y = context.size.y+self.design_org.y #design size is negative - double substaction
        if self.design_size.y > 0:
            # size is direcly specified
            self.size.y = self.design_size.y
        else:
            self.size.y = context.size.y - self.org.y + self.design_size.y #design size is negative - double substaction


        self.size.y = max(self.min_size.y,self.size.y)
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

    cdef bint mouse_over(self,Vec2 m):
        return self.org.x <= m.x <= self.org.x+self.size.x and self.org.y <= m.y <=self.org.y+self.size.y

    def __repr__(self):
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
        rect(self.org,self.size)

    cdef copy(self):
        return FitBox( Vec2(*self.design_org), Vec2(*self.design_size), Vec2(*self.min_size) )



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
    '''
    Holds accumulated user input collect during a frame.
    '''

    cdef public list keys,chars,buttons
    cdef Vec2 dm,m,s

    def __cinit__(self):
        self.keys = []
        self.buttons = []
        self.chars = []
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

    def __repr__(self):
        return 'Current Input: \n   Mouse pos  : %s\n   Mouse delta: %s\n   Scroll: %s\n   Buttons: %s\n   Keys: %s\n   Chars: %s' %(self.m,self.dm,self.s,self.buttons,self.keys,self.chars)

cdef class Vec2:
    #cdef public float x,y declared in pyglui.pxd

    def __cinit__(self,float x, float y):
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

    def __repr__(self):
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
        if idx==0:
            return self.x
        if idx==1:
            return self.y
        raise IndexError()

