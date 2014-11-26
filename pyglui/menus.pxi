

#Layout parameters
DEF menu_pad = 8
DEF menu_topbar_pad = 37
DEF menu_topbar_min_width = 200
DEF menu_bottom_pad = 20

DEF menu_sidebar_pad = 34
DEF menu_sidebar_min_height = 20

DEF resize_corner_size = 25


cdef class Base_Menu(UI_element):
    """
    Base class that other menu inherit from. Dont use this.
    This contains all methods/attributed shared by all derived menus.
    """

    cdef public list elements
    cdef FitBox element_space
    cdef int header_pos_id
    cdef Draggable handlebar, resize_corner
    cdef public RGBA color

    cpdef sync(self):
        if self.element_space.has_area():
            for e in self.elements:
                e.sync()


    def append(self, obj):
        self.elements.append(obj)

    def extend(self, objs):
        self.elements.extend(objs)

    def remove(self, obj):
        del self.elements[self.elements.index(obj)]

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

    def __bool__(self):
        return True



    cdef draw_menu(self,bint nested):
        #draw translucent background
        if nested:
            pass
        else:
            gl.glColor4f(self.color.r,self.color.g,self.color.b,self.color.a)

            if self.header_pos_id == 2: #left
                self.outline.org.x += menu_sidebar_pad*ui_scale
                self.outline.size.x -= menu_sidebar_pad*ui_scale
                self.outline.sketch()
                self.outline.org.x -= menu_sidebar_pad*ui_scale
                self.outline.size.x += menu_sidebar_pad*ui_scale

            elif self.header_pos_id == 3: #right
                self.outline.size.x -= menu_sidebar_pad*ui_scale
                self.outline.sketch()
                self.outline.size.x += menu_sidebar_pad*ui_scale
            else:
                self.outline.sketch()

        if self.resize_corner is not None:
            self.resize_corner.outline.compute(self.outline)
            self.resize_corner.draw(self.outline)

        if self.handlebar is not None:
            self.handlebar.outline.compute(self.outline)
            if 2<= self.header_pos_id <= 3:
                tripple_v(self.handlebar.outline.org,Vec2(25*ui_scale,25*ui_scale))
            else:
                tripple_h(self.handlebar.outline.org,Vec2(25*ui_scale,25*ui_scale))
                glfont.draw_text(self.handlebar.outline.org.x+30*ui_scale,
                                 self.handlebar.outline.org.y+4*ui_scale,self.label)


cdef class Stretching_Menu(Base_Menu):
    '''
    A simple menu
    Not movable and fixed in height.
    It will space its content evenenly in y.
    '''
    cdef public bint collapsed

    def __cinit__(self,label,pos=(0,0),size=(200,100)):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=Vec2(0,0))
        self.element_space = FitBox(position=Vec2(menu_pad,menu_pad),size=Vec2(-menu_pad,-menu_pad))
        self.elements = []
        self.color = RGBA(0,0,0,0)
        self.collapsed = False

    def __init__(self,label,pos=(0,0),size=(200,100)):
        pass

    cpdef draw(self,FitBox parent,bint nested=True):
        cdef float h = 0,y_spacing=0,org_y=0
        if not self.collapsed:
            self.outline.compute(parent)
            self.element_space.compute(self.outline)

            for e in self.elements:
                e.precompute(self.element_space)
                h += e.height

            y_spacing  = (self.element_space.size.y-h)/(len(self.elements)+1)
            org_y = self.element_space.org.y
            #if elements are not visible, no need to draw them.
            if self.element_space.has_area():
                self.element_space.org.y+= y_spacing
                for e in self.elements:
                    e.draw(self.element_space,nested= False)
                    self.element_space.org.y+= e.height + y_spacing
                self.outline.org.y = org_y


    cpdef handle_input(self, Input new_input,bint visible):
        if not self.read_only and not self.collapsed:
            global should_redraw
            #if elements are not visible, no need to interact with them.
            if self.element_space.has_area():
                for e in self.elements:
                    e.handle_input(new_input, visible)


    property configuration:
        def __get__(self):
            return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':self.collapsed}

        def __set__(self,new_conf):
            self.outline.design_org[:] = new_conf['pos']
            self.outline.design_size[:] = new_conf['size']
            self.collapsed = new_conf['collapsed']


cdef class Growing_Menu(Base_Menu):
    '''
    Growing_Menu is a movable object on the canvas grows with its content

    size positive -> size from self.org
    size 0 -> span into parent context and lock it like this. If you want it draggable use -.001 or .001
    size negative -> make the box to up to size pixels to the parent container.
    position negative -> align to the opposite side of context
    position 0  -> span into parent context and lock it like this. If you want it draggable use -.001 or .001


    '''
    cdef public bint collapsed


    def __cinit__(self,label,pos=(0,0),size=(0,0),header_pos = 'top'):
        self.uid = id(self)
        self.label = label
        #design height will be overwritten in draw.
        if header_pos in ('top','bottom'):
            min_size = Vec2(menu_topbar_min_width,menu_topbar_pad)
        elif header_pos in ('left','right'):
            min_size = Vec2(menu_sidebar_pad,menu_sidebar_min_height)
        else:
            min_size = Vec2(0,0)
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=min_size)

        self.elements = []
        self.header_pos = header_pos
        self.color = RGBA(0,0,0,.3)

    def __init__(self,label, pos=(0,0),size=(200,100),header_pos = 'top'):
        pass
    property header_pos:
        def __get__(self):
            header_pos_list = ['top','bottom','left','right','hidden']
            return header_pos_list[self.header_pos_id]

        def __set__(self, header_pos):
            if header_pos == 'top':
                self.element_space = FitBox(Vec2(menu_pad,menu_topbar_pad + menu_pad),Vec2(-menu_pad,-menu_pad- menu_bottom_pad))
                self.handlebar = Draggable(Vec2(0,0),Vec2(0,menu_topbar_pad),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                self.outline.design_size,
                                                arrest_axis=2,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'bottom':
                self.element_space = FitBox(Vec2(menu_pad,menu_bottom_pad + menu_pad),Vec2(-menu_pad,-menu_pad- menu_topbar_pad))
                self.handlebar = Draggable(Vec2(0,-menu_bottom_pad),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                self.resize_corner = None

            elif header_pos == 'right':
                self.element_space = FitBox(Vec2(menu_pad,0),Vec2(-menu_pad-menu_sidebar_pad,0))
                self.handlebar = Draggable(Vec2(-menu_sidebar_pad,0),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                self.resize_corner = None

            elif header_pos == 'left':
                self.element_space = FitBox(Vec2(menu_sidebar_pad+menu_pad,0),Vec2(-menu_pad,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(menu_sidebar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=2,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.handlebar = None


            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom', was %s "%header_pos)

            self.header_pos_id = ['top','bottom','left','right','hidden'].index(header_pos)



    cpdef draw(self,FitBox parent,bint nested=True):
        #here we compute the requred design height of this menu.
        self.outline.design_size.y  = self.height/ui_scale
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        self.draw_menu(nested)

        cdef float org_y = self.element_space.org.y
        #if elements are not visible, no need to draw them.
        if self.element_space.has_area():
            for e in self.elements:
                e.draw(self.element_space)
                self.element_space.org.y+= e.height
            self.outline.org.y = org_y


    cpdef handle_input(self, Input new_input,bint visible):
        if not self.read_only:
            global should_redraw

            if self.resize_corner is not None:
                self.resize_corner.handle_input(new_input,visible)
            if self.handlebar is not None:
                self.handlebar.handle_input(new_input,visible)

            #if elements are not visible, no need to interact with them.
            if self.element_space.has_area():
                for e in self.elements:
                    e.handle_input(new_input, visible)

    cpdef precompute(self,FitBox parent):
        #here we compute the requred design height of this menu.
        self.outline.design_size.y  = self.height/ui_scale
        self.outline.compute(parent)

    property height:
        def __get__(self):
            cdef float height = 0
            #space from outline to element space at top
            height += self.element_space.design_org.y*ui_scale
            #space from elementspace to outline at bottom
            height -= self.element_space.design_size.y*ui_scale #double neg
            if self.collapsed:
                #elemnt space is 0
                pass
            else:
                height += sum([<float>e.height for e in self.elements])
            return height


    def toggle_iconified(self):
        global should_redraw
        should_redraw = True
        self.collapsed = not self.collapsed

    property configuration:
        def __get__(self):
            return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':self.collapsed}

        def __set__(self,new_conf):
            self.outline.design_org[:] = new_conf['pos']
            self.outline.design_size[:] = new_conf['size']
            self.collapsed = new_conf['collapsed']
            self.header_pos = self.header_pos #update layout


cdef class Scrolling_Menu(Base_Menu):
    '''
    Scrolling_Menu is a movable object on the canvas that contains other elements
    and scrolls when they overflow the space.

    size positive -> size from self.org
    size 0 -> span into parent context and lock it like this. If you want it draggable use -.001 or .001
    size negative -> make the box to up to size pixels to the parent container.
    position negative -> align to the opposite side of context
    position 0  -> span into parent context and lock it like this. If you want it draggable use -.001 or .001

    '''
    cdef FitBox uncollapsed_outline
    cdef Draggable scrollbar
    cdef Vec2 scrollstate
    cdef float scroll_factor

    def __cinit__(self,label,pos=(0,0),size=(200,100),header_pos = 'top'):
        self.uid = id(self)
        self.label = label

        if header_pos in ('top','bottom'):
            min_size = Vec2(menu_topbar_min_width,menu_topbar_pad)
        elif header_pos in ('left','right'):
            min_size = Vec2(menu_sidebar_pad,menu_sidebar_min_height)
        else:
            min_size = Vec2(0,0)
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=min_size)
        self.uncollapsed_outline = self.outline.copy()
        self.elements = []

        self.scrollstate = Vec2(0,0)
        self.scrollbar = Draggable(Vec2(0,0),Vec2(0,0),self.scrollstate,arrest_axis=1,zero_crossing=True)
        self.scroll_factor = 1.
        self.header_pos = header_pos
        self.color = RGBA(0,0,0,.3)

    def __init__(self,label,pos=(0,0),size=(200,100),header_pos = 'top'):
        pass

    property header_pos:
        def __get__(self):
            header_pos_list = ['top','bottom','left','right','hidden']
            return header_pos_list[self.header_pos_id]

        def __set__(self, header_pos):
            if header_pos == 'top':
                self.element_space = FitBox(Vec2(menu_pad,menu_topbar_pad + menu_pad),Vec2(-menu_pad,-menu_pad- menu_bottom_pad))
                self.handlebar = Draggable(Vec2(0,0),Vec2(0,menu_topbar_pad),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )
                if self.outline.design_size:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                self.outline.design_size,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'bottom':
                self.element_space = FitBox(Vec2(menu_pad, +menu_bottom_pad+menu_pad),Vec2(-menu_pad,-menu_pad- menu_topbar_pad))
                self.handlebar = Draggable(Vec2(0,-menu_topbar_pad),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(resize_corner_size,resize_corner_size),
                                                self.outline.design_org,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'right':
                self.element_space = FitBox(Vec2(menu_pad, 0),Vec2(-menu_pad-menu_sidebar_pad,0))
                self.handlebar = Draggable(Vec2(-menu_sidebar_pad,0),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_org:
                    self.resize_corner = Draggable(Vec2(0,0),Vec2(resize_corner_size,resize_corner_size),
                                                self.outline.design_org,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'left':
                self.element_space = FitBox(Vec2(menu_pad+menu_sidebar_pad, 0),Vec2(-menu_pad,0))
                self.handlebar = Draggable(Vec2(0,0),Vec2(menu_sidebar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified )

                if self.outline.design_size:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=0,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.handlebar = None


            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom', was %s "%header_pos)

            self.header_pos_id = ['top','bottom','left','right','hidden'].index(header_pos)



    cpdef draw(self,FitBox parent,bint nested=True):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        self.draw_menu(nested)

        #if elements are not visible, no need to draw them.
        if self.element_space.has_area():
            self.draw_scroll_window_elements()

    cdef draw_scroll_window_elements(self):
        self.push_scissor()
        self.scrollbar.outline.compute(self.element_space)

        #compute scroll stack height.
        cdef float h = sum([e.height for e in self.elements])


        #display that we have scrollable content
        #if self.scroll_factor < 1:
        #    self.element_space.size.x -=20


        #If the scollbar is not active, make sure the content is not scrolled away:
        if not self.scrollbar.selected or 1:
            #self.scrollstate.y = clamp(self.scrollstate.y,min(-h,self.element_space.size.y-h),0)
            self.scrollstate.y = clamp(self.scrollstate.y,(-h/ui_scale)+35,0)

        #render elements
        self.element_space.org.y += self.scrollstate.y*ui_scale

        for e in self.elements:
            e.draw(self.element_space)
            self.element_space.org.y+= e.height
        self.element_space.org.y -= self.scrollstate.y*ui_scale
        self.element_space.org.y -= h


        self.pop_scissor()

    cdef push_scissor(self):
        # compute and set gl scissor
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

    cdef pop_scissor(self):
        #restore scissor state
        gl.glPopAttrib()


    cpdef handle_input(self, Input new_input,bint visible):
        cdef bint mouse_over_menu = 0
        if not self.read_only:
            global should_redraw

            if self.resize_corner is not None:
                self.resize_corner.handle_input(new_input,visible)
            if self.handlebar is not None:
                self.handlebar.handle_input(new_input,visible)

            #if elements are not visible, no need to interact with them.
            if self.element_space.has_area():
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


    def toggle_iconified(self):
        global should_redraw
        should_redraw = True

        if self.outline.is_collapsed():
            self.outline.inflate(self.uncollapsed_outline)
        else:
            self.uncollapsed_outline = self.outline.copy()
            self.outline.collapse()


    property collapsed:
        def __get__(self):
            return self.outline.is_collapsed()

        def __set__(self,new_state):
            if bool(new_state) == bool(self.outline.is_collapsed()):
                self.toggle_iconified()

    property configuration:
        def __get__(self):
            if self.outline.is_collapsed():
                return {'pos':self.uncollapsed_outline.design_org[:],'size':self.uncollapsed_outline.design_size[:],'collapsed':True}
            else:
                return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':False}

        def __set__(self,new_conf):
            self.outline.design_org[:] = new_conf['pos']
            self.outline.design_size[:] = new_conf['size']
            self.header_pos = self.header_pos #update layout
            if new_conf['collapsed'] and not self.outline.is_collapsed():
                self.toggle_iconified()

