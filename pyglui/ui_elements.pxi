
DEF text_height = 20


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

    property height:
        def __get__(self):
            return self.outline.size.y

cdef class Slider(UI_element):
    cdef float minimum,maximum,step
    cdef public FitBox field
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
        self.outline = FitBox(Vec2(0,0),Vec2(0,80)) # we only fix the height
        self.field = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.slider_pos = Vec2(0,20)
        self.selected = False
        self.read_only = False


    def __init__(self,bytes attribute_name, object attribute_context,label = None, min = 0, max = 100, step = 1,setter= None,getter= None):
        pass


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

        #todo: draw step lines if they make sense
        step_pixels = clampmap(2,self.minimum,self.maximum,0,self.field.size.x)
        steps = frange(0,self.field.size.x,step_pixels*2)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)

        glfont.push_state()
        glfont.draw_text(10,0,self.label)
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT)
        if type(self.sync_val.value) == float:
            glfont.draw_text(self.field.size.x-10,0,bytes('%0.2f'%self.sync_val.value) )
        else:
            glfont.draw_text(self.field.size.x-10,0,bytes(self.sync_val.value ))
        glfont.pop_state()

        slider_line(Vec2(0,40),Vec2(self.field.size.x, 40))
        
        if self.step > 1 and step_pixels > 10.0: 
            for s in steps:
                utils.draw_points(((s,40),),size=8, color=(0.8,0.8,0.8,0.6))

        if self.selected:
            utils.draw_points(((self.slider_pos.x,40),),size=40, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.slider_pos.x,40),),size=30, color=(.5,.5,.9,.9))
        else:
            utils.draw_points(((self.slider_pos.x,40),),size=30, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.slider_pos.x,40),),size=20, color=(.5,.5,.5,.9))

        gl.glPopMatrix()



    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
            global should_redraw

            if self.selected and new_input.dm:
                val = clampmap(new_input.m.x-self.field.org.x,0,self.field.size.x,self.minimum,self.maximum)
                self.sync_val.value = step(val,self.minimum,self.maximum,self.step)
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


cdef class Switch(UI_element):
    cdef public FitBox field,button
    cdef bint selected
    cdef int on_val,off_val
    cdef Synced_Value sync_val

    def __cinit__(self,bytes attribute_name, object attribute_context, on_val=True, off_val=False, label=None, setter=None, getter=None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)
        self.on_val = on_val
        self.off_val = off_val
        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.field = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.button = FitBox(Vec2(-20,0),Vec2(20,20))
        self.selected = False

    def __init__(self,bytes attribute_name, object attribute_context,label = None, on_val = True, off_val = False ,setter= None,getter= None):
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
            utils.draw_points(((self.button.center),),size=40, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.button.center),),size=30, color=(.5,.5,.9,.9))
        else:
            utils.draw_points(((self.button.center),),size=30, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.button.center),),size=20, color=(.5,.5,.5,.9))

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)

        glfont.push_state()
        glfont.draw_text(10,0,self.label)
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
                        new_input.buttons.remove(b)
                        self.selected = True
                        should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.on_val):
                    new_input.buttons.remove(b)
                    self.sync_val.value = self.off_val
                    self.selected = False
                    should_redraw = True
                if self.selected and b[1] == 0 and (self.sync_val.value == self.off_val):
                    new_input.buttons.remove(b)
                    self.sync_val.value = self.on_val
                    self.selected = False
                    should_redraw = True



cdef class Selector(UI_element):
    cdef public FitBox field, select_field
    cdef object selection, selection_labels
    cdef Synced_Value sync_val
    cdef int selection_idx
    cdef bint selected

    def __cinit__(self,bytes attribute_name, object attribute_context, selection, selection_labels=None, label=None, setter=None, getter=None):
        self.uid = id(self)
        self.label = label or attribute_name

        self.selection = list(selection)
        self.selection_labels = selection_labels or [str(s) for s in selection]
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter,self._on_change)

        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.field = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.select_field = FitBox(Vec2(50,0),Vec2(0,0))

    def __init__(self,bytes attribute_name, object attribute_context, selection, selection_labels=None, label=None, setter=None, getter=None):
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


    cpdef draw(self,FitBox parent,bint nested=True):

        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.select_field.compute(self.field)

        # self.outline.sketch()
        # self.field.sketch()
        self.select_field.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.field.org.x),int(self.field.org.y),0)
        glfont.push_state()
        glfont.draw_text(10,0,self.label)
        glfont.pop_state()
        gl.glPopMatrix()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.select_field.org.x),int(self.select_field.org.y),0)
        glfont.push_state()
        if self.selected:
            for y in range(len(self.selection)):
                glfont.draw_text(10,y*text_height*ui_scale,self.selection_labels[y])
        else:
            glfont.draw_text(10,0,self.selection_labels[self.selection_idx])
        glfont.pop_state()
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
            global should_redraw

            for b in new_input.buttons:
                if visible and self.select_field.mouse_over(new_input.m):
                    new_input.buttons.remove(b)
                    if b[1] == 0:
                        should_redraw = True
                        if not self.selected:
                            self.init_selection()
                        else:
                            self.finish_selection(mouse_y = new_input.m.y-self.select_field.org.y)

    cdef init_selection(self):
        self.selected = True
        #blow up the menu to fit the open selector field
        cdef h = text_height * len(self.selection_labels)
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y #double neg
        self.outline.design_size.y = h


    cdef finish_selection(self,float mouse_y):
        self.selection_idx = int(mouse_y/(self.select_field.size.y/len(self.selection)) )
        #just for sanity
        self.selection_idx = int(clamp(self.selection_idx,0,len(self.selection)-1))

        self.sync_val.value = self.selection[self.selection_idx]

        #make the outline small again
        cdef h = text_height
        h+= self.field.design_org.y - self.field.design_size.y #double neg
        h+= self.select_field.design_org.y - self.select_field.design_size.y #double neg
        self.outline.design_size.y = h

        self.selected = False





cdef class TextInput(UI_element):
    cdef FitBox textfield
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
        #update appearance:
        self.outline.compute(parent)

        gl.glPushMatrix()
        gl.glTranslatef(int(self.outline.org.x),int(self.outline.org.y),0)
        dx = glfont.draw_text(10,10,self.label)
        dx += 10
        self.textfield.design_org.x = dx
        self.textfield.compute(self.outline)
        gl.glPopMatrix()

        gl.glPushMatrix()
        #then transform locally and render the UI element
        #self.textfield.sketch()
        gl.glTranslatef(int(self.textfield.org.x),int(self.textfield.org.y),0)
        glfont.draw_text(10,0,self.preview)
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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


cdef class Button(UI_element):
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


    cpdef draw(self,FitBox parent,bint nested=True):
        #update appearance:
        self.outline.compute(parent)
        self.button.compute(self.outline)

        self.outline.sketch()
        if self.selected:
            pass
        else:
            self.button.sketch()

        gl.glPushMatrix()
        gl.glTranslatef(int(self.button.org.x),int(self.button.org.y),0)
        glfont.draw_text(10,0,self.label)
        gl.glPopMatrix()


    cpdef handle_input(self,Input new_input,bint visible):
        if not self.read_only:
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
