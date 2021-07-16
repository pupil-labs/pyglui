from cython cimport view
from libcpp.vector cimport vector

import numpy as np

cimport numpy as np

cimport pyglui.cygl.shader as shader


cpdef RGBA mix_smooth(RGBA first, RGBA second, float val, float min_, float max_):
    cdef float pct = np.clip((val - min_) / (max_ - min_), 0., 1.)
    pct = pct * pct * (3. - 2. * pct)
    return RGBA(first.r * (1. - pct) + second.r * pct,
                first.g * (1. - pct) + second.g * pct,
                first.b * (1. - pct) + second.b * pct,
                first.a * (1. - pct) + second.a * pct)

cdef class RGBA:
    #cdef public float r,g,b,a
    def __cinit__(self,r=1,g=1,b=1,a=1):
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    def __init__(self,r=1,g=1,b=1,a=1):
        pass

    def __getitem__(self,idx):
        if isinstance(idx,slice):
            return (self.r,self.g,self.b,self.a)[idx]
        else:
            if idx==0:
                return self.r
            elif idx==1:
                return self.g
            elif idx==2:
                return self.b
            elif idx==3:
                return self.a

            raise IndexError()

    def __setitem__(self,idx,obj):
        if isinstance(idx,slice):
            t = [self.r,self.g,self.b,self.a]
            t[idx] = obj
            self.r,self.g,self.b,self.a = t
        else:
            raise IndexError()

    def as_tuple(self):
        return (self.r, self.g, self.b, self.a)

basic_shader = None
simple_pt_shader = None
progress_shader = None
tooltip_shader = None
simple_yuv422_shader = None
simple_circle_shader = None
rounded_rect_shader = None

cpdef init():
    global basic_shader
    global simple_pt_shader
    global progress_shader
    global tooltip_shader
    global simple_yuv422_shader
    global simple_circle_shader
    global rounded_rect_shader
    basic_shader = None
    simple_pt_shader = None
    progress_shader = None
    tooltip_shader = None
    simple_yuv422_shader = None
    simple_circle_shader = None
    rounded_rect_shader = None

    if glewInit() != GLEW_OK:
        raise Exception("GLEW could not be initialized!")
    if not glewIsSupported("GL_VERSION_2_1"):
        raise Exception("This OpenGL context is below 2.1.")

    init_basic_shader()

cdef init_basic_shader():
    global basic_shader # we cache the shader because we only create it the first time we call this fn.
    if not basic_shader:

        VERT_SHADER = """
        #version 120
        attribute vec3 vertex;

        void main () {
               gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex,1.);
               }
        """

        FRAG_SHADER = """
        #version 120
        uniform vec4 color;
        void main()
        {
            gl_FragColor = color;
        }
        """

        GEOM_SHADER = """"""
        #shader link and compile
        basic_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)


cpdef draw_points(points,float size=20,RGBA color=RGBA(1.,0.5,0.5,.5),float sharpness=0.8):
    global simple_pt_shader # we cache the shader because we only create it the first time we call this fn.
    if not simple_pt_shader:

        VERT_SHADER = """
        #version 120
        varying vec4 f_color;
        uniform float size = 20;
        uniform float sharpness = 0.8;

        void main () {
               gl_Position = gl_ModelViewProjectionMatrix*vec4(gl_Vertex.xyz,1.);
               gl_PointSize = size;
               f_color = gl_Color;
               }
        """

        FRAG_SHADER = """
        #version 120
        varying vec4 f_color;
        uniform float size = 20;
        uniform float sharpness = 0.8;
        void main()
        {
            float dist = distance(gl_PointCoord.xy, vec2(0.5, 0.5))*size;
            gl_FragColor = mix(f_color, vec4(f_color.rgb,0.0), smoothstep(sharpness*size*0.5, 0.5*size, dist));
        }
        """

        GEOM_SHADER = """"""
        #shader link and compile
        simple_pt_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)

    simple_pt_shader.bind()
    simple_pt_shader.uniform1f('size',size)
    simple_pt_shader.uniform1f('sharpness',sharpness)
    glColor4f(color.r,color.g,color.b,color.a)
    glBegin(GL_POINTS)
    for pt in points:
        if len(pt) == 2:
            for pt in points:
                glVertex2f(pt[0],pt[1])
        else:
            for pt in points:
                glVertex3f(pt[0],pt[1],pt[2])
        break
    glEnd()
    simple_pt_shader.unbind()

cpdef draw_progress(location, float start, float stop, float inner_radius=15., float outer_radius=20.0, RGBA color=RGBA(1., 0.5, 0.5, .5), float sharpness=0.8):
    global progress_shader
    if not progress_shader:
        VERT_SHADER = """
        #version 120
        varying vec4 f_color;
        uniform float inner_radius = 15.;
        uniform float outer_radius = 20.;
        uniform float sharpness = 0.8;
        uniform float start = 0.0;
        uniform float stop = 0.0;

        void main () {
               gl_Position = gl_ModelViewProjectionMatrix*vec4(gl_Vertex.xyz,1.);
               gl_PointSize = outer_radius;
               f_color = gl_Color;
               }
        """

        FRAG_SHADER = """
        #version 120
        #define PI 3.14159265359
        #define TWO_PI 6.28318530718
        varying vec4 f_color;
        uniform float inner_radius = 15.;
        uniform float outer_radius = 20.;
        uniform float sharpness = 0.8;
        uniform float start = 0.0;
        uniform float stop = 0.0;

        // Rotation matrix by 90deg or PI/2
        mat2 rot = mat2(0., -1., 1., 0.);

        void main()
        {
            float dist = distance(gl_PointCoord.xy, vec2(0.5))*outer_radius*2.0;
            vec2 vec_loc = rot * normalize(gl_PointCoord.xy - vec2(0.5));
            float rel_loc = (atan(vec_loc.y, vec_loc.x) + PI) / TWO_PI;
            float pct = 0.;

            if (stop > start) {
                pct = smoothstep(start-0.01, start, rel_loc) -
                      smoothstep(stop, stop+0.01, rel_loc);
            }
            else if (stop < start) {
                pct = smoothstep(start-0.01, start, rel_loc) +
                      1. - smoothstep(stop, stop+0.01, rel_loc);
            }

            pct *= smoothstep(inner_radius, inner_radius/sharpness, dist) -
                   smoothstep(sharpness*outer_radius, outer_radius, dist);
            gl_FragColor = mix(vec4(f_color.rgb,0.0), f_color, pct);
        }
        """

        GEOM_SHADER = """"""
        #shader link and compile
        progress_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)

    progress_shader.bind()
    progress_shader.uniform1f('inner_radius',inner_radius)
    progress_shader.uniform1f('outer_radius',outer_radius)
    progress_shader.uniform1f('sharpness',sharpness)
    progress_shader.uniform1f('start', start)
    progress_shader.uniform1f('stop', stop)
    glColor4f(color.r,color.g,color.b,color.a)
    glBegin(GL_POINTS)
    if len(location) == 2:
        glVertex2f(location[0], location[1])
    else:
        glVertex3f(location[0],location[1],location[2])
    glEnd()
    progress_shader.unbind()


cdef draw_tooltip(tip_location, text_size, padding=(0., 0.),
                   RGBA tooltip_color=RGBA(1., 1., 1., .8), float sharpness=0.95):
    global tooltip_shader
    if not tooltip_shader:
        VERT_SHADER = """
        #version 120
        varying vec4 f_color;
        uniform float tip_width = 20.;
        uniform float blur = 0.05;

        void main () {
            float xpos = gl_Vertex.x - tip_width/2.;
            gl_Position = gl_ModelViewProjectionMatrix*vec4(xpos, gl_Vertex.yz, 1.);
            gl_PointSize = tip_width;
            f_color = gl_Color;
        }
        """

        FRAG_SHADER = """
        #version 120
        varying vec4 f_color;
        uniform float tip_width = 20.;
        uniform float blur = 0.05;

        uniform vec2 tip_anchor = vec2(.66,.5);

        float f(in float x, vec2 a, vec2 b)
        {
            float m = (b.y - a.y)/(b.x - a.x);
            return m*x + (b.y - m*b.x);
        }

        void main()
        {
            vec2 uv = gl_PointCoord.xy;
            float bre = f(uv.x, tip_anchor, vec2(0.));
            float tre = f(uv.x, vec2(0., 1.), tip_anchor);
            float pct = smoothstep(bre-blur, bre, uv.y) -
                        smoothstep(tre, tre+blur, uv.y);
            gl_FragColor = mix(vec4(0.), f_color, pct);
        }
        """

        GEOM_SHADER = """"""
        #shader link and compile
        tooltip_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)

    cdef int tip_width = int(text_size[1] + 2. * padding[1])

    tooltip_shader.bind()
    tooltip_shader.uniform1f('tip_width', tip_width)
    tooltip_shader.uniform1f('blur', 1. - sharpness)
    glColor4f(tooltip_color.r,tooltip_color.g,tooltip_color.b,tooltip_color.a)

    glBegin(GL_POINTS)
    glVertex2f(tip_location[0], tip_location[1])
    glEnd()
    tooltip_shader.unbind()

    glBegin(GL_POLYGON)
    glVertex2f(tip_location[0] - tip_width,
               tip_location[1] + text_size[1] / 2. + padding[1])
    glVertex2f(tip_location[0] - tip_width - text_size[0] - 2. * padding[0],
               tip_location[1] + text_size[1] / 2. + padding[1])
    glVertex2f(tip_location[0] - tip_width - text_size[0] - 2. * padding[0],
               tip_location[1] - text_size[1] / 2. - padding[1])
    glVertex2f(tip_location[0] - tip_width,
               tip_location[1] - text_size[1] / 2. - padding[1])
    glEnd()

cpdef draw_circle( center_position = (0,0) ,float radius=20,float stroke_width= 2, RGBA color=RGBA(1.,0.5,0.5,0.5),float sharpness=0.8):

    global simple_circle_shader

    if not simple_circle_shader:
        VERT_SHADER = """
        #version 120

        uniform vec2 center_position; // position in screen coordinates
        uniform float radius;
        uniform vec4 color;
        uniform float stroke_width;
        varying float quadSize;
        void main () {

               quadSize = radius * 2.0;
               gl_Position =  gl_ModelViewProjectionMatrix * vec4( center_position + quadSize * 0.5 *  gl_Vertex.xy, 0.0, 1.0);
               gl_TexCoord[0] = gl_MultiTexCoord0;

               }
        """

        FRAG_SHADER = """
        #version 120
        uniform vec4 color;
        uniform float radius;
        uniform float sharpness;
        uniform float stroke_width;
        varying float quadSize;

        void main()
        {
            vec2 texCoord = gl_TexCoord[0].st ;
            float center_distance = distance(texCoord.xy, vec2(0.5, 0.5)) * quadSize; // in pixels

            if( center_distance <= radius ){
                float radius_distance = abs(center_distance - radius); // in pixels
                float factor = smoothstep(stroke_width, stroke_width*sharpness ,radius_distance ) * smoothstep(0.0 , stroke_width * (1.0-sharpness),  radius_distance )  ;
                gl_FragColor = mix(color, vec4(color.rgb,0.0), 1.0 - factor  );
            }else{
                gl_FragColor = vec4(0,0,0,0);
            }

        }
        """

        GEOM_SHADER = """"""
        #shader link and compile
        simple_circle_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)



    simple_circle_shader.bind()
    simple_circle_shader.uniform1f('radius', radius)
    simple_circle_shader.uniform1f('stroke_width', stroke_width)
    simple_circle_shader.uniformf('center_position', center_position )
    simple_circle_shader.uniform1f('sharpness',sharpness)
    simple_circle_shader.uniformf('color', color[:] )

    glBegin(GL_QUADS)
    glTexCoord2f(0.0, 1.0)
    glVertex2f(-0.5,-0.5)
    glTexCoord2f(1.0, 1.0)
    glVertex2f(0.5,-0.5)
    glTexCoord2f(1.0, 0.0)
    glVertex2f(0.5,0.5)
    glTexCoord2f(0.0, 0.0)
    glVertex2f(-0.5,0.5)
    glEnd()


    simple_circle_shader.unbind()


cpdef draw_rounded_rect(origin, size, float corner_radius, RGBA color=RGBA(1.,0.5,0.5,.5), float sharpness=0.8):
    global rounded_rect_shader
    if not rounded_rect_shader:
        VERT_SHADER = """
        #version 120

        varying vec4 f_color;
        uniform vec2 origin; // position in screen coordinates
        uniform vec2 size; // size in screen coordinates
        uniform float corner_radius = 10;
        uniform float sharpness = 0.9;

        void main () {
            f_color = gl_Color;
            gl_Position =  gl_ModelViewProjectionMatrix * vec4(gl_Vertex.xy, 0.0, 1.0);
            gl_TexCoord[0] = gl_MultiTexCoord0;
        }
        """

        FRAG_SHADER = """
        #version 120

        varying vec4 f_color;
        uniform vec2 origin; // position in screen coordinates
        uniform vec2 size; // size in screen coordinates
        uniform float corner_radius = 10;
        uniform float sharpness = 0.9;
        float blur = min(size.y * (1. - sharpness), corner_radius);

        void main()
        {
            vec2 uv = gl_TexCoord[0].st - origin;

            float dist;
            gl_FragColor = f_color;
            if (uv.x <= corner_radius && uv.y <= corner_radius) {
                float dist = distance(uv, vec2(corner_radius));
                gl_FragColor.w *= smoothstep(corner_radius, corner_radius - blur, dist);
            }
            else if (uv.x <= corner_radius && uv.y >= size.y - corner_radius) {
                float dist = distance(uv, vec2(corner_radius, size.y - corner_radius));
                gl_FragColor.w *= smoothstep(corner_radius, corner_radius - blur, dist);
            }
            else if (uv.x >= size.x - corner_radius && uv.y >= size.y - corner_radius) {
                float dist = distance(uv, vec2(size.x - corner_radius, size.y - corner_radius));
                gl_FragColor.w *= smoothstep(corner_radius, corner_radius - blur, dist);
            }
            else if (uv.x >= size.x - corner_radius && uv.y <= corner_radius) {
                float dist = distance(uv, vec2(size.x - corner_radius, corner_radius));
                gl_FragColor.w *= smoothstep(corner_radius, corner_radius - blur, dist);
            }
            else if (uv.x >= size.x - blur) {
                gl_FragColor.w = smoothstep(size.x, size.x - blur, uv.x);
            }
            else if (uv.y >= size.y - blur) {
                gl_FragColor.w = smoothstep(size.y, size.y - blur, uv.y);
            }
            else if (uv.x <= blur) {
                gl_FragColor.w = smoothstep(0., blur, uv.x);
            }
            else if (uv.y <= blur) {
                gl_FragColor.w = smoothstep(0., blur, uv.y);
            }
        }
        """

        GEOM_SHADER = """"""
        rounded_rect_shader = shader.Shader(VERT_SHADER,FRAG_SHADER,GEOM_SHADER)

    rounded_rect_shader.bind()
    glColor4f(color.r,color.g,color.b,color.a)
    rounded_rect_shader.uniform1f('corner_radius', corner_radius)
    rounded_rect_shader.uniform1f('sharpness', sharpness)
    rounded_rect_shader.uniformf('origin', origin)
    rounded_rect_shader.uniformf('size', size )

    top_right = origin[0] + size[0], origin[1]
    bot_right = origin[0] + size[0], origin[1] + size[1]
    bot_left = origin[0], origin[1] + size[1]

    glBegin(GL_QUADS)
    for x,y in (origin, top_right, bot_right, bot_left):
        glTexCoord2f(x, y)
        glVertex2f(x, y)
    glEnd()
    rounded_rect_shader.unbind()

cpdef draw_points_norm(points,float size=20,RGBA color=RGBA(1.,0.5,0.5,.5),float sharpness=0.8):

    glMatrixMode(GL_PROJECTION)
    glPushMatrix()
    glLoadIdentity()
    glOrtho(0, 1, 0, 1, -1, 1)  # gl coord convention
    glMatrixMode(GL_MODELVIEW)
    glPushMatrix()
    glLoadIdentity()

    draw_points(points,size,color,sharpness)

    glMatrixMode(GL_PROJECTION)
    glPopMatrix()
    glMatrixMode(GL_MODELVIEW)
    glPopMatrix()

cpdef draw_bars(verts, float height, float thickness=1,RGBA color=RGBA(1.,0.5,0.5,.5)):
    glColor4f(color.r,color.g,color.b,color.a)
    glLineWidth(thickness)
    glBegin(GL_LINES)
    for pt in verts:
        glVertex2f(pt[0],pt[1] - height/2)
        glVertex2f(pt[0],pt[1] + height/2)
    glEnd()

cpdef draw_bars_buffer(verts, float thickness=1,RGBA color=RGBA(1.,0.5,0.5,.5)):
    glColor4f(color.r,color.g,color.b,color.a)
    glLineWidth(thickness)
    cdef float[:] data = verts
    glEnableClientState(GL_VERTEX_ARRAY)
    glVertexPointer(2, GL_FLOAT, 0, &data[0])
    glDrawArrays (GL_LINES, 0, (verts.size)/2)

cpdef draw_x(verts, float width, float height, float thickness=1,RGBA color=RGBA(1.,0.5,0.5,.5)):
    glColor4f(color.r,color.g,color.b,color.a)
    glLineWidth(thickness)
    glBegin(GL_LINES)
    for pt in verts:
        # top left -> bot right
        glVertex2f(pt[0] - width/2, pt[1] - height/2)
        glVertex2f(pt[0] + width/2, pt[1] + height/2)
        # bot left -> top right
        glVertex2f(pt[0] - width/2, pt[1] + height/2)
        glVertex2f(pt[0] + width/2, pt[1] - height/2)
    glEnd()


cpdef draw_polyline(verts,float thickness=1,RGBA color=RGBA(1.,0.5,0.5,.5),line_type = GL_LINE_STRIP):
    glColor4f(color.r,color.g,color.b,color.a)
    glLineWidth(thickness)
    glBegin(line_type)
    for pt in verts:
        if len(pt) == 2:
            for pt in verts:
                glVertex2f(pt[0],pt[1])
        else:
            for pt in verts:
                glVertex3f(pt[0],pt[1],pt[2])
        break
    glEnd()

cpdef draw_polyline_norm(verts,float thickness=1,RGBA color=RGBA(1.,0.5,0.5,.5),line_type = GL_LINE_STRIP):
    glMatrixMode(GL_PROJECTION)
    glPushMatrix()
    glLoadIdentity()
    glOrtho(0, 1, 0, 1, -1, 1) # gl coord convention
    glMatrixMode(GL_MODELVIEW)
    glPushMatrix()
    glLoadIdentity()

    draw_polyline(verts,thickness,color,line_type)

    glMatrixMode(GL_PROJECTION)
    glPopMatrix()
    glMatrixMode(GL_MODELVIEW)
    glPopMatrix()


cdef class Sphere:
    ### OpenGL funtions for creating and drawing a sphere.
    def __cinit__(self):
        pass
    def __init__(self,resolution=10):
        cdef int doubleRes = resolution*2
        cdef float polarInc = np.pi/resolution
        cdef float azimInc = np.pi*2.0/doubleRes

        cdef vector[GLfloat] vertices
        cdef vector[GLuint] indices

        cdef float nx,ny,nz
        cdef float tr
        for i in range(0, resolution+1):

            tr = np.sin( np.pi-i * polarInc )
            ny = np.cos( np.pi-i * polarInc )

            for j in range(0, doubleRes+1):
                nx = tr * np.sin(j * azimInc)
                nz = tr * np.cos(j * azimInc)
                vertices.push_back(nx)
                vertices.push_back(ny)
                vertices.push_back(nz)

        nr = doubleRes+1
        for y in range(0,resolution ):
            for x in range(0,doubleRes+1 ):
                indices.push_back( y*nr + x )
                indices.push_back( (y+1)*nr + x )

        self.vertex_buffer_size = vertices.size() * sizeof(GLfloat)
        self.indices_amount = indices.size()
        self.index_buffer_size = indices.size() * sizeof(GLuint)

        glGenBuffers(1, &self.index_buffer_id)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_buffer_id)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.index_buffer_size, &indices[0], GL_STATIC_DRAW)

        glGenBuffers(1, &self.vertex_buffer_id)
        glBindBuffer(GL_ARRAY_BUFFER, self.vertex_buffer_id)
        glBufferData(GL_ARRAY_BUFFER, self.vertex_buffer_size, &vertices[0] , GL_STATIC_DRAW)

        glBindBuffer(GL_ARRAY_BUFFER,0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)

    def draw(self, color = RGBA(0.5,0.5,0,0.5), primitive_type = GL_LINE_STRIP):
        basic_shader.bind()
        basic_shader.uniformf('color', color[:] )

        glBindAttribLocation(basic_shader.handle , 0 , 'vertex')

        glBindBuffer(GL_ARRAY_BUFFER, self.vertex_buffer_id)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL )

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.index_buffer_id)
        glDrawElements(primitive_type, self.indices_amount , GL_UNSIGNED_INT,  NULL )

        glBindBuffer(GL_ARRAY_BUFFER, 0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
        glDisableVertexAttribArray(0)

        basic_shader.unbind()


    def __dealloc__(self):
        glDeleteBuffers(1,&self.index_buffer_id)
        glDeleteBuffers(1,&self.vertex_buffer_id)


cdef class Named_Texture:
    ### OpenGL funtions for creating, updating and drawing a texture.
    ### Using a Frame object to update.
    #cdef GLuint texture_id
    #cdef bint use_yuv_shader
    def __cinit__(self):
        pass
    def __init__(self):
        self.texture_id = create_named_texture()

    def update_from_ndarray(self,img):
        update_named_texture(self.texture_id,img)
        self.use_yuv_shader = False

    def update_from_yuv_buffer(self,yuv_buffer,width,height):
        update_named_texture_yuv422(self.texture_id,yuv_buffer,width,height)
        self.use_yuv_shader = True

    def draw(self,interpolation=True, quad=((0.,0.),(1.,0.),(1.,1.),(0.,1.)),alpha=1.0):
        if self.use_yuv_shader:
            draw_named_texture_yuv422(self.texture_id,interpolation,quad,alpha)
        else:
            draw_named_texture(self.texture_id,interpolation,quad,alpha)

    def __dealloc__(self):
        destroy_named_texture(self.texture_id)


cpdef GLuint create_named_texture():
    cdef GLuint texture_id = 0
    glGenTextures(1, &texture_id)
    return texture_id

cpdef destroy_named_texture(int texture_id):
    cdef GLuint texture_cid = texture_id
    glDeleteTextures(1,&texture_cid)

cpdef update_named_texture_yuv422(texture_id, unsigned char[::1] imageData, width, height):

    glBindTexture(GL_TEXTURE_2D, texture_id)
    glPixelStorei(GL_UNPACK_ALIGNMENT,1)
    # Create Texture and upload data
    glTexImage2D(GL_TEXTURE_2D,
                    0,
                    GL_LUMINANCE,
                    width ,
                    height * 2, # take the sampling in to account
                    0,
                    GL_LUMINANCE,
                    GL_UNSIGNED_BYTE,
                    <void*>&imageData[0])
    glBindTexture(GL_TEXTURE_2D, 0)

cpdef draw_named_texture_yuv422(texture_id , interpolation=True, quad=((0.,0.),(1.,0.),(1.,1.),(0.,1.)),alpha=1.0 ):
    """
    We draw the image as a texture on a quad from 0,0 to img.width,img.height.
    We set the coord system to pixel dimensions.
    to save cpu power, update can be false and we will reuse the old img instead of uploading the new.
    """

    global simple_yuv422_shader
    if not simple_yuv422_shader:

        VERT_SHADER = """
            #version 120

            void main () {
                   gl_Position = gl_ModelViewProjectionMatrix*vec4(gl_Vertex.xyz,1.);
                   gl_TexCoord[0] = gl_MultiTexCoord0;
            }
            """

        FRAG_SHADER = """
            #version 120

            // texture sampler of the YUV422 image
            uniform sampler2D yuv422_image;

            float getYPixel(vec2 texCoord) {
              texCoord.y = texCoord.y / 2.0;
              return texture2D(yuv422_image, texCoord).x;
            }

            float getUPixel(vec2 position) {
                float x = position.x / 2.0;
                float y = position.y / 4.0 + 0.5;
                return texture2D(yuv422_image, vec2(x,y)).x;
            }

            float getVPixel(vec2 position) {
                float x = position.x / 2.0 ;
                float y = position.y / 4.0 + 0.75;
                return texture2D(yuv422_image, vec2(x,y)).x;
            }

            void main()
            {
                vec2 texCoord = gl_TexCoord[0].st;

                float yChannel = getYPixel(texCoord);
                float uChannel = getUPixel(texCoord);
                float vChannel = getVPixel(texCoord);

                // This does the colorspace conversion from Y'UV to RGB as a matrix
                // multiply.  It also does the offset of the U and V channels from
                // [0,1] to [-.5,.5] as part of the transform.
                vec4 channels = vec4(yChannel, uChannel, vChannel, 1.0);

                mat4 conversion = mat4(1.0,  0.0,    1.402, -0.701,
                                         1.0, -0.344, -0.714,  0.529,
                                         1.0,  1.772,  0.0,   -0.886,
                                         0, 0, 0, 0);

                vec3 rgb = (channels * conversion).xyz;
                gl_FragColor = vec4(rgb, 1.0);
            }
            """

        simple_yuv422_shader = shader.Shader(VERT_SHADER, FRAG_SHADER, "")


    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, texture_id)
    glEnable(GL_TEXTURE_2D)

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST) # interpolation here
    if not interpolation:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    simple_yuv422_shader.bind()
    simple_yuv422_shader.uniform1i("yuv422_image", 0)

    # someday replace with this:
    # glEnableClientState(GL_VERTEX_ARRAY)
    # glEnableClientState(GL_TEXTURE_COORD_ARRAY)
    # Varray = numpy.array([[0,0],[0,1],[1,1],[1,0]],numpy.float)
    # glVertexPointer(2,GL_FLOAT,0,Varray)
    # glTexCoordPointer(2,GL_FLOAT,0,Varray)
    # indices = [0,1,2,3]
    # glDrawElements(GL_QUADS,1,GL_UNSIGNED_SHORT,indices)
    glColor4f(1.0,1.0,1.0,alpha)
    # Draw textured Quad.
    glBegin(GL_QUADS)
    # glTexCoord2f(0.0, 0.0)
    glTexCoord2f(0.0, 1.0)
    glVertex2f(quad[0][0],quad[0][1])
    glTexCoord2f(1.0, 1.0)
    glVertex2f(quad[1][0],quad[1][1])
    glTexCoord2f(1.0, 0.0)
    glVertex2f(quad[2][0],quad[2][1])
    glTexCoord2f(0.0, 0.0)
    glVertex2f(quad[3][0],quad[3][1])
    glEnd()

    simple_yuv422_shader.unbind()

    glBindTexture(GL_TEXTURE_2D, 0)
    glDisable(GL_TEXTURE_2D)



cpdef update_named_texture(texture_id, image):
    cdef unsigned char[:,:,:] data_3
    cdef unsigned char[:,:] data_1

    glBindTexture(GL_TEXTURE_2D, texture_id)

    if len(image.shape) == 2:
        height, width = image.shape
        channels = 1
        data_1 = image

    else:
        height, width, channels = image.shape
        data_3 = image

    gl_blend = (None,GL_LUMINANCE,None,GL_BGR,GL_BGRA)[channels]
    gl_blend_init = (None,GL_LUMINANCE,None,GL_RGB,GL_RGBA)[channels]

    glPixelStorei(GL_UNPACK_ALIGNMENT,1)
    # Create Texture and upload data
    if channels ==1:
        glTexImage2D(GL_TEXTURE_2D,
                        0,
                        gl_blend_init,
                        width,
                        height,
                        0,
                        gl_blend,
                        GL_UNSIGNED_BYTE,
                        <void*>&data_1[0,0])
    else:
        glTexImage2D(GL_TEXTURE_2D,
                        0,
                        gl_blend_init,
                        width,
                        height,
                        0,
                        gl_blend,
                        GL_UNSIGNED_BYTE,
                        <void*>&data_3[0,0,0])

    glBindTexture(GL_TEXTURE_2D, 0)


cpdef draw_named_texture(texture_id, interpolation=True, quad=((0.,0.),(1.,0.),(1.,1.),(0.,1.)),alpha=1.0):
    """
    We draw the image as a texture on a quad from 0,0 to img.width,img.height.
    We set the coord system to pixel dimensions.
    to save cpu power, update can be false and we will reuse the old img instead of uploading the new.
    """

    glBindTexture(GL_TEXTURE_2D, texture_id)
    glEnable(GL_TEXTURE_2D)

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST) # interpolation here
    if not interpolation:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    # someday replace with this:
    # glEnableClientState(GL_VERTEX_ARRAY)
    # glEnableClientState(GL_TEXTURE_COORD_ARRAY)
    # Varray = numpy.array([[0,0],[0,1],[1,1],[1,0]],numpy.float)
    # glVertexPointer(2,GL_FLOAT,0,Varray)
    # glTexCoordPointer(2,GL_FLOAT,0,Varray)
    # indices = [0,1,2,3]
    # glDrawElements(GL_QUADS,1,GL_UNSIGNED_SHORT,indices)
    glColor4f(1.0,1.0,1.0,alpha)
    # Draw textured Quad.
    glBegin(GL_QUADS)
    # glTexCoord2f(0.0, 0.0)
    glTexCoord2f(0.0, 1.0)
    glVertex2f(quad[0][0],quad[0][1])
    glTexCoord2f(1.0, 1.0)
    glVertex2f(quad[1][0],quad[1][1])
    glTexCoord2f(1.0, 0.0)
    glVertex2f(quad[2][0],quad[2][1])
    glTexCoord2f(0.0, 0.0)
    glVertex2f(quad[3][0],quad[3][1])
    glEnd()

    glBindTexture(GL_TEXTURE_2D, 0)
    glDisable(GL_TEXTURE_2D)


def draw_gl_texture(image,interpolation=True,alpha=1.0):
    """
    We draw the image as a texture on a quad from 0,0 to img.width,img.height.
    Simple anaymos texture one time use. Look at named texture fn's for better perfomance
    """
    cdef unsigned char[:,:,:] data_3
    cdef unsigned char[:,:] data_1
    if len(image.shape) == 2:
        height, width = image.shape
        channels = 1
        data_1 = image
    else:
        height, width, channels = image.shape
        if channels == 1:
            data_1 = image
        else:
            data_3 = image

    gl_blend = (None,GL_LUMINANCE,None,GL_BGR,GL_BGRA)[channels]
    gl_blend_init = (None,GL_LUMINANCE,None,GL_RGB,GL_RGBA)[channels]

    glPixelStorei(GL_UNPACK_ALIGNMENT,1)
    glEnable(GL_TEXTURE_2D)
    # Create Texture and upload data
    if channels == 1:
        glTexImage2D(GL_TEXTURE_2D,
                        0,
                        gl_blend_init,
                        width,
                        height,
                        0,
                        gl_blend,
                        GL_UNSIGNED_BYTE,
                        <void*>&data_1[0,0])
    else:
        glTexImage2D(GL_TEXTURE_2D,
                        0,
                        gl_blend_init,
                        width,
                        height,
                        0,
                        gl_blend,
                        GL_UNSIGNED_BYTE,
                        <void*>&data_3[0,0,0])

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST) # interpolation here
    if not interpolation:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);


    glColor4f(1.0,1.0,1.0,alpha)
    # Draw textured Quad.
    glBegin(GL_QUADS)
    glTexCoord2f(0.0, 1.0)
    glVertex2f(0,0)
    glTexCoord2f(1.0, 1.0)
    glVertex2f(1,0)
    glTexCoord2f(1.0, 0.0)
    glVertex2f(1,1)
    glTexCoord2f(0.0, 0.0)
    glVertex2f(0,1)
    glEnd()

    glDisable(GL_TEXTURE_2D)



cdef class Render_Target:
    ### OpenGL funtions for rendering to texture.
    ### Using this saves us considerable cpu/gpu time when the UI remains static.
    #cdef fbo_tex_id fbo_tex defined in .pxd
    def __cinit__(self,w,h):
        pass
    def __init__(self,w,h):
        self.fbo_tex = create_ui_texture(w,h)

    def push(self):
        render_to_ui_texture(self.fbo_tex)

    def pop(self):
        render_to_screen()

    def draw(self,float alpha=1.0):
        draw_ui_texture(self.fbo_tex,alpha)

    def resize(self,int w, int h):
        resize_ui_texture(self.fbo_tex,w,h)

    def __dealloc__(self):
        destroy_ui_texture(self.fbo_tex)

### OpenGL funtions for rendering to texture.
### Using this saves us considerable cpu/gpu time when the UI remains static.

cdef fbo_tex_id create_ui_texture(int w,int h):
    cdef fbo_tex_id ui_layer
    ui_layer.fbo_id = 0
    ui_layer.tex_id = 0

    # create Framebufer Object
    #requires gl ext or opengl > 3.0
    glGenFramebuffers(1, &ui_layer.fbo_id)
    glBindFramebuffer(GL_FRAMEBUFFER, ui_layer.fbo_id)

    #create texture object
    glGenTextures(1, &ui_layer.tex_id)
    glBindTexture(GL_TEXTURE_2D, ui_layer.tex_id)
    # configure Texture
    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, w,
                    h, 0,GL_RGBA, GL_UNSIGNED_BYTE,
                    NULL)
    #set filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    #attach texture to fbo
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                GL_TEXTURE_2D, ui_layer.tex_id, 0)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        raise Exception("UI Framebuffer could not be created.")

    #unbind fbo and texture
    glBindTexture(GL_TEXTURE_2D, 0)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

    return ui_layer

cdef destroy_ui_texture(fbo_tex_id ui_layer):
    glDeleteTextures(1,&ui_layer.tex_id)
    glDeleteFramebuffers(1,&ui_layer.fbo_id)

cdef resize_ui_texture(fbo_tex_id ui_layer, int w,int h):
    glBindTexture(GL_TEXTURE_2D, ui_layer.tex_id)
    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, w,
                    h, 0,GL_RGBA, GL_UNSIGNED_BYTE,
                    NULL)
    glBindTexture(GL_TEXTURE_2D, 0)


cdef render_to_ui_texture(fbo_tex_id ui_layer):
    # set fbo as render target
    # blending method after:
    # http://stackoverflow.com/questions/24346585/opengl-render-to-texture-with-partial-transparancy-translucency-and-then-rende/24380226#24380226
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,
                                GL_ONE_MINUS_DST_ALPHA, GL_ONE)
    glBindFramebuffer(GL_FRAMEBUFFER, ui_layer.fbo_id)
    glClearColor(0.,0.,0.,0.)
    glClear(GL_COLOR_BUFFER_BIT)


cdef render_to_screen():
    # set rendertarget 0
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

cdef draw_ui_texture(fbo_tex_id ui_layer,float alpha = 1.0):
    # render texture

    # set blending
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)

    # bind texture and use.
    glBindTexture(GL_TEXTURE_2D, ui_layer.tex_id)
    glEnable(GL_TEXTURE_2D)

    #set up coord system
    glMatrixMode(GL_PROJECTION)
    glPushMatrix()
    glLoadIdentity()
    glOrtho(0, 1, 1, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glPushMatrix()
    glLoadIdentity()

    glColor4f(alpha,alpha,alpha,alpha)
    # Draw textured Quad.
    glBegin(GL_QUADS)
    glTexCoord2f(0.0, 1.0)
    glVertex2f(0,0)
    glTexCoord2f(1.0, 1.0)
    glVertex2f(1,0)
    glTexCoord2f(1.0, 0.0)
    glVertex2f(1,1)
    glTexCoord2f(0.0, 0.0)
    glVertex2f(0,1)
    glEnd()

    #pop coord systems
    glMatrixMode(GL_PROJECTION)
    glPopMatrix()
    glMatrixMode(GL_MODELVIEW)
    glPopMatrix()

    glBindTexture(GL_TEXTURE_2D, 0)
    glDisable(GL_TEXTURE_2D)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)


cpdef push_ortho(int w,int h):
    glMatrixMode(GL_PROJECTION)
    glPushMatrix()
    glLoadIdentity()
    glOrtho(0, w,h, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glPushMatrix()
    glLoadIdentity()

cpdef pop_ortho():
    glMatrixMode(GL_PROJECTION)
    glPopMatrix()
    glMatrixMode(GL_MODELVIEW)
    glPopMatrix()
