
cdef inline push_view(Vec2 size):
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glPushMatrix()
    gl.glLoadIdentity()
    gl.glOrtho(0, size.x, size.y, 0, -1, 1)
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glPushMatrix()
    gl.glLoadIdentity()

cdef inline pop_view():
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glPopMatrix()
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glPopMatrix()

cdef inline rect(Vec2 org, Vec2 size, RGBA color):
    gl.glColor4f(color.r, color.g, color.b, color.a)
    gl.glBegin(gl.GL_POLYGON)
    gl.glVertex3f(org.x,org.y,0.0)
    gl.glVertex3f(org.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y+size.y,0.0)
    gl.glVertex3f(org.x+size.x,org.y,0.0)
    gl.glEnd()

cdef inline rect_outline(Vec2 org, Vec2 size, float line_width, RGBA color):
    gl.glColor4f(color.r, color.g, color.b, color.a)
    gl.glLineWidth(line_width)
    gl.glBegin(gl.GL_LINE_LOOP)
    gl.glVertex3f(org.x - line_width, org.y - line_width,0.0)
    gl.glVertex3f(org.x - line_width,org.y+size.y + line_width,0.0)
    gl.glVertex3f(org.x+size.x + line_width,org.y+size.y + line_width,0.0)
    gl.glVertex3f(org.x+size.x + line_width,org.y - line_width,0.0)
    gl.glEnd()

cdef inline rect_corners(Vec2 org, Vec2 end, RGBA color):
    gl.glColor4f(color.r, color.g, color.b, color.a)
    gl.glBegin(gl.GL_POLYGON)
    gl.glVertex3f(org.x,org.y,0.0)
    gl.glVertex3f(org.x,end.y,0.0)
    gl.glVertex3f(end.x,end.y,0.0)
    gl.glVertex3f(end.x,org.y,0.0)
    gl.glEnd()

cdef inline tripple_h(Vec2 org, Vec2 size, RGBA color=RGBA(1.,1.,1.,.5)):
    gl.glColor4f(color.r, color.g, color.b, color.a)
    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x + 3*ui_scale         ,org.y+5*ui_scale,0)
    gl.glVertex3f(org.x + size.x- 3*ui_scale ,org.y+ 5*ui_scale,0)

    gl.glVertex3f(org.x + 3   *ui_scale      ,org.y+size.y/2,0)
    gl.glVertex3f(org.x + size.x -3 *ui_scale,org.y+size.y/2,0)

    gl.glVertex3f(org.x + 3 *ui_scale        ,org.y+size.y-5*ui_scale,0)
    gl.glVertex3f(org.x + size.x -3*ui_scale ,org.y+size.y-5*ui_scale,0)

    gl.glEnd()

cdef inline tripple_d(Vec2 org, Vec2 size):
    cdef Vec2 o = org,s=size-Vec2(9*ui_scale,9*ui_scale)
    gl.glColor4f(1,1,1,.5)
    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)


    gl.glVertex3f(o.x,o.y+s.y,0)
    gl.glVertex3f(o.x + s.x,o.y,0)

    gl.glVertex3f(o.x + s.x*.0,o.y+s.y*.33,0)
    gl.glVertex3f(o.x + s.x*.33,o.y+s.y*0,0)

    gl.glVertex3f(o.x + s.x*.66,o.y+s.y*1.,0)
    gl.glVertex3f(o.x + s.x*1.,o.y+s.y*.66,0)

    gl.glEnd()

cdef inline triangle_h(Vec2 org, Vec2 size, RGBA color):
    gl.glColor4f(color.r,color.g,color.b,color.a)

    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x + 3 *ui_scale        ,org.y+5*ui_scale,0)
    gl.glVertex3f(org.x + size.x- 3*ui_scale ,org.y+ 5*ui_scale,0)
    gl.glEnd()

    #gl.glBegin(gl.GL_POLYGON)
    #gl.glVertex3f(org.x + 0         ,org.y+size.y/2,0)
    #gl.glVertex3f(org.x + size.x/2. ,org.y+size.y-5,0)
    #gl.glVertex3f(org.x + size.x -0 ,org.y+size.y/2,0)
    #gl.glEnd()

    gl.glBegin(gl.GL_LINE_LOOP)
    gl.glVertex3f(org.x + 3 *ui_scale        ,org.y+size.y/2,0)
    gl.glVertex3f(org.x + size.x/2. ,org.y+size.y-5*ui_scale,0)
    gl.glVertex3f(org.x + size.x -3*ui_scale ,org.y+size.y/2,0)
    gl.glEnd()

cdef inline tripple_v(Vec2 org, Vec2 size):
    gl.glColor4f(1,1,1,.5)
    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x + 5*ui_scale         ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + 5*ui_scale         ,org.y+size.y-3*ui_scale,0)

    gl.glVertex3f(org.x + size.x/2  ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + size.x/2 ,org.y+size.y-3*ui_scale,0)

    gl.glVertex3f(org.x + size.x -5*ui_scale ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + size.x -5*ui_scale ,org.y+size.y-3*ui_scale,0)

    gl.glEnd()

cdef inline triangle_right(Vec2 org, Vec2 size):
    gl.glColor4f(1,1,1,.5)

    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x + size.x -5*ui_scale ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + size.x -5*ui_scale ,org.y+size.y-3*ui_scale,0)
    gl.glEnd()


    gl.glBegin(gl.GL_LINE_LOOP)
    gl.glVertex3f(org.x + size.x/2  ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + 5*ui_scale          ,org.y+size.y/2,0)
    gl.glVertex3f(org.x + size.x/2  ,org.y+size.y-3*ui_scale,0)
    gl.glEnd()

cdef inline triangle_left(Vec2 org, Vec2 size):
    gl.glColor4f(1,1,1,.5)

    gl.glLineWidth(1.6*ui_scale)
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x + 5 *ui_scale        ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + 5 *ui_scale        ,org.y+size.y-3*ui_scale,0)
    gl.glEnd()


    gl.glBegin(gl.GL_LINE_LOOP)
    gl.glVertex3f(org.x + size.x/2  ,org.y+3*ui_scale,0)
    gl.glVertex3f(org.x + size.x -5*ui_scale ,org.y+size.y/2,0)
    gl.glVertex3f(org.x + size.x/2 ,org.y+size.y-3*ui_scale,0)
    gl.glEnd()

cdef inline line(Vec2 org, Vec2 end, RGBA color):
    gl.glColor4f(color.r, color.g, color.b, color.a)
    gl.glLineWidth(1.5*ui_scale) #thinner lines sometimes dont show on certain hardware.
    gl.glBegin(gl.GL_LINES)
    gl.glVertex3f(org.x, org.y,0)
    gl.glVertex3f(end.x, end.y,0)
    gl.glEnd()

cdef inline FitBox draw_seek_handle(FitBox handle, RGBA color):
    ''' Draw the seek handle and return FitBox that corresponds to the draggable area
    '''
    rect(handle.org, handle.size, color)
    cdef FitBox drag = handle.computed_copy()
    drag.org.x -= 10 * drag.size.x
    drag.size.x *= 21
    drag.size.y += 20 * ui_scale
    return drag

cdef inline FitBox draw_trim_handle(FitBox handle, float opening, RGBA color):
    ''' Draw a handle and return FitBox that corresponds draggable area
    '''
    # cdef Vec2 line_size = Vec2(2* ui_scale, handle.size.y * 3 / 4)
    # cdef Vec2 line_org = Vec2(0., handle.org.y + handle.size.y / 2 - line_size.y / 2)
    cdef tuple location
    if opening == 0.25:  # left handle
        location = handle.org.x + handle.size.x, handle.org.y + handle.size.y / 2
        # line_org.x = handle.org.x + handle.size.x - line_size.x
    elif opening == 0.75:  # right handle
        location = handle.org.x, handle.org.y + handle.size.y / 2
        # line_org.x = h andle.org.x
    else:
        location = handle.center
    utils.draw_progress(location, (opening + 0.25) % 1., (opening - 0.25) % 1.,
                        inner_radius=0., outer_radius=handle.size.y + ui_scale, color=color,
                        sharpness=0.9)
    cdef FitBox drag = handle.computed_copy()
    drag.org = Vec2(location[0] - drag.size.x, location[1] - drag.size.y)
    drag.size *= 2
    return drag

cdef inline FitBox draw_handle_top_right(Vec2 tip_loc, Vec2 handle_size, RGBA color):
    ''' Draw a handle and return FitBox that corresponds draggable area
    '''
    cdef float tip_length = 10.*ui_scale
    cdef float half_line_width = 2. * ui_scale

    rect_corners(Vec2(tip_loc.x - half_line_width, tip_loc.y),
                 Vec2(tip_loc.x + half_line_width, tip_loc.y - tip_length), color)

    rect_corners(Vec2(tip_loc.x - half_line_width + handle_size.x, tip_loc.y - tip_length),
                 Vec2(tip_loc.x - half_line_width, tip_loc.y - tip_length - handle_size.y), color)

    return FitBox(Vec2(tip_loc.x - half_line_width, tip_loc.y - tip_length - handle_size.y) / ui_scale, handle_size / ui_scale)

### OpenGL funtions for rendering to texture.
### Using this saves us considerable cpu/gpu time when the UI remains static.
### An almost identical implementation can be found in cylg.utils
ctypedef struct fbo_tex_id:
    gl.GLuint fbo_id
    gl.GLuint tex_id

cdef fbo_tex_id create_ui_texture(Vec2 tex_size):
    cdef fbo_tex_id ui_layer
    ui_layer.fbo_id = 0
    ui_layer.tex_id = 0

    # create Framebufer Object
    #requires gl ext or opengl > 3.0
    gl.glGenFramebuffers(1, &ui_layer.fbo_id)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, ui_layer.fbo_id)

    #create texture object
    gl.glGenTextures(1, &ui_layer.tex_id)
    gl.glBindTexture(gl.GL_TEXTURE_2D, ui_layer.tex_id)
    # configure Texture
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0,gl.GL_RGBA, int(tex_size.x),
                    int(tex_size.y), 0,gl.GL_RGBA, gl.GL_UNSIGNED_BYTE,
                    NULL)
    #set filtering
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST)
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST)

    #attach texture to fbo
    gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0,
                                gl.GL_TEXTURE_2D, ui_layer.tex_id, 0)

    if gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) != gl.GL_FRAMEBUFFER_COMPLETE:
        raise Exception("UI Framebuffer could not be created.")

    #unbind fbo and texture
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)

    return ui_layer

cdef destroy_ui_texture(fbo_tex_id ui_layer):
    gl.glDeleteTextures(1,&ui_layer.tex_id)
    gl.glDeleteFramebuffers(1,&ui_layer.fbo_id)

cdef resize_ui_texture(fbo_tex_id ui_layer, Vec2 tex_size):
    gl.glBindTexture(gl.GL_TEXTURE_2D, ui_layer.tex_id)
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0,gl.GL_RGBA, int(tex_size.x),
                    int(tex_size.y), 0,gl.GL_RGBA, gl.GL_UNSIGNED_BYTE,
                    NULL)
    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)


cdef render_to_ui_texture(fbo_tex_id ui_layer):
    # set fbo as render target
    # blending method after:
    # http://stackoverflow.com/questions/24346585/opengl-render-to-texture-with-partial-transparancy-translucency-and-then-rende/24380226#24380226
    gl.glBlendFuncSeparate(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA,
                                gl.GL_ONE_MINUS_DST_ALPHA, gl.GL_ONE)
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, ui_layer.fbo_id)
    gl.glClearColor(0.,0.,0.,0.)
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)


cdef render_to_screen():
    # set rendertarget 0
    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0)
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)

cdef draw_ui_texture(fbo_tex_id ui_layer):
    # render texture

    # set blending
    gl.glBlendFunc(gl.GL_ONE, gl.GL_ONE_MINUS_SRC_ALPHA)

    # bind texture and use.
    gl.glBindTexture(gl.GL_TEXTURE_2D, ui_layer.tex_id)
    gl.glEnable(gl.GL_TEXTURE_2D)

    #set up coord system
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glPushMatrix()
    gl.glLoadIdentity()
    gl.glOrtho(0, 1, 1, 0, -1, 1)
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glPushMatrix()
    gl.glLoadIdentity()

    gl.glColor4f(1.0,1.0,1.0,1.0)
    # Draw textured Quad.
    gl.glBegin(gl.GL_QUADS)
    gl.glTexCoord2f(0.0, 1.0)
    gl.glVertex2f(0,0)
    gl.glTexCoord2f(1.0, 1.0)
    gl.glVertex2f(1,0)
    gl.glTexCoord2f(1.0, 0.0)
    gl.glVertex2f(1,1)
    gl.glTexCoord2f(0.0, 0.0)
    gl.glVertex2f(0,1)
    gl.glEnd()

    #pop coord systems
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glPopMatrix()
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glPopMatrix()

    gl.glBindTexture(gl.GL_TEXTURE_2D, 0)
    gl.glDisable(gl.GL_TEXTURE_2D)
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
