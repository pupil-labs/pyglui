########## UI_element ##########
# Base class
# see 'design_params.pxi' for design parameters
cdef class UI_element:
    '''
    The base class for all UI elements.
    '''
    cdef float _order
    cdef readonly object uid
    cdef public FitBox outline
    cdef basestring _label
    cdef bint _read_only


    cpdef sync(self):
        global should_redraw
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        pass

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
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

    property width:
        def __get__(self):
            return self.outline.size.x

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

    property label:
        def __get__(self):
            return self._label
        def __set__(self,basestring val):
            if self._label != val:
                self._label = val
                global should_redraw
                should_redraw = True

    property order:
        def __get__(self):
            return self._order
        def __set__(self,float order):
            if self._order != order:
                self._order = order
                global should_redraw
                should_redraw = True


########## Slider ##########
#    +--------------------------------+
#    | Label  Input Text              |
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
    cdef Slider_Text_Input label_field

    def __cinit__(self,str attribute_name, object attribute_context = None, label = None, min = 0, max = 100, step = 0,setter= None,getter= None):

        self.label_field = Slider_Text_Input(attribute_name, attribute_context,
                                             label=label or attribute_name,
                                             setter=setter, getter=getter)
        self.label_field.validator = self.validate
        self.uid = id(self)
        self.sync_val = self.label_field.sync_val
        self.step = abs(step)
        self.minimum = min
        if self.step:
            self.maximum = (((max-min+.0000001)//self.step))*self.step+min # + 0.0000001 becasue of floating point rounding issues.
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
        self.display_format = '%0.2f'

    def __init__(self,str attribute_name, object attribute_context = None,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
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
        self.slider_pos.y = slider_handle_org_y * ui_scale
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
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)


        rect_corners(Vec2(self.slider_pos.x, self.slider_pos.y - 1. * ui_scale),
                     Vec2(self.field.size.x, self.slider_pos.y +  1. * ui_scale),
                     self.line_default_color)
        rect_corners(Vec2(0., self.slider_pos.y - 1. * ui_scale),
                     Vec2(self.slider_pos.x, self.slider_pos.y +  1. * ui_scale),
                     self.line_highlight_color)

        cdef float step_pixel_size,x
        if self.steps>1:
            step_pixel_size = lmap(self.minimum+self.step,self.minimum,self.maximum,0,self.field.size.x)
            if step_pixel_size >= slider_button_size*ui_scale:
                step_marks = [(x*step_pixel_size,self.slider_pos.y) for x in range(self.steps+1)]
                utils.draw_points(step_marks,size=slider_step_mark_size*ui_scale, color=self.step_color)

        if self.selected:
            utils.draw_points((self.slider_pos,),size=(slider_button_size_selected+slider_button_shadow)*ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points((self.slider_pos,),size=slider_button_size_selected*ui_scale, color=self.button_selected_color)
        else:
            utils.draw_points((self.slider_pos,),size=(slider_button_size+slider_button_shadow)+ui_scale, color=self.button_shadow_color,sharpness=shadow_sharpness)
            utils.draw_points((self.slider_pos,),size=slider_button_size*ui_scale, color=self.button_color)

        gl.glPopMatrix()
        self.label_field.draw(self.outline, nested=True, parent_read_only=(self._read_only or parent_read_only))



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

            for b in new_input.buttons[:]:#list copy for remove to work
                if b[1] == 1 and visible:
                    if mouse_over_center(Vec2(self.field.org.x + self.field.size.x / 2.,
                                              self.slider_pos.y + self.field.org.y),
                                         self.field.size.x,self.field.size.y/2.,new_input.m):
                        new_input.buttons.remove(b) # the slider should catch the event (unlike other elements)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0:
                    self.selected = False
                    should_redraw = True

            self.label_field.handle_input(new_input, visible, False)

    cpdef validate(self, val):
        return step(clamp(val, self.minimum, self.maximum), self.minimum, self.maximum, self.step)

    @property
    def display_format(self):
        return self.label_field.display_format

    @display_format.setter
    def display_format(self, val):
        self.label_field.display_format = val


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

    def __cinit__(self,str attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None):
        self.uid = id(self)
        self._label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(0,switch_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.button = FitBox(Vec2(-switch_button_size-x_spacer,0),Vec2(switch_button_size,switch_button_size))
        self.selected = False
        # rendering variables
        self.text_color = RGBA(*color_text_default)
        self.button_color_on = RGBA(*color_on)
        self.button_color_off = RGBA(*color_default)
        self.button_shadow_color = RGBA(*color_shadow)
        self.button_selected_color = RGBA(*color_selected)


    def __init__(self,str attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None):
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
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        glfont.draw_limited_text(x_spacer,0,self._label,self.field.size.x-(switch_button_size_on+switch_button_shadow))

        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if visible and self.button.mouse_over(new_input.m):
                    if b[1] == 1:
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.on_val):
                    self.sync_val.value = self.off_val
                    self.selected = False
                    should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.off_val):
                    self.sync_val.value = self.on_val
                    self.selected = False
                    should_redraw = True




########## Selector ##########
#
#   +--------------------------------+
#   |       +----------------------+ |
#   | Label | Selection          v | |
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
    cdef object selection_getter

    def __cinit__(self,str attribute_name, object attribute_context = None, selection = [], labels=None, label=None, setter=None, getter=None, selection_getter = None):
        # NOTE: implementing a custom selection_getter can lead to race-conditions. Make
        # sure that the current set value is always contained in the returned selections
        # from selection_getter.

        self.uid = id(self)
        self._label = label or attribute_name

        self.text_color = RGBA(*color_text_default)
        self.triangle_color = RGBA(*selector_triangle_color_default)

        def default_selection_getter():
            def to_str(obj):
                if isinstance(obj,basestring):
                    return obj
                else:
                    return str(obj)

            return selection,(labels or [to_str(s) for s in selection])

        self.selection_getter = selection_getter or default_selection_getter

        self.selection,self.selection_labels = self.selection_getter()

        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter,self._on_change)

        self.outline = FitBox(Vec2(0,0),Vec2(0,selector_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.select_field = FitBox(Vec2(x_spacer,0),Vec2(0,0))

    def __init__(self,*args,**kwargs):
        pass

    cpdef sync(self):
        self.sync_val.sync()

    def _on_change(self,new_value):
        self.selection,self.selection_labels = self.selection_getter()
        try:
            self.selection_idx = list(self.selection).index(new_value)
        except ValueError:
            ##we could throw and error here or ignore
            ##but for now we just add the new object to the selection
            #self.selection.append(new_value)
            #self.selection_labels.append(str(new_value))
            raise ValueError("Synced value '%s' is not part of selection."%str(new_value))


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
            if self.selected:
                self.triangle_color = RGBA(*color_on)
            else:
                self.triangle_color = RGBA(*selector_triangle_color_default)

        gl.glPushMatrix()
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)
        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        cdef float label_text_space = glfont.draw_text(x_spacer,0,self._label)
        glfont.pop_state()
        gl.glPopMatrix()

        self.select_field.org.x += label_text_space + x_spacer * ui_scale
        self.select_field.size.x  = max(0.0,self.select_field.size.x-label_text_space - x_spacer * ui_scale)
        rect_outline(self.select_field.org, self.select_field.size, 2.*ui_scale, self.triangle_color)
        #self.select_field.sketch()
        # line(self.select_field.org+Vec2(0,self.select_field.size.y),self.select_field.org+self.select_field.size,color=self.triangle_color)


        gl.glPushMatrix()
        gl.glTranslatef(self.select_field.org.x,self.select_field.org.y,0)

        glfont.push_state()
        glfont.set_color_float(self.text_color[:])

        if self.selected:
            for y in range(len(self.selection)):
                glfont.draw_limited_text(x_spacer,y*line_height*ui_scale,self.selection_labels[y],self.select_field.size.x-x_spacer)
        else:
            glfont.draw_limited_text(x_spacer,0,self.selection_labels[self.selection_idx],self.select_field.size.x-x_spacer-self.select_field.size.y)
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
                    if b[1] == 0:
                        should_redraw = True
                        if not self.selected:
                            self.init_selection()
                        else:
                            self.finish_selection(mouse_y = new_input.m.y-self.select_field.org.y)

    cdef init_selection(self):
        self.selected = True
        self.selection,self.selection_labels = self.selection_getter()
        #blow up the menu to fit the open selector field
        cdef h = line_height * len(self.selection_labels)
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y
         #double neg
        self.outline.design_size.y = h


    cdef finish_selection(self,float mouse_y):
        clicked_idx = int(mouse_y/(self.select_field.size.y/float(len(self.selection))) )
        #just for sanity
        clicked_idx = int(clamp(clicked_idx,0,len(self.selection)-1))

        self.sync_val.value = self.selection[clicked_idx]

        # Sync value. Will update self.selection_idx if the value actually changed.
        self.sync_val.sync()

        #make the outline small again
        cdef h = line_height
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y #double neg
        self.outline.design_size.y = h

        self.selected = False

########## TextInput ##########
#
#   +--------------------------------+
#   | Label  Input text              |
#   +--------------------------------+

cdef class Text_Input(UI_element):
    '''
    Text input field.
    '''
    cdef FitBox field, textfield
    cdef bint selected,highlight, catch_input
    cdef readonly Synced_Value sync_val
    cdef unicode preview
    cdef int caret,start_char_idx,end_char_idx,start_highlight_idx
    cdef RGBA text_color, text_input_highlight_color, text_input_line_highlight_color
    cdef object data_type
    cdef double t_long_press, t_double_click

    def __cinit__(self,str attribute_name, object attribute_context = None,label = None,setter= None,getter= None):
        self.uid = id(self)
        self._label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.outline = FitBox(Vec2(0,0),Vec2(0,text_input_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.textfield = FitBox(Vec2(x_spacer,0),Vec2(0,0))
        self.selected = False
        self.highlight = False
        self.preview = u'' #only used when self.selected==True
        self.caret = 0 #only used when self.selected==True
        self.start_char_idx = 0
        self.end_char_idx = self.caret
        self.start_highlight_idx = 0
        self.text_color = RGBA(*color_text_default)
        self.text_input_highlight_color = RGBA(*text_input_highlight_color)
        self.text_input_line_highlight_color = RGBA(*text_input_line_highlight_color)
        self.data_type = type(self.sync_val.value)
        self.catch_input = True
        self.t_long_press = 0.0 #timer used for long press
        self.t_double_click = 0.0 #timer used for t_double_click

    def __init__(self,str attribute_name, object attribute_context = None,label = None,setter= None,getter= None):
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
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)
        dx = glfont.draw_text(x_spacer,0,self._label)
        gl.glPopMatrix()

        self.textfield.org.x += dx + x_spacer * ui_scale
        self.textfield.size.x -= dx + x_spacer * ui_scale

        self.draw_text_field()
        glfont.pop_state()
        # self.draw_text_selection()


    cpdef pre_handle_input(self,Input new_input):
        global should_redraw
        while new_input.keys:
            key,scancode,action,mods = new_input.keys.pop(0)
            # See file glfw.py
            # for key,scancode,action,mods definitions
            if key == 257 and action == 0: #Enter and key press
                self.finish_input()
                return
            if  key == 256 and action == 0: #ESC and key press
                self.abort_input()
                return

            # cut: mod+x (88), copy: mod+c (67)
            elif key in (67, 88) and mods & UI_MOD_KEY and action != 0:
                if self.highlight:
                    min_idx = min(self.start_highlight_idx, self.caret)
                    max_idx = max(self.start_highlight_idx, self.caret)
                    new_input.cb = self.preview[min_idx:max_idx]
                    if key == 88:
                        self.preview = self.preview[:min_idx] + self.preview[max_idx:]
                        self.caret = min_idx
                        self.highlight = False
                        should_redraw = True
            # paste: mod+v
            elif key == 86 and mods & UI_MOD_KEY and action != 0 and new_input.cb:
                if self.highlight:
                    min_idx = min(self.start_highlight_idx, self.caret)
                    max_idx = max(self.start_highlight_idx, self.caret)
                else:
                    min_idx = max_idx = self.caret

                self.preview = self.preview[:min_idx] + new_input.cb + self.preview[max_idx:]
                self.caret = min_idx + len(new_input.cb)
                self.highlight = False
                should_redraw = True

            elif key == 259 and action != 1: # Backspace and key not released (key repeat)
                if self.caret > 0 and self.highlight is False:
                    self.preview = self.preview[:self.caret-1] + self.preview[self.caret:]
                    self.caret -=1
                if self.highlight:
                    min_idx = min(self.start_highlight_idx, self.caret)
                    max_idx = max(self.start_highlight_idx, self.caret)
                    self.preview = self.preview[:min_idx] + self.preview[max_idx:]
                    self.caret = min_idx
                    self.highlight = False

                self.caret = max(0, self.caret)
                should_redraw = True

            elif key == 261 and action != 1: # Delete and key not released (key repeat)
                if self.caret < len(self.preview) and self.highlight is False:
                    self.preview = self.preview[:self.caret] + self.preview[self.caret+1:]
                if self.highlight:
                    self.preview = self.preview[:min(self.start_highlight_idx,self.caret)] + self.preview[max(self.start_highlight_idx,self.caret):]
                    self.caret = min(self.start_highlight_idx,self.caret)
                    self.highlight = False

                self.caret = min(len(self.preview), self.caret)
                should_redraw = True

            elif key == 263 and action != 1 and mods == 0: #key left and key not released without mod keys
                self.caret -=1
                self.caret = max(0,self.caret)
                self.highlight=False
                should_redraw = True

            elif key == 262 and action != 1 and mods == 0: #key right and key not released without mod keys
                self.caret +=1
                self.caret = min(len(self.preview),self.caret)
                self.highlight=False
                should_redraw = True

            elif  key == 263 and action != 1 and mods == 1: #key left and key not released with shift mod
                if self.highlight is False:
                    self.start_highlight_idx = max(0,self.caret)
                self.caret -=1
                self.caret = max(0,self.caret)
                self.highlight = True
                should_redraw = True

            elif key == 262 and action != 1 and mods == 1: #key right and key not released with shift mod
                if self.highlight is False:
                    self.start_highlight_idx = min(len(self.preview),self.caret)
                self.caret +=1
                self.caret = min(len(self.preview),self.caret)
                self.highlight = True
                should_redraw = True

            elif key == 65 and action == 0 and mods == UI_MOD_KEY: # select all
                # key a and action key press and mods are either command/super for MacOS or control for Windows
                if len(self.preview) > 0 and self.highlight is False:
                    self.start_highlight_idx = 0
                    self.caret = len(self.preview)
                    self.highlight = True
                should_redraw = True
            elif key in (268, 269) and action == 1:  # home on release
                if mods != 1:
                    self.highlight = False
                elif self.highlight is False:
                    self.start_highlight_idx = min(len(self.preview),self.caret)
                    self.highlight = True

                if key == 269:
                    self.caret = len(self.preview)
                else:
                    self.caret = 0
                should_redraw = True

        while new_input.chars:
            c = new_input.chars.pop(0)
            if self.highlight:
                # new char overwrites all highlighted chars
                self.preview = self.preview[:min(self.start_highlight_idx,self.caret)] + c + self.preview[max(self.start_highlight_idx,self.caret):]
                self.caret = min(self.start_highlight_idx+1,self.caret+1)
                self.caret = max(1,self.caret)
                self.highlight = False
            else:
                self.preview = self.preview[:self.caret] + c + self.preview[self.caret:]
                self.caret +=1

            should_redraw = True

        for b in new_input.buttons:
            if b[1] == 0 and not self.textfield.mouse_over(new_input.m):
                self.finish_input()

    cdef to_unicode(self,obj):
        if type(obj) is unicode:
            return obj
        elif type(obj) is bytes:
            return obj.decode('utf-8')
        else:
            return unicode(obj)

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        global should_redraw
        cdef double d_double_click = 0.5  # delay used for double click
        cdef double d_long_press = 1.0  # delay used for long press
        cdef double now = time()

        if not (self._read_only or parent_read_only):
            for b in new_input.buttons[:]:
                if self.textfield.mouse_over(new_input.m) and visible:
                    if b[1] == 1:
                        self.selected = True
                        self.highlight = False
                        self.preview = self.to_unicode(self.sync_val.value)
                        self.caret = len(self.preview)

                        mouse_x_in_text_box = new_input.m.x-x_spacer-self.textfield.org.x

                        # get caret position closest to current mouse.x
                        self.calculate_start_idx() # caret position needs to be updated relative to text offset in the case of long string of text
                        caret_positions = glfont.char_cumulative_width(x_spacer,0,self.preview[self.start_char_idx:self.caret])
                        mouse_to_caret = [abs(i-mouse_x_in_text_box) for i in caret_positions]
                        min_distance = min(mouse_to_caret)
                        self.caret = mouse_to_caret.index(min_distance)

                        should_redraw = True
                        self.t_long_press = now

                        if now - self.t_double_click > d_double_click:
                            self.highlight = False
                            self.t_double_click = now
                        elif len(self.preview) > 0:
                            self.highlight = True
                            self.start_highlight_idx = 0
                            self.caret = len(self.preview)
                            self.t_double_click = 0.

                    elif b[1] == 0:  # button release
                        if now - self.t_long_press > d_long_press:
                            # long press highlights all text
                            # similar to the behavior on a mobile device
                            self.highlight = True
                            self.start_highlight_idx = 0
                            self.caret = len(self.preview)

                        should_redraw = True

                    if self.catch_input:
                        # this is required so that we can catch mouse up behavior
                        new_input.buttons.remove(b)

        if self.selected:
            new_input.active_ui_elements.append(self)


    cdef finish_input(self):
        global should_redraw
        should_redraw = True
        self.selected = False
        self.update_input_val()

    cdef update_input_val(self):
        # turn string back into the data_type of the value in case of str always use unicode
        if isinstance(self.sync_val.value, basestring):
            typed_val = self.preview
        else:
            try:
                typed_val = self.data_type(eval(self.preview))
            except:
                #failed to convert. Ignore user input.
                return
        self.sync_val.value = typed_val


    cdef abort_input(self):
        global should_redraw
        should_redraw = True
        self.selected = False

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

        if self.selected:
            self.calculate_start_idx()
            highlight_text = self.preview[self.start_char_idx:self.start_highlight_idx]

            gl.glPushMatrix()
            #then transform locally and render the UI element
            gl.glTranslatef(self.textfield.org.x,self.textfield.org.y,0)
            rect_outline(Vec2(0, 0), self.textfield.size, 2.*ui_scale, self.text_input_line_highlight_color)

            x = glfont.text_bounds(0,0,self.preview[self.start_char_idx:self.caret])+x_spacer
            # draw highlighted text if any
            if self.highlight:
               rect_corners(Vec2(x,0),Vec2(min(self.textfield.size.x-x_spacer,
                    glfont.text_bounds(0,0,highlight_text)+x_spacer),self.textfield.size.y),
                    self.text_input_highlight_color)

            glfont.draw_limited_text(x_spacer,0,self.preview[self.start_char_idx:],self.textfield.size.x-x_spacer)

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
            gl.glTranslatef(self.textfield.org.x,self.textfield.org.y,0)
            rect_outline(Vec2(0, 0), self.textfield.size, 2.*ui_scale, RGBA(*color_line_default))
            glfont.draw_limited_text(x_spacer,0,self.to_unicode(self.sync_val.value),self.textfield.size.x-x_spacer)
            gl.glPopMatrix()


cdef class Slider_Text_Input(Text_Input):

    cdef public object validator
    cdef public basestring display_format

    def __cinit__(self, *args, **kwargs):
        self.validator = lambda x: x
        self.display_format = '%0.2f'

    cdef update_input_val(self):
        # turn string back into the data_type of the value in case of str always use unicode
        if isinstance(self.sync_val.value, basestring):
            typed_val = self.preview
        else:
            try:
                typed_val = self.data_type(self.validator(eval(self.preview)))
            except:
                #failed to convert. Ignore user input.
                return
        self.sync_val.value = typed_val

    cdef to_unicode(self,obj):
        if type(obj) is unicode:
            return obj
        elif type(obj) is bytes:
            return obj.decode('utf-8')
        elif isinstance(obj, float):
            return self.display_format % obj
        else:
            return unicode(obj)

########## Button ##########
#
#   +--------------------------------+
#   |                      +-------+ |
#   | Outer_Label          | Label | |
#   |                      +-------+ |
#   +--------------------------------+



cdef class Button(UI_element):
    cdef FitBox field, button
    cdef bint selected
    cdef public object function
    cdef RGBA text_color
    cdef basestring _outer_label

    def __cinit__(self,label, function, outer_label=''):
        self.uid = id(self)
        self._label = label
        self._outer_label = outer_label
        self.outline = FitBox(Vec2(0,0),Vec2(0,button_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(0,0),Vec2(0,0))  # depends on string length
        self.button = FitBox(Vec2(0,0),Vec2(0,0))  # will be computed on demand
        self.selected = False
        self.function = function
        self.text_color = RGBA(*color_text_default)

    def __init__(self, *args, **kwargs):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        cdef tuple text_color
        cdef RGBA bg_color
        # read only rendering rules
        if self._read_only or parent_read_only:
            self.text_color = RGBA(*button_read_only_text_color)
            bg_color = RGBA(*button_read_only_color)
        elif self.selected:
            self.text_color = RGBA(*button_active_text_color)
            bg_color = RGBA(*button_active_color)
        else:
            self.text_color = RGBA(*button_default_text_color)
            bg_color = RGBA(*button_default_color)

        #update appearance:
        self.outline.compute(parent)

        cdef float label_width = 0.
        if self._outer_label:
            label_width = glfont.text_bounds(0., 0., self._label) / ui_scale
            self.field = FitBox(Vec2(outline_padding, outline_padding),
                                Vec2(-label_width-outline_padding-3.*x_spacer, -outline_padding))
            self.button = FitBox(Vec2(-label_width-button_text_padding-button_outline_padding-2.*x_spacer, button_outline_padding),
                                 Vec2(label_width+2.*x_spacer+2*button_text_padding, -button_outline_padding))
            self.field.compute(self.outline)
        else:
            self.button = FitBox(Vec2(button_outline_padding, button_outline_padding),
                                 Vec2(-button_outline_padding, -button_outline_padding))
        self.button.compute(self.outline)

        cdef FitBox shadow = self.button.computed_copy()
        if not self.selected:
            shadow.org -= Vec2(2. * ui_scale, 2. * ui_scale)
            shadow.size += Vec2(4. * ui_scale, 4. * ui_scale)
            utils.draw_rounded_rect(shadow.org, shadow.size,
                                    button_corner_radius * ui_scale,
                                    color=RGBA(*color_shadow), sharpness=shadow_sharpness)

        utils.draw_rounded_rect(self.button.org, self.button.size,
                                button_corner_radius * ui_scale,
                                color=bg_color, sharpness=0.9)

        if self._outer_label:
            gl.glPushMatrix()
            glfont.push_state()
            gl.glTranslatef(self.field.org.x + button_text_padding * ui_scale,
                            self.field.org.y + button_text_padding * ui_scale,0)
            glfont.set_color_float(color_text_default)
            glfont.draw_limited_text(0,0,self._outer_label,self.field.size.x)
            glfont.pop_state()
            gl.glPopMatrix()

        gl.glPushMatrix()
        glfont.push_state()
        gl.glTranslatef(self.button.org.x + button_text_padding * ui_scale,
                        self.button.org.y + button_text_padding * ui_scale,0)
        glfont.set_color_float(self.text_color[:])
        glfont.draw_limited_text(x_spacer*ui_scale,0,self._label,self.button.size.x - 2. *  button_text_padding * ui_scale)
        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons:
                if  visible and self.button.mouse_over(new_input.m):
                    if b[1] == 1:
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0:
                    self.selected = False
                    should_redraw = True
                    self.function()

    @property
    def outer_label(self):
        return self._outer_label

    @outer_label.setter
    def outer_label(self,basestring val):
        if self._outer_label != val:
            self._outer_label = val
            global should_redraw
            should_redraw = True


cdef class Separator(UI_element):
    cdef float separator_height

    def __cinit__(self):
        self.outline = FitBox(Vec2(0,0),Vec2(0,0))

    def __init__(self):
        pass

    cpdef draw(self, FitBox parent,bint nested=True, bint parent_read_only = False):
        self.outline.compute(parent)

        line(Vec2(self.outline.org.x + outline_padding,
                  self.outline.org.y + outline_padding),
             Vec2(self.outline.org.x - outline_padding + self.outline.size.x,
                  self.outline.org.y + outline_padding),
             RGBA(*menu_line))

        self.outline.design_size.y = 1.5 * ui_scale * outline_padding * 2
        self.outline.compute(parent)

    cpdef precompute(self, FitBox parent):
        self.outline.compute(parent)
        self.outline.design_size.y = 1.5 * ui_scale * outline_padding * 2
        self.outline.compute(parent)

cdef class Info_Text(UI_element):
    cdef basestring _text
    cdef int max_height
    cdef FitBox text_area
    cdef float _text_size
    cdef RGBA _text_color
    cdef bint _centered

    def __cinit__(self, basestring text):
        self._text = text
        self.max_height = 200
        self.outline = FitBox(Vec2(0,0),Vec2(0,0))
        self.text_area = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self._text_size = size_text_info
        self._text_color = RGBA(*color_text_info)
        self._centered = False

    def __init__(self, basestring text):
        pass

    property text:
        def __get__(self):
            return self._text

        def __set__(self,basestring new_text):
            global should_redraw
            if self._text != new_text:
                should_redraw = True
                self._text = new_text

    property text_size:
        def __get__(self):
            return self._text_size

        def __set__(self, float new_text_size):
            global should_redraw
            if self._text_size != new_text_size:
                should_redraw = True
                self._text_size = new_text_size

    property text_color:
        def __get__(self):
            return self._text_color

        def __set__(self, RGBA new_text_color):
            global should_redraw
            if self._text_color != new_text_color:
                should_redraw = True
                self._text_color = new_text_color

    property centered:
        #TODO: Replace this property with full support for setting horizontal and vertical alignment
        def __get__(self):
            return self._centered

        def __set__(self, bint new_value):
            global should_redraw
            if self._centered != new_value:
                should_redraw = True
                self._centered = new_value

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.text_area.compute(self.outline)
        glfont.push_state()
        glfont.set_color_float(self.text_color.as_tuple())
        glfont.set_size(self.text_size*ui_scale)
        if self.centered:
            glfont.set_align(fs.FONS_ALIGN_CENTER | fs.FONS_ALIGN_TOP)
            text_origin = (self.text_area.center[0], self.text_area.org.y)
        else:
            text_origin = (self.text_area.org.x, self.text_area.org.y)
        left_word, height = glfont.draw_breaking_text(text_origin[0], text_origin[1], self._text, self.text_area.size.x,self.max_height )
        glfont.pop_state()
        self.text_area.design_size.y  = (height - self.text_area.org.y) / ui_scale
        self.outline.design_size.y = self.text_area.design_size.y + outline_padding * 2
        self.text_area.compute(self.outline)
        self.outline.compute(parent)

    cpdef precompute(self,FitBox parent):
        self.outline.compute(parent)
        self.text_area.compute(self.outline)
        glfont.push_state()
        glfont.set_size(self.text_size*ui_scale)
        left_word, height = glfont.compute_breaking_text(self.text_area.org.x, self.text_area.org.y, self._text, self.text_area.size.x,self.max_height )
        glfont.pop_state()
        self.text_area.design_size.y  = (height - self.text_area.org.y) / ui_scale
        self.outline.design_size.y = self.text_area.design_size.y + outline_padding * 2
        self.text_area.compute(self.outline)
        self.outline.compute(parent)


cdef class Color_Legend(UI_element):
    cdef basestring _text
    cdef FitBox text_area
    cdef float _text_size
    cdef RGBA _text_color
    cdef RGBA _line_color
    cdef int max_height

    def __cinit__(self, object line_color, basestring text):
        self._text = text
        self.max_height = 200
        self.outline = FitBox(Vec2(0,0),Vec2(0,0))
        self.text_area = FitBox(
            Vec2(outline_padding * 6, outline_padding),
            Vec2(-outline_padding, -outline_padding)
        )
        self._text_size = size_text_info
        self._text_color = RGBA(*color_text_info)
        self._line_color = RGBA(*line_color)

    def __init__(self, object line_color, basestring text):
        pass

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        self.outline.compute(parent)

        line(Vec2(self.outline.org.x + outline_padding,
                  self.outline.org.y + outline_padding),
             Vec2(self.outline.org.x + ui_scale * outline_padding * 4,
                  self.outline.org.y + outline_padding),
             self._line_color)

        self.text_area.compute(self.outline)

        glfont.push_state()
        glfont.set_color_float(self._text_color.as_tuple())
        glfont.set_size(self._text_size * ui_scale)
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_LEFT)
        left_word, height = glfont.draw_breaking_text(
            self.text_area.org.x,
            self.text_area.org.y,
            self._text,
            self.text_area.size.x,
            self.max_height,
        )
        glfont.pop_state()
        self.text_area.design_size.y  = (height - self.text_area.org.y) / ui_scale
        self.outline.design_size.y = self.text_area.design_size.y + outline_padding
        self.text_area.compute(self.outline)
        self.outline.compute(parent)

    cpdef precompute(self, FitBox parent):
        self.outline.compute(parent)
        self.text_area.compute(self.outline)
        glfont.push_state()
        glfont.set_size(self._text_size * ui_scale)
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_LEFT)
        left_word, height = glfont.compute_breaking_text(
            self.text_area.org.x,
            self.text_area.org.y,
            self._text,
            self.text_area.size.x,
            self.max_height
        )
        glfont.pop_state()
        self.text_area.design_size.y  = (height - self.text_area.org.y) / ui_scale
        self.outline.design_size.y = self.text_area.design_size.y + outline_padding
        self.text_area.compute(self.outline)
        self.outline.compute(parent)

########## Thumb ##########


cdef class Thumb(UI_element):
    '''
    Not a classical UI element. Use button instead.
    Thumb is a circular type of switch/button
    It can also display status info via a overlay
    '''
    cdef public FitBox button
    cdef bint selected
    cdef int on_val,off_val
    cdef float offset_x, offset_y, offset_size, label_line_height
    cdef public basestring label_font
    cdef Synced_Value sync_val
    cdef RGBA _on_color, _off_color
    cdef basestring _status_text
    cdef object hotkey, label_getter

    def __cinit__(
        self,
        str attribute_name,
        object attribute_context = None,
        on_val=True,
        off_val=False,
        label=None,
        label_font='roboto',
        label_offset_x=0,
        label_offset_y=0,
        label_offset_size=0,
        label_line_height=1.0,
        setter=None,
        getter=None,
        hotkey = None,
        on_color=thumb_color_on,
        off_color=thumb_color_off,
        label_getter=None
    ):
        self.uid = id(self)
        self._label = label_getter() if label_getter is not None else (label or attribute_name[0])
        self.label_font = label_font
        self.label_getter = label_getter
        self.offset_x = label_offset_x
        self.offset_y = label_offset_y
        self.offset_size = label_offset_size
        self.label_line_height = label_line_height
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(thumb_outline_size,thumb_outline_size))
        self.button = FitBox(Vec2(thumb_outline_pad,thumb_outline_pad),Vec2(-thumb_outline_pad,-thumb_outline_pad))
        self.selected = False
        self._on_color = RGBA(*on_color)
        self._off_color = RGBA(*off_color)
        self.hotkey = hotkey
        self._status_text = ''

    def __init__(self, *args, **kwargs):
        pass

    property status_text:
        def __get__(self):
            return self._status_text
        def __set__(self,basestring new_status_text):
            if self._status_text != new_status_text:
                global should_redraw
                should_redraw = True
                self._status_text = new_status_text

    property on_color:
        def __get__(self):
            return self._on_color
        def __set__(self, RGBA new_color):
            if self._on_color != new_color:
                global should_redraw
                should_redraw = True
                self._on_color = new_color

    property off_color:
        def __get__(self):
            return self._off_color
        def __set__(self, RGBA new_color):
            if self._off_color != new_color:
                global should_redraw
                should_redraw = True
                self._off_color = new_color

    cpdef sync(self):
        if self.label_getter is not None:
            # only redraws if label_getter returns a new value
            self.label = self.label_getter()
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.button.compute(self.outline)
        cdef int stroke_width = int(12 * ui_scale)
        cdef int stroke_width_half = int(stroke_width * 0.5)
        cdef int shadow_stroke_width = int(24 * ui_scale)
        cdef RGBA icon_color

        if self.sync_val.value == self.on_val:
            icon_color = self.on_color
        elif self.selected:
            icon_color = self.on_color
        else:
            icon_color = self.off_color

        #utils.draw_circle(self.button.center,radius=int(min(self.button.size)*.7)+stroke_width_half, stroke_width = shadow_stroke_width, color=RGBA(*thumb_color_shadow),sharpness=thumb_button_shadow_sharpness)
        utils.draw_circle(self.button.center,radius=int(min(self.button.size)*.77), stroke_width = stroke_width, color=RGBA(*thumb_color_shadow),sharpness=thumb_button_shadow_sharpness)
        utils.draw_circle(self.button.center,radius=int(min(self.button.size)*.77), stroke_width = stroke_width, color=icon_color,sharpness=thumb_button_sharpness)

        if self.selected:
            self.selected = False
            global should_redraw
            should_redraw = True

        glfont.push_state()
        glfont.set_font(self.label_font)
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_CENTER)
        glfont.set_size(max(1,int(min(self.button.size)+self.offset_size*ui_scale)-thumb_font_padding*ui_scale))
        glfont.set_color_float((0,0,0,0.5))
        glfont.set_blur(10.5)
        cdef int text_x = self.button.center[0]+int(self.offset_x*ui_scale)
        cdef int text_y = self.button.center[1]+int(self.offset_y*ui_scale)
        glfont.draw_multi_line_text(text_x, text_y, self._label, self.label_line_height)
        glfont.set_blur(0.5)
        glfont.set_color_float(icon_color[:])
        glfont.draw_multi_line_text(text_x, text_y, self._label, self.label_line_height)
        glfont.pop_state()


        # draw status text.
        glfont.push_state()
        glfont.set_font('roboto')
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_LEFT)
        glfont.set_size( max(1, int( (min(self.button.size) )-thumb_font_padding*ui_scale)/2.) )
        glfont.set_color_float((0,0,0,1))
        glfont.set_blur(10.5)
        glfont.draw_multi_line_text(self.button.center[0]+self.button.size.x/2.,self.button.center[1],self._status_text)
        glfont.set_color_float(icon_color[:])
        glfont.set_blur(.1)
        glfont.draw_multi_line_text(self.button.center[0]+self.button.size.x/2.,self.button.center[1],self._status_text)
        glfont.pop_state()


    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        if not (self._read_only or parent_read_only):
            global should_redraw

            for b in new_input.buttons[:]:#we need to make a copy for remove to work as desired:
                if visible and self.button.mouse_over(new_input.m):
                    if b[1] in (1,2):
                        self.selected = True
                        should_redraw = True
                        new_input.buttons.remove(b)
                if self.selected and b[1] in (1,2) and (self.sync_val.value == self.on_val):
                    self.sync_val.value = self.off_val
                if self.selected and b[1] in (1,2) and (self.sync_val.value == self.off_val):
                    self.sync_val.value = self.on_val


            if self.hotkey is not None:
                for c in new_input.chars:
                    if c == self.hotkey:
                        self.selected = True
                        should_redraw = True
                        if self.sync_val.value == self.on_val:
                            self.sync_val.value = self.off_val
                        elif self.sync_val.value == self.off_val:
                            self.sync_val.value = self.on_val
                        break

                for k in new_input.keys:
                    if k[2] in (1,2):  #keydown
                        if k[0] == self.hotkey:
                            self.selected = True
                            should_redraw = True
                            if self.sync_val.value == self.on_val:
                                self.sync_val.value = self.off_val
                            elif self.sync_val.value == self.off_val:
                                self.sync_val.value = self.on_val
                            break

cdef class Icon(Thumb):
    cdef float _indicator_start, _indicator_stop
    cdef basestring _tooltip
    cdef bint being_hovered

    def __cinit__(self, *args, **kwargs):
        self._indicator_start = 0.
        self._indicator_stop = 0.
        self._tooltip = ''
        self.being_hovered = False
        self.outline = FitBox(Vec2(0,0),Vec2(icon_outline_size, icon_outline_size))

    @property
    def tooltip(self):
        return self._tooltip

    @tooltip.setter
    def tooltip(self, val):
        if self._tooltip != val:
            global should_redraw_overlay
            should_redraw_overlay = True
            self._tooltip = val

    @property
    def indicator_start(self):
        return self._indicator_start

    @indicator_start.setter
    def indicator_start(self, val):
        assert isinstance(val, float), 'Indicator values are required to be floats'
        val %= 1.
        if self._indicator_start != val:
            global should_redraw_overlay
            should_redraw_overlay = True
        self._indicator_start = val

    @property
    def indicator_stop(self):
        return self._indicator_stop

    @indicator_stop.setter
    def indicator_stop(self, val):
        assert isinstance(val, float), 'Indicator values are required to be floats'
        val %= 1.
        if self._indicator_stop != val:
            global should_redraw_overlay
            should_redraw_overlay = True
        self._indicator_stop = val

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        unused = super(Icon, self).handle_input(new_input, visible, parent_read_only)
        global should_redraw_overlay
        cdef bint hovering = visible and self.button.mouse_over(new_input.m)

        if hovering != self.being_hovered:
            self.being_hovered = hovering
            should_redraw_overlay = True
        elif new_input.s.y > 0.:
            should_redraw_overlay = True
        return unused

    cpdef draw(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        #update appearance
        self.outline.compute(parent)
        self.button.compute(self.outline)
        cdef tuple icon_color, bg_color
        cdef float ref_size = min(self.button.size)

        icon_color = 0, 0, 0, 1
        if self.sync_val.value == self.on_val or self.selected:
            bg_alpha = 1.
        else:
            bg_alpha = .6

        if self.selected:
            self.selected = False
            global should_redraw
            should_redraw = True

        utils.draw_points([self.button.center], size=int(ref_size*.7), color=RGBA(1., 1., 1., .3), sharpness=0.7)
        utils.draw_points([self.button.center], size=int(ref_size*.7), color=RGBA(1., 1., 1., bg_alpha), sharpness=0.9)

        glfont.push_state()
        glfont.set_font(self.label_font)
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_CENTER)
        glfont.set_size(max(1,int(ref_size+self.offset_size*ui_scale)-icon_font_padding*ui_scale))
        glfont.set_color_float((*icon_color[:3], 0.3))
        glfont.set_blur(3)
        cdef int text_x = self.button.center[0]+int(self.offset_x*ui_scale)
        cdef int text_y = self.button.center[1]+int(self.offset_y*ui_scale)
        glfont.draw_multi_line_text(text_x, text_y, self._label, self.label_line_height)
        glfont.set_blur(0.5)
        glfont.set_color_float(icon_color)
        glfont.draw_multi_line_text(text_x, text_y, self._label, self.label_line_height)
        glfont.pop_state()

    cpdef draw_overlay(self,FitBox parent,bint nested=True, bint parent_read_only = False):
        cdef basestring T = self.tooltip
        cdef float ref_size = min(self.button.size)
        if self.indicator_start != self.indicator_stop:
            utils.draw_progress(self.button.center, self.indicator_start,
                                self.indicator_stop, inner_radius=int(ref_size*.625),
                                outer_radius=int(ref_size*.9), color=RGBA(*icon_progress_color),
                                sharpness=0.9)

        if self._tooltip == '' or not self.being_hovered:
            return # only draw tooltip when set

        cdef float text_height = tooltip_text_size * ui_scale
        cdef float pad_x = 0.25*text_height
        cdef float pad_y = .5*pad_x
        cdef float tip_width = text_height + pad_x  # == 2* pad_y

        cdef float vert_loc = self.button.center[1]
        cdef float tip_loc_x = self.button.org.x + 10.*ui_scale
        cdef float text_loc_x = tip_loc_x - tip_width - pad_x
        glfont.push_state()
        glfont.set_font('opensans')
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_RIGHT)
        glfont.set_size(text_height)
        glfont.set_blur(.0)
        cdef float text_width = glfont.text_bounds(text_loc_x, vert_loc, T)

        utils.draw_tooltip((tip_loc_x, vert_loc), (text_width, text_height),
                           padding=(pad_x, pad_y), tooltip_color=RGBA(.8, .8, .8, .9),
                           sharpness=.9)

        # glfont.set_color_float((0., 0., 0., 0.3))
        # glfont.set_blur(3)
        # glfont.draw_text(text_loc_x, vert_loc, T)

        glfont.set_color_float((0., 0., 0., 8.))
        glfont.draw_text(text_loc_x, vert_loc, T)

        glfont.pop_state()


cdef class Hot_Key(UI_element):
    '''
    Just a hotkey. Not displayed.
    '''
    cdef int on_val,off_val
    cdef Synced_Value sync_val
    cdef public RGBA on_color,off_color
    cdef object hotkey

    def __cinit__(self,str attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None, hotkey = None):
        self.uid = id(self)
        self._label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.hotkey = hotkey
        self.outline = FitBox(Vec2(0,0),Vec2(0,0)) # we dont use it but we need to have it.


    def __init__(self,str attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None, hotkey = None):
        pass

    cpdef sync(self):
        self.sync_val.sync()

    cpdef handle_input(self,Input new_input,bint visible,bint parent_read_only = False):
        global should_redraw
        if not (self._read_only or parent_read_only):
            if self.hotkey is not None:
                for c in new_input.chars:
                    if c == self.hotkey:
                        if self.sync_val.value == self.on_val:
                            self.sync_val.value = self.off_val
                            should_redraw = True
                        elif self.sync_val.value == self.off_val:
                            self.sync_val.value = self.on_val
                            should_redraw = True
                        break
                for k in new_input.keys:
                    if k[2]  in (1,2):  #keydown
                        if k[0] == self.hotkey:
                            if self.sync_val.value == self.on_val:
                                self.sync_val.value = self.off_val
                                should_redraw = True
                            elif self.sync_val.value == self.off_val:
                                self.sync_val.value = self.on_val
                                should_redraw = True
                            break
