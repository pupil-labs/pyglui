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
    cdef public bint read_only

    cpdef sync(self):
        global should_redraw
        pass

    cpdef draw(self,FitBox context, bint nested=True):
        pass

    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
            global should_redraw
            pass

    cpdef pre_handle_input(self,Input new_input):
        # if your element needs to catch input event in front of very boday else:
        # add yourself to new_input.active_ui_elements during handle_input
        # pre_handle input will be called in the next frame with new input.
        # add yourself again in handle input if you need to stay in active_ui_elements

        pass

    cpdef precompute(self,FitBox parent):
        self.outline.compute(parent)

    property height:
        def __get__(self):
            return self.outline.size.y



########## Slider ##########
#    +--------------------------------+
#    | Label                    Value |
#    | ------------------O----------- |
#    +--------------------------------+

cdef class Slider(UI_element):
    cdef float minimum,maximum,step
    cdef public FitBox field
    cdef bint selected
    cdef Vec2 slider_pos
    cdef Synced_Value sync_val
    cdef int steps

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
        self.read_only = False
        if self.step:
            self.steps = int((self.maximum-self.minimum)/float(step))
        else:
            self.steps = 0


    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        self.sync()
        if not isinstance(self.sync_val.value, (float,int) ):
            raise Exception('Slider values should be float or int type. "%s" is of type %s'%(self.sync_val.value,type(self.sync_val.value)))


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent, bint nested=True):
        #update appearance:
        self.outline.compute(parent)
        self.field.compute(self.outline)

        # map slider value
        self.slider_pos.x = clampmap(self.sync_val.value,self.minimum,self.maximum,0,self.field.size.x)
        #self.outline.sketch()
        #self.field.sketch()


        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)

        glfont.push_state()
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        if type(self.sync_val.value) == float:
            glfont.draw_text(self.field.size.x-x_spacer,0,bytes('%0.2f'%self.sync_val.value) )
            glfont.pop_state()
            used_x = glfont.text_bounds(0,0,bytes('%0.2f'%self.sync_val.value))
        else:
            glfont.draw_text(self.field.size.x-x_spacer,0,bytes(self.sync_val.value ))
            glfont.pop_state()
            used_x = glfont.text_bounds(0,0,bytes(self.sync_val.value))

        glfont.draw_limited_text(x_spacer,0,self.label,self.field.size.x-3*x_spacer-used_x)



        line(Vec2(0,slider_handle_org_y),Vec2(self.field.size.x, slider_handle_org_y))
        line_highlight(Vec2(0,slider_handle_org_y),Vec2(self.slider_pos.x,slider_handle_org_y))

        cdef float step_pixel_size,x
        if self.steps>1:
            step_pixel_size = lmap(self.minimum+self.step,self.minimum,self.maximum,0,self.field.size.x)
            if step_pixel_size >= slider_button_size*ui_scale:
                step_marks = [(x*step_pixel_size,slider_handle_org_y) for x in range(self.steps+1)]
                utils.draw_points(step_marks,size=slider_step_mark_size, color=slider_color_step)

        if self.selected:
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size_selected+slider_button_shadow, color=color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size_selected, color=color_selected)
        else:
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size+slider_button_shadow, color=color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.slider_pos.x,slider_handle_org_y),),size=slider_button_size, color=color_default)

        gl.glPopMatrix()



    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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

    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True):

        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.button.compute(self.field)

        # self.outline.sketch()
        # self.field.sketch()
        # self.button.sketch()
        if self.sync_val.value == self.on_val:
            utils.draw_points(((self.button.center),),size=switch_button_size_on+switch_button_shadow, color=color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size_on, color=color_on)
        elif self.selected:
            utils.draw_points(((self.button.center),),size=switch_button_size_selected+switch_button_shadow, color=color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size_selected, color=color_selected)
        else:
            utils.draw_points(((self.button.center),),size=switch_button_size+switch_button_shadow, color=color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=switch_button_size, color=color_default)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        glfont.draw_limited_text(x_spacer,0,self.label,self.field.size.x-(switch_button_size_on+switch_button_shadow))
        glfont.push_state()

        #glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_CENTER)

        # turn on text for debugging and rebuild if you want to check the value
        # glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        # glfont.draw_text(self.field.size.x-5,0,bytes(self.sync_val.value))
        glfont.pop_state()

        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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

    def __cinit__(self,bytes attribute_name, object attribute_context = None, selection = [], labels=None, label=None, setter=None, getter=None):
        self.uid = id(self)
        self.label = label or attribute_name

        self.selection = list(selection)
        self.selection_labels = labels or [str(s) for s in selection]

        for s in self.selection_labels:
            if not isinstance(s,str):
                raise Exception('Lables need to be strings not "%s"'%s)

        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter,self._on_change)

        self.outline = FitBox(Vec2(0,0),Vec2(0,selector_outline_size_y)) # we only fix the height
        self.field = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.select_field = FitBox(Vec2(x_spacer,0),Vec2(0,0))

    def __init__(self,bytes attribute_name, object attribute_context = None, selection = [], labels=None, label=None, setter=None, getter=None):
        pass


    def _on_change(self,new_value):
        try:
            self.selection_idx = self.selection.index(new_value)
        except ValueError:
            #we could throw and error here or ignore
            #but for now we just add the new object to the selection
            self.selection.append(new_value)
            self.selection_labels.append(str(new_value))
            self.selection_idx = len(self.selection_labels)-1


    cpdef draw(self,FitBox parent,bint nested=True):

        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.select_field.compute(self.field)

        # self.outline.sketch()
        # self.field.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        #glfont.push_state()
        cdef float label_text_space = glfont.draw_text(x_spacer,0,self.label)
        #glfont.pop_state()
        gl.glPopMatrix()

        self.select_field.org.x += label_text_space
        self.select_field.size.x  = max(0.0,self.select_field.size.x-label_text_space)
        self.select_field.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.select_field.org.x),int(self.select_field.org.y),0)
        #glfont.push_state()
        if self.selected:
            for y in range(len(self.selection)):
                glfont.draw_limited_text(x_spacer,y*line_height*ui_scale,self.selection_labels[y],self.select_field.size.x-x_spacer)
        else:
            glfont.draw_limited_text(x_spacer,0,self.selection_labels[self.selection_idx],self.select_field.size.x-x_spacer)
        #glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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
        self.selection_idx = int(mouse_y/(self.select_field.size.y/len(self.selection)) )
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
    cdef int caret,text_offset,caret_highlight


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
        self.caret_highlight = 0
        self.text_offset = 0

    def __init__(self,bytes attribute_name, object attribute_context = None,label = None,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True):
        #update appearance:
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.textfield.compute(self.field)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        dx = glfont.draw_text(x_spacer,0,self.label)
        gl.glPopMatrix()

        self.textfield.org.x += dx
        self.textfield.size.x -=dx

        self.draw_text_field()
        # self.draw_text_selection()


    cpdef pre_handle_input(self,Input new_input):
        global should_redraw
        while new_input.keys:
            k = new_input.keys.pop(0)
            if k == (257,36,0,0): #Enter and key up:
                self.finish_input()
                return

            elif k == (259,51,0,0) or k ==(259,51,2,0): #Delete and key up:
                if self.caret > 0 and self.highlight is False:
                    self.preview = self.preview[:self.caret-1] + self.preview[self.caret:]
                    self.caret -=1
                if self.highlight:
                    self.preview = self.preview[:min(self.caret_highlight,self.caret)] + self.preview[max(self.caret_highlight,self.caret):]
                    self.highlight = False

                self.caret = max(0,self.caret)
                should_redraw = True

            elif k == (263,123,0,0): #key left:
                self.caret -=1
                self.caret = max(0,self.caret)
                should_redraw = True

            elif k == (262,124,0,0): #key right
                self.caret +=1
                self.caret = min(len(self.preview),self.caret)
                should_redraw = True
                self.highlight=False

            elif k == (263,123,0,1): #key left with shift:
                if self.highlight is False:
                    self.caret_highlight = max(0,self.caret)
                self.caret -=1
                self.caret = max(0,self.caret)
                self.highlight = True
                should_redraw = True

            elif k == (262,124,0,1): #key left with shift:
                if self.highlight is False:
                    self.caret_highlight = min(len(self.preview),self.caret)
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
                    self.abort_input()



    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw
        if not self.read_only and not self.selected:
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


    cdef draw_text_field(self):
        cdef bytes pre_caret
        cdef float x,caret_x
        if self.selected:
            pre_caret = self.preview[:self.caret]
            highlight_size = self.preview[:self.caret_highlight]

            gl.glPushMatrix()

            #then transform locally and render the UI element
            gl.glTranslatef(int(self.textfield.org.x),int(self.textfield.org.y),0)
            line_highlight(Vec2(0,self.textfield.size.y), self.textfield.size)
            x = glfont.draw_limited_text(x_spacer,0,self.preview,self.textfield.size.x-x_spacer)

            caret_x = min(glfont.text_bounds(0,0,pre_caret)+x_spacer,x)

            # to be removed 
            # if glfont.text_bounds(0,0,pre_caret) > self.textfield.size.x-3*x_spacer:
            #     print "caret index: %s, width: %s, caret pos: %s" %(self.caret, self.textfield.size.x, glfont.text_bounds(0,0,pre_caret))

            # draw highlighted text if any
            if self.highlight:
                rect_highlight(Vec2(caret_x,0),Vec2(glfont.text_bounds(0,0,highlight_size)+x_spacer,self.textfield.size.y))

            # draw the caret
            gl.glColor4f(1,1,1,.5)
            gl.glLineWidth(1)
            gl.glBegin(gl.GL_LINES)
            gl.glVertex3f(caret_x,0,0)
            gl.glVertex3f(caret_x,self.textfield.size.y,0)
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

    def __cinit__(self,label, setter):
        self.uid = id(self)
        self.label = label
        self.outline = FitBox(Vec2(0,0),Vec2(0,button_outline_size_y)) # we only fix the height
        self.button = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.selected = False
        self.function = setter

    def __init__(self,label, setter):
        pass


    cpdef draw(self,FitBox parent,bint nested=True):
        #update appearance:
        self.outline.compute(parent)
        self.button.compute(self.outline)

        # self.outline.sketch()
        if self.selected:
            pass
        else:
            self.button.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.button.org.x),int(self.button.org.y),0)
        glfont.draw_limited_text(x_spacer,0,self.label,self.button.size.x-x_spacer)
        gl.glPopMatrix()


    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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


########## Thumb ##########


cdef class Thumb(UI_element):
    '''
    Not a classical UI element. Use button instead.
    Thumb is a circular type of switch/button
    '''
    cdef public FitBox button
    cdef bint selected
    cdef int on_val,off_val
    cdef Synced_Value sync_val
    cdef public RGBA on_color
    cdef bytes hotkey

    def __cinit__(self,bytes attribute_name, object attribute_context = None, on_val=True, off_val=False, label=None, setter=None, getter=None,bytes hotkey = None, RGBA on_color=RGBA(*thumb_default_on_color)):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(thumb_outline_size,thumb_outline_size))
        self.button = FitBox(Vec2(outline_padding,outline_padding),Vec2(-outline_padding,-outline_padding))
        self.selected = False
        self.on_color = on_color
        self.hotkey = hotkey

    def __init__(self,bytes attribute_name, object attribute_context = None,label = None, on_val = True, off_val = False ,setter= None,getter= None,bytes hotkey = None,RGBA on_color=RGBA(*thumb_default_on_color)):
        pass


    cpdef sync(self):
        self.sync_val.sync()


    cpdef draw(self,FitBox parent,bint nested=True):
        #update appearance
        self.outline.compute(parent)
        self.button.compute(self.outline)
        if self.sync_val.value == self.on_val:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=thumb_color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_on, color=self.on_color[:],sharpness=thumb_button_sharpness)
        elif self.selected:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=thumb_color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_selected, color=thumb_color_on,sharpness=thumb_button_sharpness)
        else:
            utils.draw_points(((self.button.center),),size=int(min(self.button.size)), color=thumb_color_shadow,sharpness=shadow_sharpness)
            utils.draw_points(((self.button.center),),size=int(min(self.button.size))-thumb_button_size_offset_off, color=thumb_color_off,sharpness=thumb_button_sharpness)

        glfont.push_state()
        glfont.set_size(max(1,int(min(self.button.size))-thumb_font_padding))
        glfont.set_align(fs.FONS_ALIGN_MIDDLE | fs.FONS_ALIGN_CENTER)
        glfont.set_blur(1.)
        glfont.set_font('roboto')
        glfont.draw_text(self.button.center[0],self.button.center[1],self.label[0])
        glfont.pop_state()
        glfont.set_font('opensans')



    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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

        cdef bytes k
        if self.hotkey is not None:
            for k in new_input.chars:
                if k == self.hotkey:
                    if self.sync_val.value == self.on_val:
                        self.sync_val.value = self.off_val
                        self.selected = False
                        should_redraw = True
                    elif self.sync_val.value == self.off_val:
                            self.sync_val.value = self.on_val
                            self.selected = False
                            should_redraw = True