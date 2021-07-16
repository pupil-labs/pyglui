cimport pyglui.pyfontstash.cfontstash as fs

#expose some constansts when c imported
FONS_ALIGN_LEFT = fs.FONS_ALIGN_LEFT
FONS_ALIGN_CENTER = fs.FONS_ALIGN_CENTER
FONS_ALIGN_RIGHT = fs.FONS_ALIGN_RIGHT
FONS_ALIGN_TOP = fs.FONS_ALIGN_TOP
FONS_ALIGN_MIDDLE = fs.FONS_ALIGN_MIDDLE
FONS_ALIGN_BOTTOM = fs.FONS_ALIGN_BOTTOM
FONS_ALIGN_BASELINE = fs.FONS_ALIGN_BASELINE
FONS_ZERO_TOPLEFT = fs.FONS_ZERO_TOPLEFT
FONS_ZERO_BOTTOMLEFT = fs.FONS_ZERO_BOTTOMLEFT

cdef unicode _to_unicode(object s):
    if type(s) is unicode:
        return <unicode>s
    else:
        return (<bytes>s).decode('utf-8')

cdef bytes _to_utf8_bytes(object s):
    if type(s) is unicode:
        return (<unicode>s).encode('utf-8')
    else:
        return <bytes>s



cdef class Context:
    def __cinit__(self,atlas_size = (1024,1024),flags = fs.FONS_ZERO_TOPLEFT):
        self.ctx = fs.glfonsCreate(atlas_size[0],atlas_size[1],flags)

    def __init__(self,atlas_size = (1024,1024),flags = fs.FONS_ZERO_TOPLEFT):
        self.fonts = {}

    def __dealloc__(self):
        fs.glfonsDelete(self.ctx)

    def add_font(self, object name, object font_loc):
        cdef int font_id = fs.FONS_INVALID

        font_id = fs.fonsAddFont(self.ctx, _to_utf8_bytes(name), _to_utf8_bytes(font_loc))
        if font_id == fs.FONS_INVALID:
            raise Exception("Font could not be loaded from '%s'."%font_loc)
        else:
            self.fonts[name]=font_id

    property fonts:
        def __get__(self):
            return self.fonts

    def set_align(self,int align):
        '''
        bitwise or '|' the following:
        FONS_ALIGN_LEFT
        FONS_ALIGN_CENTER
        FONS_ALIGN_RIGHT
        FONS_ALIGN_TOP
        FONS_ALIGN_MIDDLE
        FONS_ALIGN_BOTTOM
        FONS_ALIGN_BASELINE
        '''
        fs.fonsSetAlign(self.ctx,align)

    def set_align_string(self,v_align='left',h_align='top'):
        v_align = {'left':FONS_ALIGN_LEFT,'center':FONS_ALIGN_CENTER,'right':FONS_ALIGN_RIGHT}[v_align]
        h_align = {'top':FONS_ALIGN_TOP,'middle':FONS_ALIGN_MIDDLE,'bottom':FONS_ALIGN_BOTTOM}[h_align]
        self.set_align(v_align | h_align)

    def set_blur(self,float blur):
        fs.fonsSetBlur(self.ctx,blur)

    def push_state(self):
        fs.fonsPushState(self.ctx)

    def pop_state(self):
        fs.fonsPopState(self.ctx)

    def clear_state(self):
        fs.fonsClearState(self.ctx)

    def set_size(self, float size):
        fs.fonsSetSize(self.ctx,size)

    def set_spacing(self, float spacing):
        fs.fonsSetSpacing(self.ctx,spacing)

    def set_font(self,object font_name):
        fs.fonsSetFont(self.ctx,self.fonts[font_name])

    def set_font_id(self,int font_id):
        fs.fonsSetFont(self.ctx,font_id)

    cpdef draw_text(self,float x,float y,object text):
        cdef float dx = fs.fonsDrawText(self.ctx,x,y,_to_utf8_bytes(text),NULL)
        return dx

    cpdef draw_limited_text(self, float x, float y, text, float width):
        '''
        draw text limited in width - it will cut off on the right hand side.
        '''
        cdef unicode utext = _to_unicode(text)
        if fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(utext), NULL, NULL) <= width:
            #early exit it fits
            return self.draw_text(x,y,utext)

        if width <= 0:
            #early exit even the smallest char would not fit
            return self.draw_text(x,y,'')



        # start_text_clip = int(width/avg_char_width)
        cdef float avg_char_width = fs.fonsTextBounds(self.ctx, 0,0, 'o', NULL, NULL)
        cdef int max_idx = len(utext)
        cdef int idx = int(width/avg_char_width)
        cdef unicode clip = utext[:idx]
        cdef bint initial_guess_fits = fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) <= width


        if initial_guess_fits:
            #we add chars until it does not fit. then go back one
            while 0 <= idx <= max_idx:
                idx +=1
                clip = utext[:idx]
                if fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) > width:
                    idx -=1
                    break
        else:
            #we remove chars until it does fit.
            while 0 <= idx <= max_idx:
                idx -=1
                clip = utext[:idx]
                if fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) < width:
                    break


        utext = utext[:idx] #+ '..'
        return self.draw_text(x,y,utext)

    cpdef get_first_char_idx(self, object text, float width):
        '''
        get the clip index for a given width
        '''
        cdef unicode utext = _to_unicode(text)
        cdef int idx = len(utext)
        cdef unicode clip
        # reverse the text
        utext = utext[::-1]

        while idx:
            clip = utext[:idx]
            if fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) <= width:
                break
            idx -=1

        return len(utext)-idx

    cpdef draw_multi_line_text(self, float x, float y, object text, float line_height = 1):
        '''
        draw multiple lines of text delimited by "\n"
        '''
        cdef float asc = 0,des = 0,lineh = 0
        fs.fonsVertMetrics(self.ctx, &asc,&des,&lineh)
        line_height *= lineh
        lines = text.split('\n')
        for l in lines:
            fs.fonsDrawText(self.ctx,x,y,_to_utf8_bytes(l),NULL)
            y += line_height


    cpdef draw_breaking_text(self, float x, float y, object text, float width,float height,float line_height = 1):
        '''
        draw a string of text breaking at the bounds.
        '''

        cdef unicode utext = _to_unicode(text)

        # first we figure out the v space
        cdef float asc = 0,des = 0,lineh = 0
        fs.fonsVertMetrics(self.ctx, &asc,&des,&lineh)
        line_height *= lineh
        cdef float max_y = y + height - line_height

        # second we break the text into lines
        cdef unicode clip
        cdef list words = utext.split(' ')
        cdef int idx = 0, max_idx = len(words)

        # now we draw words
        while words:
            clip = ' '.join(words[:idx+1])
            if idx >= max_idx or fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) > width or u'\n' in clip[:-1]:
                clip = u' '.join(words[:idx])
                if clip and clip[-1] == u'\n':
                    clip = clip[:-1]
                fs.fonsDrawText(self.ctx,x,y,_to_utf8_bytes(clip),NULL)
                words = words[idx:]
                idx = 1 #always draw the first word.
                y += line_height
                if y > max_y:
                    break
            else:
                idx +=1

        return words,y

    cpdef compute_breaking_text(self, float x, float y, object text, float width,float height,float line_height = 1):
        '''
        draw a string of text breaking at the bounds.
        '''
        cdef unicode utext = _to_unicode(text)


        # first we figure out the v space
        cdef float asc = 0,des = 0,lineh = 0
        fs.fonsVertMetrics(self.ctx, &asc,&des,&lineh)
        line_height *= lineh
        cdef float max_y = y + height - line_height

        # second we break the text into lines
        cdef unicode clip
        cdef list words = utext.split(' ')
        cdef int idx = 1, max_idx = len(words)

        cdef bint first = True
        # now we draw words
        while words:
            clip = ' '.join(words[:idx])
            if idx > max_idx or fs.fonsTextBounds(self.ctx, 0,0, _to_utf8_bytes(clip), NULL, NULL) > width:
                if first == True:
                    idx = max(0,idx-1)
                    first = False
                else:
                    idx = max(0,idx-2)
                clip = u' '.join(words[:idx])
                words = words[idx:]
                y += line_height
                if y > max_y:
                    break
            idx +=1

        return words,y


    cpdef char_cumulative_width(self,float x, float y, object text):
        '''
        return a list with the cumulative width of each char in given text
        can be used as a map for positioning the caret
        or determining if a mouse position is close to a caret position
        '''
        cdef unicode utext = _to_unicode(text)
        # break the text string into chars
        cdef int total = 0
        cdef list running_sum = [0]
        for c in utext:
            total += self.text_bounds(x,y,c)
            running_sum.append(total)
        return running_sum


    def text_bounds(self,float x,float y, object text):
        '''
        get the width of a text
        '''
        cdef float width
        width = fs.fonsTextBounds(self.ctx,x,y,_to_utf8_bytes(text),NULL,NULL)
        return width

    #todo:
    #fonsLineBounds

    cpdef vertical_metrics(self):
        cdef float asc = 0,des = 0,lineh = 0
        fs.fonsVertMetrics(self.ctx, &asc,&des,&lineh)
        return asc,des,lineh


    cpdef set_color_float(self,tuple color):
        cdef unsigned int ir,ig,ib,ia,c
        ir = int(color[0]*255)
        ig = int(color[1]*255)
        ib = int(color[2]*255)
        ia = int(color[3]*255)
        c = fs.glfonsRGBA(ir,ig,ib,ia)
        fs.fonsSetColor(self.ctx,c)

    def draw_debug(self,float x,float y):
        fs.fonsDrawDebug(self.ctx,x,y)
