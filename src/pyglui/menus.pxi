

cdef float sort_key(UI_element elm):
        return elm._order


cdef class Base_Menu(UI_element):
    """
    Base class that other menu inherit from. Dont use this.
    This contains all methods/attributed shared by all derived menus.
    """

    cdef public list elements
    cdef FitBox element_space
    cdef readonly int header_pos_id
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
        global should_redraw
        should_redraw = True

    def __delitem__ (self,x):
        del self.elements[x]
        global should_redraw
        should_redraw = True

    def __contains__ (self,obj):
        return obj in self.elements

    def __bool__(self):
        return True


    cdef get_submenu_config(self):
        '''
        Menus are sometimes emebedded in Other menues. We load their configurations recursively.
        '''
        cdef dict submenus = {}
        for e in self.elements:
            if isinstance(e,(Growing_Menu, Scrolling_Menu, Stretching_Menu, Container)):
                submenus[e.label] = submenus.get(e.label,[]) + [e.configuration] #we could have two submenues with same label so we use a list for each submenu label cotaining the conf dicts for each menu
        return submenus

    cdef set_submenu_config(self,dict submenus):
        '''
        Growing menus are sometimes emebedded in Other menues. We save their configurations recursively.
        '''
        if submenus:
            for e in self.elements:
                if isinstance(e,(Growing_Menu,Scrolling_Menu,Stretching_Menu,Container)):
                    e.configuration = submenus.get(e.label,[{}]).pop(0) #pop of the first menu conf dict in the list.


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
                self.outline.sketch(self.color)
                self.outline.org.x -= menu_sidebar_pad*ui_scale
                self.outline.size.x += menu_sidebar_pad*ui_scale

            elif self.header_pos_id == 3: #right
                self.outline.size.x -= menu_sidebar_pad*ui_scale
                self.outline.sketch(self.color)
                self.outline.size.x += menu_sidebar_pad*ui_scale
            else:
                self.outline.sketch(self.color)

        if self.resize_corner is not None:
            self.resize_corner.outline.compute(self.outline)
            tripple_d(self.resize_corner.outline.org,self.resize_corner.outline.size)

        if self.menu_bar is not None:
            self.menu_bar.outline.compute(self.outline)
            if self.minimize_corner is not None:
                self.minimize_corner.outline.compute(self.menu_bar.outline)
            #self.minimize_corner.outline.sketch()
            if 2 == self.header_pos_id: #left
                if self.element_space.has_area():
                    tripple_v(self.menu_bar.outline.org+menu_offset,tripple_v_size)
                # else:
                #     triangle_right(self.menu_bar.outline.org+menu_offset,tripple_v_size)
            elif 3 == self.header_pos_id: #right
                if self.element_space.has_area():
                    tripple_v(self.menu_bar.outline.org+menu_offset,tripple_v_size)
                else:
                    triangle_left(self.menu_bar.outline.org+menu_offset,tripple_v_size)
            elif 0 == self.header_pos_id:  #top (botton not implemented)
                if nested:
                    menu_offset.x = 0
                if self.element_space.has_area():
                    tripple_h(self.menu_bar.outline.org+menu_offset,tripple_h_size)
                else:
                    triangle_h(self.menu_bar.outline.org+menu_offset,tripple_h_size,RGBA(*color_line_default))

                glfont.draw_text(self.menu_bar.outline.org.x+menu_offset.x+menu_topbar_text_x_org*ui_scale,
                                 self.outline.org.y+menu_offset.y,self._label)
                line(Vec2(self.menu_bar.outline.org.x+menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                     Vec2(self.menu_bar.outline.org.x+self.menu_bar.outline.size.x-menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                     RGBA(*menu_line))
            elif isinstance(self, Timeline_Menu):
                size = Vec2(2. * timelines_draggable_size * ui_scale, timelines_draggable_size * ui_scale)
                org = Vec2(*self.menu_bar.outline.center) - size / 2.
                border_color = RGBA(*color_line_default)

                gl.glColor4f(border_color.r, border_color.g, border_color.b, border_color.a)

                line_w = 2. * ui_scale
                gl.glLineWidth(line_w)
                gl.glBegin(gl.GL_LINES)
                gl.glVertex3f(org.x, org.y + size.y / 4, 0)
                gl.glVertex3f(org.x + size.x, org.y + size.y / 4, 0)
                gl.glVertex3f(org.x, org.y + size.y / 2, 0)
                gl.glVertex3f(org.x + size.x, org.y + size.y / 2, 0)
                gl.glEnd()

                line_w *= 2
                gl.glLineWidth(line_w)
                gl.glBegin(gl.GL_LINES)
                gl.glVertex3f(self.element_space.org.x, self.element_space.org.y - line_w / 2, 0)
                gl.glVertex3f(self.element_space.org.x + self.element_space.size.x,
                              self.element_space.org.y - line_w / 2, 0)
                gl.glEnd()


            elif 5 == self.header_pos_id:  #headline
                if not self.collapsed:
                    glfont.draw_text(self.menu_bar.outline.org.x+menu_offset.x,
                                     self.outline.org.y+menu_offset.y,self._label)
                    line(Vec2(self.menu_bar.outline.org.x+menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                         Vec2(self.menu_bar.outline.org.x+self.menu_bar.outline.size.x-menu_offset.x,self.menu_bar.outline.org.y+self.menu_bar.outline.size.y),
                         RGBA(*menu_line))

            # (botton not implemented)
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
            header_pos_list = ['top','bottom','left','right','hidden','headline']
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
                                                 self.outline.design_org, arrest_axis=0,
                                                 zero_crossing = False, catch_input = catch_input)
                # remove click_cb to prevent interaction conflict in new Pupil ui

                if self.outline.design_size.x > 0:
                    self.resize_corner = Draggable(Vec2(-resize_corner_size,-resize_corner_size),Vec2(0,0),
                                                    self.outline.design_size,
                                                    arrest_axis=2,zero_crossing = False)

            elif header_pos == 'hidden':
                self.element_space = FitBox(Vec2(0,0),Vec2(0,0))
                self.resize_corner = None
                self.menu_bar = None
            elif header_pos == 'headline':
                self.menu_bar = Draggable(Vec2(0,0),Vec2(0,menu_topbar_pad),
                                            self.outline.design_org,
                                            arrest_axis=1,zero_crossing = False,
                                            catch_input = catch_input  )
                self.element_space = FitBox(Vec2(0,menu_topbar_pad),Vec2(0,0))
                self.resize_corner = None

            else:
                raise Exception("Header Positon argument needs to be one of 'top,right,left,bottom','headline' was %s "%header_pos)

            self.header_pos_id = ['top','bottom','left','right','hidden','headline'].index(header_pos)




cdef class Stretching_Menu(Base_Menu):
    '''
    A simple menu
    Not movable and fixed in height.
    It will space its content evenenly in y.
    '''
    cdef public bint collapsed

    def __cinit__(self,label,pos=(0,0),size=(200,100)):
        self.uid = id(self)
        self._label = label
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=Vec2(0,0))
        self.element_space = FitBox(position=Vec2(menu_pad,menu_pad),size=Vec2(-menu_pad,-menu_pad))
        self.elements = []
        self.color = RGBA(*rect_color_default)
        self.collapsed = False

    def __init__(self,label,pos=(0,0),size=(200,100)):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        cdef float h = 0,y_spacing=0,org_y=0
        if not self.collapsed:
            self.elements.sort(key=sort_key)
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

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        if not self.collapsed and self.element_space.has_area():
            self.elements.sort(key=sort_key)
            for e in self.elements:
                (<UI_element>e).draw_overlay(self.element_space, nested=False,
                                             parent_read_only=parent_read_only or self._read_only)

    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            for e in self.elements:
                e.handle_input(new_input, visible,self._read_only or parent_read_only)


    @property
    def configuration(self):
        cdef dict submenus = self.get_submenu_config()
        return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':self.collapsed,'submenus':submenus}

    @configuration.setter
    def configuration(self,new_conf):
        self.outline.design_org[:] = new_conf.get('pos',self.outline.design_org[:])
        self.outline.design_size[:] = new_conf.get('size',self.outline.design_size[:])
        self.collapsed = new_conf.get('collapsed',self.collapsed)
        self.set_submenu_config(new_conf.get('submenus',{}))

cdef class Horizontally_Stretching_Menu(Base_Menu):
    '''
    A simple menu
    Not movable and fixed in height.
    It will space its content evenenly in x.
    '''
    cdef public bint collapsed

    def __cinit__(self,label,pos=(0,0),size=(200,100)):
        self.uid = id(self)
        self._label = label
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=Vec2(0,0))
        self.element_space = FitBox(position=Vec2(menu_pad,menu_pad),size=Vec2(-menu_pad,-menu_pad))
        self.elements = []
        self.color = RGBA(*rect_color_default)
        self.collapsed = False

    def __init__(self,label,pos=(0,0),size=(200,100)):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        cdef float w=0, x_spacing=0, org_x=0
        if not self.collapsed:
            self.elements.sort(key=sort_key)
            self.outline.compute(parent)
            self.element_space.compute(self.outline)

            for e in self.elements:
                e.precompute(self.element_space)
                w += e.width

            x_spacing  = (self.element_space.size.x-w)/(len(self.elements)+1)
            org_x = self.element_space.org.x
            #if elements are not visible, no need to draw them.
            if self.element_space.has_area():
                self.element_space.org.x+= x_spacing
                for e in self.elements:
                    e.draw(self.element_space,nested= False, parent_read_only = parent_read_only or self._read_only)
                    self.element_space.org.x+= e.width + x_spacing
                self.outline.org.x = org_x

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        if not self.collapsed and self.element_space.has_area():
            self.elements.sort(key=sort_key)
            for e in self.elements:
                (<UI_element>e).draw_overlay(self.element_space, nested=False,
                                             parent_read_only=parent_read_only or self._read_only)

    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            for e in self.elements:
                e.handle_input(new_input, visible,self._read_only or parent_read_only)


    @property
    def configuration(self):
        cdef dict submenus = self.get_submenu_config()
        return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'collapsed':self.collapsed,'submenus':submenus}

    @configuration.setter
    def configuration(self,new_conf):
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
    cdef bint _collapsed


    def __cinit__(self,label,pos=(0,0),size=(0,0),header_pos = 'top'):
        self.uid = id(self)
        self._label = label
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
        self.color = RGBA(*rect_color_default)

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
            self.elements.sort(key=sort_key)
            for e in self.elements:
                e.draw(self.element_space,parent_read_only = parent_read_only or self._read_only)
                self.element_space.org.y+= e.height
            self.outline.org.y = org_y

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        if self.element_space.has_area():
            self.elements.sort(key=sort_key)
            for e in self.elements:
                (<UI_element>e).draw_overlay(self.element_space, parent_read_only=parent_read_only or self._read_only)


    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        if self.resize_corner is not None:
            self.resize_corner.handle_input(new_input,visible)
        if self.menu_bar is not None:
            self.menu_bar.handle_input(new_input,visible)
        if self.minimize_corner is not None:
            self.minimize_corner.handle_input(new_input,visible)


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
            cdef float height = 0.0000001 #0 is magic and not meant when hight is computed to be 0.
            if self.header_pos_id == 5 and self.collapsed:
                pass
            else:
                #space from outline to element space at top
                height += self.element_space.design_org.y*ui_scale
            #space from element_space to outline at bottom
            height -= self.element_space.design_size.y*ui_scale #double neg
            if self._collapsed:
                #elemnt space is 0
                pass
            else:
                for e in self.elements:
                    e.precompute(self.element_space)
                height += sum([<float>e.height for e in self.elements])
            return height


    def toggle_iconified(self):
        self.collapsed = not self.collapsed

    property collapsed:
        def __get__(self):
            return self._collapsed
        def __set__(self,collapsed):
            if collapsed != self._collapsed:
                global should_redraw
                should_redraw = True
                self._collapsed = not self._collapsed


    @property
    def configuration(self):
        cdef dict submenus = self.get_submenu_config()
        return {'pos':self.outline.design_org[:],'size':[self.outline.design_size[0],0],'collapsed':self.collapsed,'submenus':submenus}

    @configuration.setter
    def configuration(self,new_conf):
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
    cdef bint _collapsed

    def __cinit__(self,label,pos=(100,100),size=(200,100),header_pos = 'top'):
        self.uid = id(self)
        self._label = label

        if header_pos in ('top', 'bottom', 'headline'):
            min_size = Vec2(menu_topbar_min_width,menu_topbar_pad)
        elif header_pos in ('right'):
            min_size = Vec2(menu_sidebar_pad,menu_sidebar_min_height)
        elif header_pos in ('left'):
            min_size = Vec2(menu_topbar_min_width,menu_sidebar_min_height)
        else:
            min_size = Vec2(0,0)
        self.outline = FitBox(position=Vec2(*pos),size=Vec2(*size),min_size=min_size)
        self.uncollapsed_outline = self.outline.copy()
        self._collapsed = False
        self.elements = []

        self.scrollstate = Vec2(0,0)
        self.scrollbar = Draggable(Vec2(0,0),Vec2(0,0),self.scrollstate,arrest_axis=1,zero_crossing=True)
        self.header_pos = header_pos
        self.color = RGBA(*rect_color_default)

    def __init__(self,label,pos=(100,100),size=(200,100),header_pos = 'top'):
        pass

    def __str__(self):
        return "Scrolling_Menu {}".format(self._label)

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)

        # collapse/inflate if needed
        if self.collapsed == self.element_space.has_area():
            if self.collapsed:
                self.uncollapsed_outline = self.outline.copy()
                self.outline.min_size = Vec2(0., 0.)
                self.outline.collapse()
            else:
                self.outline.min_size[:] = self.uncollapsed_outline.min_size[:]
                self.outline.inflate(self.uncollapsed_outline)
            self.outline.compute(parent)
            self.element_space.compute(self.outline)

        if self.header_pos_id == 2:
            nested = nested or self.collapsed
        self.draw_menu(nested)

        #if elements are not visible, no need to draw them.
        if self.element_space.has_area():
            self.elements.sort(key=sort_key)
            self.draw_scroll_window_elements(parent_read_only)

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        if self.element_space.has_area():
            self.elements.sort(key=sort_key)
            for e in self.elements:
                (<UI_element>e).draw_overlay(self.element_space, parent_read_only=parent_read_only or self._read_only)

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

        cdef float scroll_factor = self.element_space.size.y/(h or 1)
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
        if self.minimize_corner is not None and not (2 == self.header_pos_id and not self.element_space.has_area()):
            self.minimize_corner.handle_input(new_input,visible)
        if self.menu_bar is not None:
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
        self.collapsed = not self.collapsed

    @property
    def collapsed(self):
        return self._collapsed

    @collapsed.setter
    def collapsed(self, should_collapse):
        if should_collapse != self.collapsed:
            global should_redraw
            should_redraw = True
            self._collapsed = should_collapse

    @property
    def configuration(self):
        cdef dict submenus = self.get_submenu_config()
        if self.collapsed:
            return {'label': self.label,
                    'pos':self.outline.design_org[:],
                    'size':self.outline.design_size[:],
                    'scrollstate':self.scrollstate[:],
                    'collapsed':True,
                    'min_size': self.outline.min_size[:],
                    'uncollapsed_min_size': self.uncollapsed_outline.min_size[:],
                    'uncollapsed_pos':self.uncollapsed_outline.design_org[:],
                    'uncollapsed_size':self.uncollapsed_outline.design_size[:],
                    'submenus':submenus}
        else:
            return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],
                    'collapsed':False,'submenus':submenus,'scrollstate':self.scrollstate[:],
                    'min_size': self.outline.min_size[:]}

    @configuration.setter
    def configuration(self, new_conf):
        self.outline.design_org[:] = new_conf.get('pos', self.outline.design_org[:])
        self.outline.design_size[:] = new_conf.get('size', self.outline.design_size[:])
        self.outline.min_size[:] = new_conf.get('min_size', None)

        if new_conf.get('collapsed', False):

            self.uncollapsed_outline.design_org[:] = new_conf.get('uncollapsed_pos',self.outline.design_org[:])
            self.uncollapsed_outline.design_size[:] = new_conf.get('uncollapsed_size',self.outline.design_size[:])
            self.uncollapsed_outline.min_size[:] = new_conf.get('uncollapsed_min_size',None)

        self.collapsed = new_conf.get('collapsed', False)
        self.header_pos = self.header_pos #update layout
        self.scrollstate[:] = new_conf.get('scrollstate',(0,0))
        self.set_submenu_config(new_conf.get('submenus',{}))


cdef class Container(Base_Menu):

    cdef public UI_element horizontal_constraint, vertical_constraint

    def __cinit__(self, pos=(0., 0.), size=(0., 0.), padding=(0., 0.)):
        self.outline = FitBox(Vec2(*pos), Vec2(*size))
        self.element_space = FitBox(Vec2(*padding), Vec2(0., 0.) - Vec2(*padding))
        self.elements = []
        self.horizontal_constraint = None
        self.vertical_constraint = None
        self.label = 'Container'

    def init(self, *args, **kwargs):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        # compute constraints
        cdef FitBox copy = parent.computed_copy()
        self.outline.compute(copy)
        if self.horizontal_constraint is not None:
            self.horizontal_constraint.precompute(parent)
            if 0 <= copy.org.x < self.horizontal_constraint.outline.org.x < copy.org.x + copy.size.x:
                copy.size.x = self.horizontal_constraint.outline.org.x - copy.org.x
                if isinstance(self.horizontal_constraint, Base_Menu) and self.horizontal_constraint.header_pos_id == 2 and not self.horizontal_constraint.collapsed:  # left header
                    copy.size.x += menu_sidebar_pad * ui_scale
            elif 0 <= self.horizontal_constraint.outline.org.x + self.horizontal_constraint.outline.size.x <= copy.org.x:
                copy.size.x = self.horizontal_constraint.outline.org.x + self.horizontal_constraint.outline.size.x - copy.org.x
                copy.org.x = self.horizontal_constraint.outline.org.x + self.horizontal_constraint.outline.size.x

        self.outline.compute(copy)
        self.element_space.compute(self.outline)

        self.elements.sort(key=sort_key)
        if self.element_space.has_area():
            for e in self.elements:
                e.draw(self.element_space,nested= False, parent_read_only = parent_read_only or self._read_only)

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        if self.element_space.has_area():
            self.elements.sort(key=sort_key)
            for e in self.elements:
                (<UI_element>e).draw_overlay(self.element_space, nested=False,
                                             parent_read_only=parent_read_only or self._read_only)

    cpdef handle_input(self, Input new_input,bint visible,bint parent_read_only = False):
        #if elements are not visible, no need to interact with them.
        if self.element_space.has_area():
            for e in self.elements:
                e.handle_input(new_input, visible,self._read_only or parent_read_only)

    @property
    def configuration(self):
        cdef dict submenus = self.get_submenu_config()
        return {'pos':self.outline.design_org[:],'size':self.outline.design_size[:],'submenus':submenus}

    @configuration.setter
    def configuration(self,new_conf):
        self.outline.design_org[:] = new_conf.get('pos',self.outline.design_org[:])
        self.outline.design_size[:] = new_conf.get('size',self.outline.design_size[:])
        self.set_submenu_config(new_conf.get('submenus',{}))


cdef class Timeline_Menu(Scrolling_Menu):
    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only=False):
        self.outline.compute(parent)
        self.element_space.compute(self.outline)
        self.element_space.sketch(RGBA(0., 0., 0., 0.3))
        super(Timeline_Menu, self).draw(parent, nested, parent_read_only)

    @property
    def collapsed(self):
        return self.outline.design_org.y >= -menu_topbar_pad

    @collapsed.setter
    def collapsed(self,collapsed):
        if collapsed != self.collapsed:
            self.toggle_iconified()

    def toggle_iconified(self):
        global should_redraw
        should_redraw = True

        if self.collapsed:
            self.outline.inflate(self.uncollapsed_outline)
        else:
            self.uncollapsed_outline = self.outline.copy()
            self.outline.collapse()

    def append(self, obj):
        if len(self.elements) == 0:
            self.collapsed = False
        super(Timeline_Menu, self).append(obj)

    def insert(self, idx, obj):
        if len(self.elements) == 0:
            self.collapsed = False
        super(Timeline_Menu, self).insert(idx, obj)

    def extend(self, objs):
        if len(self.elements) == 0:
            self.collapsed = False
        super(Timeline_Menu, self).extend(objs)

    def remove(self, obj):
        super(Timeline_Menu, self).remove(obj)
        if len(self.elements) == 0:
            self.collapsed = True
