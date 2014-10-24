
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
        #self.outline.sketch()
        #self.field.sketch()


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
    cdef public FitBox outline,field,button
    cdef bint selected
    cdef int on_val, off_val
    cdef Synced_Value sync_val
    cdef obj

    def __cinit__(self,bytes attribute_name, object attribute_context, on_val = 1, off_val = 0,label = None, setter= None,getter= None):
        self.uid = id(self)
        self.label = label or attribute_name
        self.sync_val = Synced_Value(attribute_name,attribute_context,getter,setter)

        self.outline = FitBox(Vec2(0,0),Vec2(0,40)) # we only fix the height
        self.field = FitBox(Vec2(10,10),Vec2(-10,-10))
        self.button = FitBox(Vec2(-20,0),Vec2(20,20))
        self.selected = False

    def __init__(self,bytes attribute_name, object attribute_context,label = None, on_val = 0, off_val = 0, step = 1,setter= None,getter= None):
        pass


    cpdef sync(self):
        self.sync_val.sync()

    cpdef draw(self,FitBox parent,bint nested=True):
        
        #update appearance
        self.outline.compute(parent)
        self.field.compute(self.outline)
        self.button.compute(self.field)

        self.outline.sketch()
        # self.field.sketch()
        # self.button.sketch()

        if self.selected:
            utils.draw_points(((self.button.center),),size=40, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.button.center),),size=30, color=(.5,.5,.9,.9))
        else:
            utils.draw_points(((self.button.center),),size=30, color=(.0,.0,.0,.8),sharpness=.3)
            utils.draw_points(((self.button.center),),size=20, color=(.5,.5,.5,.9))

        gl.glPushMatrix()
        gl.glTranslatef(self.field.org.x,self.field.org.y,0)

        glfont.push_state()
        glfont.draw_text(10,0,self.label)
        glfont.set_align(fs.FONS_ALIGN_TOP | fs.FONS_ALIGN_RIGHT) 
        glfont.draw_text(self.field.size.x-10,0,bytes(self.sync_val.value))
        glfont.pop_state()
        
        gl.glPopMatrix()

    cpdef handle_input(self,Input new_input,bint visible):
        global should_redraw

        for b in new_input.buttons:
            if visible and self.button.mouse_over(new_input.m):
                if b[1] == 1:
                    new_input.buttons.remove(b)
                    self.selected = not self.selected
                    should_redraw = True
                    self.sync_val.value = not self.sync_val.value

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
        #self.textfield.sketch()
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
