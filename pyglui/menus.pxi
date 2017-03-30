

cdef class Base_Menu(UI_element):
    """
    Base class that other menu inherit from. Dont use this.
    This contains all methods/attributed shared by all derived menus.
    """

    cdef public list elements
    cdef FitBox element_space
    cdef int header_pos_id
    cdef Draggable menu_bar,minimize_corner, resize_corner
    cdef public RGBA color

    cpdef sync(self):
        if self.element_space.has_area():
            for e in self.elements:
                e.sync()

    def append(self, obj):
        if not issubclass(obj.__class__,UI_element):
            raise Exception("Can only append UI elements, not: '%s'"%obj )
        self.elements.append(obj)
        global should_redraw
        should_redraw = True

    def insert(self,idx, obj):
        if not issubclass(obj.__class__,UI_element):
            raise Exception("Can only append UI elements, not: '%s'"%obj )
        self.elements.insert(idx,obj)
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


    cdef get_submenu_config(self):
        '''
        Growing menus are sometimes emebedded in Other menus. We load their configurations recursively.
        '''
        cdef dict submenus = {}
        for e in self.elements:
            if isinstance(e,(Growing_Menu,Scrolling_Menu,Stretching_Menu)):
                submenus[e.label] = submenus.get(e.label,[]) + [e.configuration] #we could have two submenus with same label so we use a list for each submenu label cotaining the conf dicts for each menu
        return submenus

    cdef set_submenu_config(self,object submenus):
        '''
        Growing menus are sometimes emebedded in Other menus. We save their configurations recursively.
        '''
        if submenus:
            # submenus is an Immutable_Dict with tuples as values.
            # Keep state of current submenu entry with iterators
            conf_iters = {k: iter(submenus[k]) for k in submenus.keys()}
            for e in self.elements:
                if isinstance(e,(Growing_Menu,Scrolling_Menu,Stretching_Menu)):
                    e.configuration = next(conf_iters[e.label]) if e.label in conf_iters else {}


    cdef draw_menu(self,bint nested):
        #draw translucent background
        cdef Vec2 tripple_h_size = Vec2(menu_move_corner_width*ui_scale,menu_move_corner_height*ui_scale)
        cdef Vec2 tripple_v_size = Vec2(menu_move_corner_height*ui_scale,menu_move_corner_width*ui_scale)
        cdef Vec2 menu_offset = Vec2(menu_pad*ui_scale,menu_pad*ui_scale)
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
            tripple_d(self.resize_corner.outline.org,self.resize_corner.outline.size)

        if self.menu_bar is not None:
            self.menu_bar.outline.compute(self.outline)
            self.minimize_corner.outline.compute(self.menu_bar.outline)
            #self.minimize_corner.outline.sketch()
            if 2 == self.header_pos_id: #left
                if self.element_space.has_area():
                    tripple_v(self.menu_bar.outline.org+menu_offset,tripple_v_size)
                else:
                    triangle_right(self.menu_bar.outline.org+menu_offset,tripple_v_size)
            elif 3 == self.header_pos_id: #right
                if self.element_space.has_area():
                    tripple_v(self.menu_bar.outline.org+menu_offset,tripple_v_size)
                else:
                    triangle_left(self.menu_bar.outline.org+menu_offset,tripple_v_size)
            else: #top (botton not implemented)
                if nested:
                    menu_offset.x = 0
                if self.element_space.has_area():
                    tripple_h(self.menu_bar.outline.org+menu_offset,tripple_h_size)
                else:
                    triangle_h(self.menu_bar.outline.org+menu_offset,tripple_h_size,RGBA(*color_line_default))

                glfont.draw_text(self.menu_bar.outline.org.x+menu_offset.x+menu_topbar_text_x_org*ui_scale,
                                 self.outline.org.y+menu_offset.y,self.label)
                line(Vec2(self.menu_bar.outline.org.x+menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                     Vec2(self.menu_bar.outline.org.x+self.menu_bar.outline.size.x-menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                     RGBA(*menu_line))

    def collect_in_window(self,FitBox window):
        global should_redraw
        if self.outline.design_org.x > 0:
            self.outline.design_org.x = min(self.outline.design_org.x, window.size.x/ui_scale-100)
            should_redraw = True
        if self.outline.design_org.y > 0:
            self.outline.design_org.y = min(self.outline.design_org.y, window.size.y/ui_scale-100)
            should_redraw = True
        if self.outline.design_org.x < 0:
            self.outline.design_org.x = max(self.outline.design_org.x, -1* window.size.x/ui_scale-100)
            should_redraw = True
        if self.outline.design_org.y < 0:
            self.outline.design_org.y = min(self.outline.design_org.y, -1* window.size.y/ui_scale-100)
            should_redraw = True


cdef class Movable_Menu(Base_Menu):
    '''
    Abstract class that implemented movable ui elements.
    '''


    property header_pos:
        def __get__(self):
            header_pos_list = ['top','bottom','left','right','hidden']
            return header_pos_list[self.header_pos_id]

        def __set__(self, header_pos):
            #if the menu position is user changable we want the dragable to catch the input. This is good of user interaction
            cdef bint catch_input =  bool(self.outline.design_org.x or self.outline.design_org.y)

            if header_pos == 'top':
                self.element_space = FitBox(Vec2(menu_pad,menu_topbar_pad),Vec2(-menu_pad,-menu_pad- menu_bottom_pad))
                self.menu_bar = Draggable(Vec2(0,0),Vec2(0,menu_topbar_pad),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            catch_input = catch_input )
                self.minimize_corner = Draggable(Vec2(0,0),Vec2(menu_topbar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified,catch_input = catch_input )
                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                self.outline.design_size,
                                                arrest_axis=0,zero_crossing = False)
                else:
                    self.resize_corner = None

            elif header_pos == 'bottom':
                self.element_space = FitBox(Vec2(menu_pad,menu_bottom_pad + menu_pad),Vec2(-menu_pad,-menu_pad- menu_topbar_pad))
                self.menu_bar = Draggable(Vec2(0,-menu_pad),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            catch_input = catch_input  )
                self.minimize_corner = Draggable(Vec2(0,0),Vec2(menu_topbar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified,catch_input = catch_input )
                self.resize_corner = None

            elif header_pos == 'right':
                self.element_space = FitBox(Vec2(menu_pad,0),Vec2(-menu_pad-menu_sidebar_pad,0))
                self.menu_bar = Draggable(Vec2(-menu_sidebar_pad,0),Vec2(0,0),
                                            self.outline.design_size,
                                            arrest_axis=0,zero_crossing = False,
                                            catch_input = catch_input  )
                self.minimize_corner = Draggable(Vec2(0,0),Vec2(menu_topbar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified,catch_input = catch_input )
                self.resize_corner = None

            elif header_pos == 'left':
                self.element_space = FitBox(Vec2(menu_sidebar_pad+menu_pad,0),Vec2(-menu_pad,0))
                self.menu_bar = Draggable(Vec2(0,0),Vec2(menu_sidebar_pad,0),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            catch_input = catch_input  )
                self.minimize_corner = Draggable(Vec2(0,0),Vec2(0,menu_topbar_pad),
                                            self.outline.design_org,
                                            arrest_axis=0,zero_crossing = False,
                                            click_cb=self.toggle_iconified,catch_input = catch_input )

                if self.outline.design_size.x:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=2,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.menu_bar = None


            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom', was %s "%header_pos)

            self.header_pos_id = ['top','bottom','left','right','hidden'].index(header_pos)




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

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
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
                    e.draw(self.element_space,nested= False, parent_read_only = parent_read_only or self._read_only)
                    self.element_space.org.y+= e.height + y_spacing
                self.outline.org.y = org_y


    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            for e in self.elements:
                e.handle_input(new_input, visible,self._read_only or parent_read_only)


    property configuration:
        def __get__(self):
            cdef dict submenus = self.get_submenu_config()
            return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':self.collapsed,'submenus':submenus}

        def __set__(self,new_conf):
            self.outline.design_org[:] = new_conf.get('pos',self.outline.design_org[:])
            self.outline.design_size[:] = new_conf.get('size',self.outline.design_size[:])
            self.collapsed = new_conf.get('collapsed',self.collapsed)
            self.set_submenu_config(new_conf.get('submenus',{}))


cdef class Growing_Menu(Movable_Menu):
    '''
    Growing_Menu is a movable object on the canvas grows with its content

    size height will be ignored as it depend on the content.
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

    def __init__(self,label, pos=(0,0),size=(0,0),header_pos = 'top'):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        #here we compute the requred design height of this menu.
        self.outline.design_size.y  = self.height/ui_scale
        #now we correct for any changes induced by the content.
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        self.draw_menu(nested)

        cdef float org_y = self.element_space.org.y
        #if elements are not visible, no need to draw them.
        if self.element_space.has_area():
            for e in self.elements:
                e.draw(self.element_space,parent_read_only = parent_read_only or self._read_only)
                self.element_space.org.y+= e.height
            self.outline.org.y = org_y


    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        if self.resize_corner is not None:
            self.resize_corner.handle_input(new_input,visible)
        if self.menu_bar is not None:
            self.minimize_corner.handle_input(new_input,visible)
            self.menu_bar.handle_input(new_input,visible)

        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            for e in self.elements:
                e.handle_input(new_input, visible,self._read_only or parent_read_only)

    cpdef precompute(self,FitBox parent):
        #here we compute the requred design height of this menu.
        self.outline.design_size.y  = self.height/ui_scale
        self.outline.compute(parent)

    property height:
        def __get__(self):
            cdef float height = 0
            #space from outline to element space at top
            height += self.element_space.design_org.y*ui_scale
            #space from element_space to outline at bottom
            height -= self.element_space.design_size.y*ui_scale #double neg
            if self.collapsed:
                #elemnt space is 0
                pass
            else:
                for e in self.elements:
                    e.precompute(self.element_space)
                height += sum([<float>e.height for e in self.elements])
            return height


    def toggle_iconified(self):
        global should_redraw
        should_redraw = True
        self.collapsed = not self.collapsed

    property configuration:
        def __get__(self):
            cdef dict submenus = self.get_submenu_config()
            return {'pos':self.outline.design_org[:],'size':[self.outline.design_size[0],0],'collapsed':self.collapsed,'submenus':submenus}

        def __set__(self,new_conf):
            #load from configutation if avaible, else keep old setting
            self.outline.design_org[:] = new_conf.get('pos',self.outline.design_org[:])
            self.outline.design_size[:] = new_conf.get('size',self.outline.design_size[:])
            self.collapsed = new_conf.get('collapsed',self.collapsed)
            self.header_pos = self.header_pos #update layout
            self.set_submenu_config(new_conf.get('submenus',{}))




cdef class Scrolling_Menu(Movable_Menu):
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

    def __cinit__(self,label,pos=(100,100),size=(200,100),header_pos = 'top'):
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
        self.header_pos = header_pos
        self.color = RGBA(0,0,0,.3)

    def __init__(self,label,pos=(100,100),size=(200,100),header_pos = 'top'):
        pass


    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)
        self.draw_menu(nested)

        #if elements are not visible, no need to draw them.
        if self.element_space.has_area():
            self.draw_scroll_window_elements(parent_read_only)

    cdef draw_scroll_window_elements(self, bint parent_read_only):

        #compute scroll stack height.
        cdef float h = sum([e.height for e in self.elements])

        #If the scollbar is not active, make sure the content is not scrolled away:
        if not self.scrollbar.selected or 1:
            #self.scrollstate.y = clamp(self.scrollstate.y,min(-h,self.element_space.size.y-h),0)
            self.scrollstate.y = clamp(self.scrollstate.y*ui_scale,min(0,-h+self.element_space.size.y),0)/ui_scale

        self.push_scissor()
        self.scrollbar.outline.compute(self.element_space)
        self.element_space.org.y += self.scrollstate.y*ui_scale

        #now we compute h for real:
        cdef float e_h = 0
        h = 0
        #render elements
        for e in self.elements:
            e.draw(self.element_space,parent_read_only = parent_read_only or self._read_only)
            e_h = e.height
            h += e_h
            self.element_space.org.y+= e_h
        self.element_space.compute(self.outline)

        self.pop_scissor()

        cdef float scroll_factor = self.element_space.size.y/h
        cdef float scroll_handle_offset = max(0,-self.scrollstate.y*ui_scale)*scroll_factor
        cdef float scroll_handle_size = self.element_space.size.y * scroll_factor

        #display that we have scrollable content
        if scroll_factor < 1:
            #self.element_space.size.x -= 10*ui_scale #shrink element space width to make room for scroll bar
            v_pad = 10*ui_scale
            start = self.element_space.org + self.element_space.size + Vec2(5*ui_scale,scroll_handle_offset-self.element_space.size.y+v_pad)
            end = self.element_space.org + self.element_space.size + Vec2(5*ui_scale,scroll_handle_offset+scroll_handle_size-self.element_space.size.y-v_pad)
            line(start,end,RGBA(*color_line_default))

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


    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        global should_redraw
        cdef bint mouse_over_menu = 0

        if self.resize_corner is not None:
            self.resize_corner.handle_input(new_input,visible)
        if self.menu_bar is not None:
            self.minimize_corner.handle_input(new_input,visible)
            self.menu_bar.handle_input(new_input,visible)

        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            # let the elements know that the mouse should be ignored
            # if outside of the visible scroll section
            mouse_over_menu =  self.element_space.org.y <= new_input.m.y <= self.element_space.org.y+self.element_space.size.y
            mouse_over_menu = mouse_over_menu and visible
            for e in self.elements:
                e.handle_input(new_input, mouse_over_menu,self._read_only or parent_read_only)

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

        if self.collapsed:
            self.outline.inflate(self.uncollapsed_outline)
        else:
            self.uncollapsed_outline = self.outline.copy()
            self.outline.collapse()


    property collapsed:
        def __get__(self):
            return not self.element_space.has_area()

        def __set__(self,new_state):
            if new_state != self.element_space.has_area():
                self.toggle_iconified()

    property configuration:
        def __get__(self):
            cdef dict submenus = self.get_submenu_config()
            if not self.element_space.has_area():
                return {'pos':self.outline.design_org[:],
                        'size':self.outline.design_size[:],
                        'scrollstate':self.scrollstate[:],
                        'collapsed':True,
                        'uncollapsed_pos':self.uncollapsed_outline.design_org[:],
                        'uncollapsed_size':self.uncollapsed_outline.design_size[:],
                        'submenus':submenus}
            else:
                return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':False,'submenus':submenus,'scrollstate':self.scrollstate[:]}
        def __set__(self,new_conf):

            self.outline.design_org[:] = new_conf.get('pos',self.outline.design_org[:])
            self.outline.design_size[:] = new_conf.get('size',self.outline.design_size[:])

            if new_conf.get('collapsed',False):
                self.uncollapsed_outline.design_org[:] = new_conf.get('uncollapsed_pos',self.outline.design_org[:])
                self.uncollapsed_outline.design_size[:] = new_conf.get('uncollapsed_size',self.outline.design_size[:])

            self.header_pos = self.header_pos #update layout
            self.scrollstate[:] = new_conf.get('scrollstate',(0,0))
            self.set_submenu_config(new_conf.get('submenus',{}))


