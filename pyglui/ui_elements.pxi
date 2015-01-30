########## UI_element ##########
# Base class
# see 'design_params.pxi' for design parameters
cdef class UI_element:
    '''
    The base class for all UI elements.
    '''
    cdef readonly bytes label
    cdef readonly long  uid
    cdef public FitBox outline
    cdef bint _read_only

    cpdef sync(self):
        global should_redraw
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        pass

    cpdef handle_input(self,Input new_input,bint visible, bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw
            pass

    cpdef pre_handle_input(self,Input new_input):
        # if your element needs to catch input event in front of everybody else:
        # add yourself to new_input.active_ui_elements during handle_input
        # pre_handle input will be called in the next frame with new input.
        # add yourself again in handle input if you need to stay in active_ui_elements
        pass

    cpdef precompute(self,FitBox parent):
        self.outline.compute(parent)

    property height:
        def __get__(self):
            return self.outline.size.y

    property read_only:
        def __get__(self):
            return self._read_only
        def __set__(self,bint val):
            if self._read_only != val:
                self._read_only = val
                global should_redraw
                should_redraw = True



########## Slider ##########
#    +--------------------------------+
#    | Label                    Value |
#    | ------------------O----------- |
#    +--------------------------------+

cdef class Slider(UI_element):
    cdef public float minimum,maximum,step
    cdef public FitBox field
    cdef bint selected
    cdef Vec2 slider_pos
    cdef Synced_Value sync_val
    cdef int steps
    cdef RGBA line_default_color, line_highlight_color, text_color, button_color, button_selected_color, button_shadow_color,step_color

    def __cinit__(self,bytes attribute_name, object attribute_context = None,label = None, min = 0, max = 100, step = 0,setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.step = abs(step)
        self.minimum = min
        if self.step:
            self.maximum = ((max-min)//self.step)*self.step+min
        else:
            self.maximum = max
        self.outline = FitBox(Vec2(0,0),Vec2(0,slider_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.slider_pos = Vec2(0,slider_label_org_y)
        self.selected = False
        self._read_only = False
        if self.step:
            self.steps = int((self.maximum-self.minimum)/float(step))
        else:
            self.steps = 0
        self.line_default_color = RGBA(*slider_line_color_default)
        self.line_highlight_color = RGBA(*slider_line_color_highlight)
        self.text_color = RGBA(*color_text_default)
        self.button_color = RGBA(*color_default)
        self.button_selected_color = RGBA(*color_selected)
        self.button_shadow_color = RGBA(*color_shadow)
        self.step_color = RGBA(*slider_color_step)


    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        self.sync()
        if not isinstance(self.sync_val.value, (float,int) ):
            raise Exception('Slider values should be float or int type. "%s" is of type %s'%(self.sync_val.value,type(self.sync_val.value)))


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance:
        self.outline.compute(parent)
        self.field.compute(self.outline)

        # map slider value
        self.slider_pos.x = clampmap(self.sync_val.value,self.minimum,self.maximum,0,self.field.size.x)
        #self.outline.sketch()
        #self.field.sketch()

        # read only rendering rules
        # cdef tuple line_default_color, line_highlight_color, text_color, button_color, button_shadow_color
        if self._read_only or parent_read_only:
            self.line_default_color = RGBA(*slider_line_color_default_read_only)
            self.line_highlight_color = RGBA(*slider_line_color_highlight_read_only)
            self.text_color = RGBA(*color_text_read_only)
            self.button_color = RGBA(*color_default_read_only)
            self.button_shadow_color = RGBA(*color_shadow_read_only)
        else:
            self.line_default_color = RGBA(*slider_line_color_default)
            self.line_highlight_color = RGBA(*slider_line_color_highlight)
            self.text_color = RGBA(*color_text_default)
            self.button_color = RGBA(*color_default)
            self.button_shadow_color = RGBA(*color_shadow)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)

        glfont.push_state()
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        glfont.set_color_float(self.text_color[:])


        if type(self.sync_val.value) == float:
            glfont.draw_text(self.field.size.x-x_spacer,0,bytes('%0.2f'%self.sync_val.value) )
            glfont.pop_state()
            used_x = glfont.text_bounds(0,0,bytes('%0.2f'%self.sync_val.value))
        else:
            glfont.draw_text(self.field.size.x-x_spacer,0,bytes(self.sync_val.value ))
            glfont.pop_state()
            used_x = glfont.text_bounds(0,0,bytes(self.sync_val.value))

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])
        glfont.draw_limited_text(x_spacer,0,self.label,self.field.size.x-3*x_spacer-used_x)
        glfont.pop_state()

        line(Vec2(0,slider_handle_org_y),Vec2(self.field.size.x, slider_handle_org_y),self.line_default_color)
        line(Vec2(0,slider_handle_org_y),Vec2(self.slider_pos.x,slider_handle_org_y),self.line_highlight_color)

        cdef float step_pixel_size,x
        if self.steps>1:
            step_pixel_size = lmap(self.minimum+self.step,self.minimum,self.maximum,0,self.field.size.x)
            if step_pixel_size >= slider_button_size*ui_scale:
                step_marks = [(x*step_pixel_size,slider_handle_org_y) for x in range(self.steps+1)]
                utils.draw_points(step_marks,size=slider_step_mark_size*ui_scale, color=self.step_color)

        if self.selected:
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=(slider_button_size_selected+slider_button_shadow)*ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size_selected*ui_scale, color=self.button_selected_color)
        else:
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=(slider_button_size+slider_button_shadow)+ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size*ui_scale, color=self.button_color)

        gl.glPopMatrix()



    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            if self.selected and new_input.dm:
                val = clampmap(new_input.m.x-self.field.org.x,0,self.field.size.x,self.minimum,self.maximum)
                #conserve some spcial types.
                if isinstance(self.sync_val.value,int):
                    self.sync_val.value = int(step(val,self.minimum,self.maximum,self.step))
                else:
                    self.sync_val.value = step(val,self.minimum,self.maximum,self.step)

                should_redraw = True

            for b in new_input.buttons:
                if b[1] == 1 and visible:
                    if mouse_over_center(self.slider_pos+self.field.org,self.field.size.y,self.field.size.y,new_input.m):
                        new_input.buttons.remove(b) # the slider should catch the event (unlike other elements)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0:
                    self.selected = False
                    should_redraw = True


########## Switch ##########
#
#   +--------------------------------+
#   | Label                        O |
#   +--------------------------------+


cdef class Switch(UI_element):
    cdef public FitBox field,button
    cdef bint selected
    cdef int on_val,off_val
    cdef Synced_Value sync_val
    cdef RGBA text_color, button_color_on, button_color_off, button_shadow_color, button_selected_color

    def __cinit__(self,bytes attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(0,switch_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.button = FitBox(Vec2(-switch_button_size-x_spacer,0),Vec2(switch_button_size-x_spacer,switch_button_size-x_spacer))
        self.selected = False
        # rendering variables
        self.text_color = RGBA(*color_text_default)
        self.button_color_on = RGBA(*color_on)
        self.button_color_off = RGBA(*color_default)
        self.button_shadow_color = RGBA(*color_shadow)
        self.button_selected_color = RGBA(*color_selected)


    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.button.compute(self.field)

        # read only rendering rules
        if self._read_only or parent_read_only:
            self.text_color = RGBA(*color_text_read_only)
            self.button_color_on = RGBA(*color_on_read_only)
            self.button_color_off = RGBA(*color_default_read_only)
            self.button_shadow_color = RGBA(*color_shadow_read_only)
        else:
            self.text_color = RGBA(*color_text_default)
            self.button_color_on = RGBA(*color_on)
            self.button_color_off = RGBA(*color_default)
            self.button_shadow_color = RGBA(*color_shadow)


        if self.sync_val.value == self.on_val:
            # on state
            utils.draw_points(((self.button.center),),size=(switch_button_size_on+switch_button_shadow)*ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size_on*ui_scale, color=self.button_color_on)
        elif self.selected:
            utils.draw_points(((self.button.center),),size=(switch_button_size_selected+switch_button_shadow)*ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size_selected*ui_scale, color=self.button_selected_color)
        else:
            # off state
            utils.draw_points(((self.button.center),),size=(switch_button_size+switch_button_shadow)*ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size*ui_scale, color=self.button_color_off)


        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        glfont.draw_limited_text(x_spacer,0,self.label,self.field.size.x-(switch_button_size_on+switch_button_shadow))

        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if visible and self.button.mouse_over(new_input.m):
                    if b[1] == 1:
                        #new_input.buttons.remove(b)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.on_val):
                    #new_input.buttons.remove(b)
                    self.sync_val.value = self.off_val
                    self.selected = False
                    should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.off_val):
                    #new_input.buttons.remove(b)
                    self.sync_val.value = self.on_val
                    self.selected = False
                    should_redraw = True




########## Selector ##########
#
#   +--------------------------------+
#   |       +----------------------+ |
#   | Label | Selection            | |
#   |       +----------------------+ |
#   +--------------------------------+


cdef class Selector(UI_element):
    cdef public FitBox field
    cdef FitBox select_field
    cdef object selection, selection_labels
    cdef Synced_Value sync_val
    cdef int selection_idx
    cdef bint selected
    cdef RGBA text_color, triangle_color

    def __cinit__(self,bytes attribute_name, object attribute_context = None, selection = [], labels=None, label=None, setter=None, getter=None):
        self.uid = id(self)
        self.label = label or attribute_name

        self.selection = list(selection)
        self.selection_labels = labels or [str(s) for s in selection]

        self.text_color = RGBA(*color_text_default)
        self.triangle_color = RGBA(*selector_triangle_color_default)

        for s in self.selection_labels:
            if not isinstance(s,str):
                raise Exception('Labels need to be strings not "%s"'%s)

        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter,self._on_change)

        self.outline = FitBox(Vec2(0,0),Vec2(0,selector_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.select_field = FitBox(Vec2(x_spacer,0),Vec2(0,0))

    def __init__(self,bytes attribute_name, object attribute_context = None, selection = [], labels=None, label=None, setter=None, getter=None):
        pass

    cpdef sync(self):
        self.sync_val.sync()

    def _on_change(self,new_value):
        try:
            self.selection_idx = self.selection.index(new_value)
        except ValueError:
            #we could throw and error here or ignore
            #but for now we just add the new object to the selection
            self.selection.append(new_value)
            self.selection_labels.append(str(new_value))
            self.selection_idx = len(self.selection_labels)-1


    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):

        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.select_field.compute(self.field)

        # read only rendering rules
        if self._read_only or parent_read_only:
            self.text_color = RGBA(*color_text_read_only)
            self.triangle_color = RGBA(*selector_triangle_color_read_only)
        else:
            self.text_color = RGBA(*color_text_default)
            self.triangle_color = RGBA(*selector_triangle_color_default)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        cdef float label_text_space = glfont.draw_text(0,0,self.label)
        glfont.pop_state()
        gl.glPopMatrix()

        self.select_field.org.x += label_text_space
        self.select_field.size.x  = max(0.0,self.select_field.size.x-label_text_space)
        #self.select_field.sketch()
        line(self.select_field.org+Vec2(0,self.select_field.size.y),self.select_field.org+self.select_field.size,color=self.triangle_color)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.select_field.org.x),int(self.select_field.org.y),0)

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        if self.selected:
            for y in range(len(self.selection)):
                glfont.draw_limited_text(x_spacer,y*line_height*ui_scale,self.selection_labels[y],self.select_field.size.x-x_spacer)
        else:
            glfont.draw_limited_text(x_spacer,0,self.selection_labels[self.selection_idx],self.select_field.size.x-x_spacer-self.select_field.size.y)
            if len(self.selection) > 1:
                triangle_h(self.select_field.size-Vec2(self.select_field.size.y,self.select_field.size.y),
                        Vec2(self.select_field.size.y,self.select_field.size.y),
                        self.triangle_color)
        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if visible and self.select_field.mouse_over(new_input.m):
                    #new_input.buttons.remove(b)
                    if b[1] == 0:
                        should_redraw = True
                        if not self.selected:
                            self.init_selection()
                        else:
                            self.finish_selection(mouse_y = new_input.m.y-self.select_field.org.y)

    cdef init_selection(self):
        self.selected = True
        #blow up the menu to fit the open selector field
        cdef h = line_height * len(self.selection_labels)
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y #double neg
        self.outline.design_size.y = h


    cdef finish_selection(self,float mouse_y):
        self.selection_idx = int(mouse_y/(self.select_field.size.y/float(len(self.selection))) )
        #just for sanity
        self.selection_idx = int(clamp(self.selection_idx,0,len(self.selection)-1))

        self.sync_val.value = self.selection[self.selection_idx]

        #make the outline small again
        cdef h = line_height
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y #double neg
        self.outline.design_size.y = h

        #we need to bootstrap the computation of the item height.
        #This is ok because we know the size will not be influcend by partent context.
        #self.outline.size.y = h*ui_scale

        self.selected = False

########## TextInput ##########
#
#   +--------------------------------+
#   | Label  Input text              |
#   +--------------------------------+

cdef class TextInput(UI_element):
    '''
    Text input field.
    '''
    cdef FitBox field, textfield
    cdef bint selected,highlight
    cdef Synced_Value sync_val
    cdef bytes preview
    cdef int caret,start_char_idx,end_char_idx,start_highlight_idx
    cdef RGBA text_color, text_input_highlight_color, text_input_line_highlight_color

    def __cinit__(self,bytes attribute_name, object attribute_context = None,label = None,setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.outline = FitBox(Vec2(0,0),Vec2(0,text_input_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.textfield = FitBox(Vec2(x_spacer,0),Vec2(0,0))
        self.selected = False
        self.highlight = False
        self.preview = str(self.sync_val.value)
        self.caret = len(self.preview)
        self.start_char_idx = 0
        self.end_char_idx = self.caret
        self.start_highlight_idx = 0
        self.text_color = RGBA(*color_text_default)
        self.text_input_highlight_color = RGBA(*text_input_highlight_color)
        self.text_input_line_highlight_color = RGBA(*text_input_line_highlight_color)


    def __init__(self,bytes attribute_name, object attribute_context = None,label = None,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):

        # read only rendering rules
        if self._read_only or parent_read_only:
            self.text_color = RGBA(*color_text_read_only)
        else:
            self.text_color = RGBA(*color_text_default)

        #update appearance:
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.textfield.compute(self.field)

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        dx = glfont.draw_text(x_spacer,0,self.label)
        gl.glPopMatrix()

        self.textfield.org.x += dx
        self.textfield.size.x -=dx

        self.draw_text_field()
        glfont.pop_state()
        # self.draw_text_selection()


    cpdef pre_handle_input(self,Input new_input):
        global should_redraw
        while new_input.keys:
            k = new_input.keys.pop(0)
            if k[0] == 257 and k[2]==0: #Enter and key up:
                self.finish_input()
                return
            if  k[0] == 256 and k[2]==0: #ESC and key up:
                self.abort_input()
                return

            elif k[0] == 259 and k[2] !=1: #Delete and key up:
                if self.caret > 0 and self.highlight is False:
                    self.preview = self.preview[:self.caret-1] + self.preview[self.caret:]
                    self.caret -=1
                if self.highlight:
                    self.preview = self.preview[:min(self.start_highlight_idx,self.caret)] + self.preview[max(self.start_highlight_idx,self.caret):]
                    self.caret = min(self.start_highlight_idx,self.caret)
                    self.highlight = False

                self.caret = max(0,self.caret)
                should_redraw = True

            elif k[0] == 263 and k[2]==0 and k[3]==0: #key left:
                self.caret -=1
                self.caret = max(0,self.caret)
                self.highlight=False
                should_redraw = True

            elif k[0] == 262 and k[2]==0 and k[3]==0: #key right
                self.caret +=1
                self.caret = min(len(self.preview),self.caret)
                self.highlight=False
                should_redraw = True

            elif  k[0] == 263 and k[2]==0 and k[3]==1: #key left with shift:
                if self.highlight is False:
                    self.start_highlight_idx = max(0,self.caret)
                self.caret -=1
                self.caret = max(0,self.caret)
                self.highlight = True
                should_redraw = True

            elif k[0] == 262 and k[2]==0 and k[3]==1: #key left with shift:
                if self.highlight is False:
                    self.start_highlight_idx = min(len(self.preview),self.caret)
                self.caret +=1
                self.caret = min(len(self.preview),self.caret)
                self.highlight = True
                should_redraw = True


        while new_input.chars:
            c = new_input.chars.pop(0)
            self.preview = self.preview[:self.caret] + c + self.preview[self.caret:]
            self.caret +=1
            self.highlight = False
            should_redraw = True

        for b in new_input.buttons:
            if b[1] == 1:
                if self.textfield.mouse_over(new_input.m):
                    self.finish_input()
                    new_input.buttons.remove(b) #avoid reselection during handle_input
                else:
                    self.finish_input()
                    #new_input.buttons.remove(b) #avoid reselection during handle_input
                    #self.abort_input()


    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        global should_redraw
        if not (self._read_only or parent_read_only) and not self.selected:
            for b in new_input.buttons:
                if b[1] == 1 and visible:
                    if self.textfield.mouse_over(new_input.m):
                        #new_input.buttons.remove(b)
                        self.selected = True
                        self.highlight = False
                        self.preview = self.sync_val.value
                        should_redraw = True


        if self.selected:
            new_input.active_ui_elements.append(self)



    cdef finish_input(self):
        global should_redraw
        self.selected = False
        self.caret = len(self.preview)
        self.sync_val.value = self.preview
        should_redraw = True


    cdef abort_input(self):
        global should_redraw
        self.selected = False
        self.preview = self.sync_val.value
        self.caret = len(self.preview)
        should_redraw = True

    cdef calculate_start_idx(self):
        # clip the preview text appropriately so that it always fits within the textfield
        # make sure there is always one char before or after caret
        cdef float width
        cdef int start_char_idx, caret_x
        width = self.textfield.size.x - 2*x_spacer

        # sanity check - if the preview is shorter than the width, then start_char_idx should be 0
        if glfont.text_bounds(x_spacer,0,self.preview[self.start_char_idx:]) < width:
            self.start_char_idx = 0

        # get the position of the caret
        caret_x = glfont.text_bounds(x_spacer,0,self.preview[self.start_char_idx:self.caret])

        # scroll left:
        # if the caret is == start_char_idx subtract one from start_char_idx until idx = 0
        if self.caret == self.start_char_idx:
            # start_char_idx = len(self.preview)-glfont.get_clip_position(self.preview[::-1],width)
            self.start_char_idx = max(0,self.start_char_idx-1)

        # scroll right:
        # if the caret reaches the right bound
        if caret_x >= width:
            # find the starting idx of the left most (starting) char if >= width of textfield+padding
            # at the current caret position - overflow on the right is handled by draw_limited_text
            start_char_idx = glfont.get_first_char_idx(self.preview[:self.caret],width)
            # adding some preview after the caret by modifying the start_char
            # this may result in more than one extra char after, unless monospaced fonts are used
            self.start_char_idx = min(len(self.preview),start_char_idx)


    cdef draw_text_field(self):
        cdef float x
        cdef bytes highlight_size = <bytes>''

        if self.selected:
            self.calculate_start_idx()
            highlight_text = self.preview[self.start_char_idx:self.start_highlight_idx]

            gl.glPushMatrix()
            #then transform locally and render the UI element
            gl.glTranslatef(int(self.textfield.org.x),int(self.textfield.org.y),0)
            line(Vec2(0,self.textfield.size.y), self.textfield.size,self.text_input_line_highlight_color)

            glfont.draw_limited_text(x_spacer,0,self.preview[self.start_char_idx:],self.textfield.size.x-x_spacer)

            x = glfont.text_bounds(0,0,self.preview[self.start_char_idx:self.caret])+x_spacer
            # draw highlighted text if any
            if self.highlight:
               rect_corners(Vec2(x,0),Vec2(min(self.textfield.size.x-x_spacer,
                    glfont.text_bounds(0,0,highlight_text)+x_spacer),self.textfield.size.y),
                    self.text_input_highlight_color)

            # draw the caret
            gl.glColor4f(1,1,1,.5)
            gl.glLineWidth(1)
            gl.glBegin(gl.GL_LINES)
            gl.glVertex3f(x,0,0)
            gl.glVertex3f(x,self.textfield.size.y,0)
            gl.glEnd()
            gl.glPopMatrix()
        else:
            gl.glPushMatrix()
            #then transform locally and render the UI element
            #self.textfield.sketch()
            gl.glTranslatef(int(self.textfield.org.x),int(self.textfield.org.y),0)
            if len(self.preview) > 0:
                glfont.draw_limited_text(x_spacer,0,self.sync_val.value,self.textfield.size.x-x_spacer)
            gl.glPopMatrix()


########## Button ##########
#
#   +--------------------------------+
#   | +----------------------------+ |
#   | | Label                      | |
#   | +----------------------------+ |
#   +--------------------------------+



cdef class Button(UI_element):
    cdef FitBox button
    cdef bint selected
    cdef object function
    cdef RGBA text_color

    def __cinit__(self,label, setter):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(Vec2(0,0),Vec2(0,button_outline_size_y)) # we only fix the height
        self.button = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.selected = False
        self.function = setter
        self.text_color = RGBA(*color_text_default)

    def __init__(self,label, setter):
        pass


    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        cdef tuple text_color
        # read only rendering rules
        if self._read_only or parent_read_only:
            self.text_color = RGBA(*color_text_read_only)
        else:
            self.text_color = RGBA(*color_text_default)

        #update appearance:
        self.outline.compute(parent)
        self.button.compute(self.outline)

        # self.outline.sketch()
        if self.selected:
            pass
        else:
            self.button.sketch()

        gl.glPushMatrix()
        glfont.push_state()
        gl.glTranslatef(int(self.button.org.x),int(self.button.org.y),0)
        glfont.set_color_float(self.text_color[:])
        glfont.draw_limited_text(x_spacer,0,self.label,self.button.size.x-x_spacer)
        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if  visible and self.button.mouse_over(new_input.m):
                    if b[1] == 1:
                        #new_input.buttons.remove(b)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0:
                    #new_input.buttons.remove(b)
                    self.selected = False
                    should_redraw = True
                    self.function()


cdef class Info_Text(UI_element):
    cdef bytes _text
    cdef int max_height
    cdef FitBox text_area


    def __cinit__(self, bytes text):
        self._text = bytes(text)
        self.max_height = 200
        self.outline = FitBox(Vec2(0,0),Vec2(0,0))
        self.text_area = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))

    def __init__(self, bytes text):
        pass

    property text:
        def __get__(self):
            return self._text

        def __set__(self,bytes new_text):
            global should_redraw
            if self._text != new_text:
                should_redraw = True
                self._text = new_text

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.text_area.compute(self.outline)
        glfont.push_state()
        glfont.set_color_float(color_text_info)
        left_word, height = glfont.draw_breaking_text(self.text_area.org.x, self.text_area.org.y, self._text, self.text_area.size.x,self.max_height )
        glfont.pop_state()
        self.text_area.design_size.y  = (height-self.text_area.org.y)/ui_scale
        self.outline.design_size.y = self.text_area.design_size.y+outline_padding*2
        self.outline.compute(parent)

    cpdef precompute(self,FitBox parent):
        self.outline.compute(parent)
        self.text_area.compute(self.outline)
        left_word, height = glfont.compute_breaking_text(self.text_area.org.x, self.text_area.org.y, self._text, self.text_area.size.x,self.max_height )
        self.text_area.design_size.y  = (height-self.text_area.org.y)/ui_scale
        self.outline.design_size.y = self.text_area.design_size.y+outline_padding*2
        self.outline.compute(parent)



########## Thumb ##########


cdef class Thumb(UI_element):
    '''
    Not a classical UI element. Use button instead.
    Thumb is a circular type of switch/button
    It can also display status info via a overlay
    '''
    cdef public FitBox button
    cdef bint selected,hotkeyed
    cdef int on_val,off_val
    cdef Synced_Value sync_val
    cdef public RGBA on_color,off_color
    cdef bytes _status_text
    cdef object hotkey

    def __cinit__(self,bytes attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None, hotkey = None,  on_color=thumb_color_on):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(thumb_outline_size,thumb_outline_size))
        self.button = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.selected = False
        self.on_color = RGBA(*on_color)
        self.off_color = RGBA(*thumb_color_off)
        self.hotkey = hotkey
        self._status_text = bytes('')

    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None, hotkey = None, on_color=thumb_color_on):
        pass


    property status_text:
        def __get__(self):
            return self._status_text
        def __set__(self,bytes new_status_text):
            if self._status_text != new_status_text:
                global should_redraw
                should_redraw = True
                self._status_text = new_status_text



    cpdef sync(self):
        self.sync_val.sync()


    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.button.compute(self.outline)
        if self.sync_val.value == self.on_val:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=RGBA(*thumb_color_shadow),sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_on, color=self.on_color,sharpness=thumb_button_sharpness)
        elif self.selected:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=RGBA(*thumb_color_shadow),sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_selected, color=self.on_color,sharpness=thumb_button_sharpness)
        else:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=RGBA(*thumb_color_shadow),sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_off, color=self.off_color,sharpness=thumb_button_sharpness)

        if self.hotkeyed:
            self.hotkeyed = False
            self.selected = False
            global should_redraw
            should_redraw = True

        glfont.push_state()
        glfont.set_size(max(1,int(min(self.button.size))-thumb_font_padding))
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_CENTER)
        glfont.set_blur(1.)
        glfont.set_font('roboto')
        glfont.draw_text(self.button.center[0],self.button.center[1],self.label[0])
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_LEFT)
        glfont.set_size( max(1, int( (min(self.button.size) )-thumb_font_padding )/2.) )
        glfont.set_color_float((0,0,0,1))
        glfont.set_blur(10.5)
        glfont.draw_text(self.button.center[0]+self.button.size.x/2.,self.button.center[1],self._status_text)
        glfont.set_color_float(self.on_color[:])
        glfont.set_blur(.1)
        glfont.draw_text(self.button.center[0]+self.button.size.x/2.,self.button.center[1],self._status_text)
        glfont.pop_state()
        glfont.set_font('opensans')



    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        cdef bytes c
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if visible and self.button.mouse_over(new_input.m):
                    if b[1] == 1:
                        #new_input.buttons.remove(b)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.on_val):
                    #new_input.buttons.remove(b)
                    self.sync_val.value = self.off_val
                    self.selected = False
                    should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.off_val):
                    #new_input.buttons.remove(b)
                    self.sync_val.value = self.on_val
                    self.selected = False
                    should_redraw = True

            if self.hotkey is not None:
                for c in new_input.chars:
                    if c == self.hotkey:
                        if self.sync_val.value == self.on_val:
                            self.sync_val.value = self.off_val
                            self.selected = True
                            should_redraw = True
                            self.hotkeyed = True

                        elif self.sync_val.value == self.off_val:
                                self.sync_val.value = self.on_val
                                self.selected = True
                                should_redraw = True
                                self.hotkeyed = True

                        break
                for k in new_input.keys:
                    if k[2] == 1:  #keydown
                        if k[0] == self.hotkey:
                            if self.sync_val.value == self.on_val:
                                self.sync_val.value = self.off_val
                                self.selected = True
                                should_redraw = True
                                self.hotkeyed = True

                            elif self.sync_val.value == self.off_val:
                                    self.sync_val.value = self.on_val
                                    self.selected = True
                                    should_redraw = True
                                    self.hotkeyed = True

                            break


cdef class Hot_Key(UI_element):
    '''
    Just a hotkey. Not displayed.
    '''
    cdef int on_val,off_val
    cdef Synced_Value sync_val
    cdef public RGBA on_color,off_color
    cdef object hotkey

    def __cinit__(self,bytes attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None, hotkey = None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.hotkey = hotkey
        self.outline = FitBox(Vec2(0,0),Vec2(0,0)) # we dont use it but we need to have it.


    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None, hotkey = None):
        pass


    cpdef sync(self):
        self.sync_val.sync()


    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        cdef bytes c
        if not (self._read_only or parent_read_only):
            if self.hotkey is not None:
                for c in new_input.chars:
                    if c == self.hotkey:
                        if self.sync_val.value == self.on_val:
                            self.sync_val.value = self.off_val
                        elif self.sync_val.value == self.off_val:
                                self.sync_val.value = self.on_val
                        break
                for k in new_input.keys:
                    if k[2] == 1:  #keydown
                        if k[0] == self.hotkey:
                            if self.sync_val.value == self.on_val:
                                self.sync_val.value = self.off_val
                            elif self.sync_val.value == self.off_val:
                                    self.sync_val.value = self.on_val
                            break






