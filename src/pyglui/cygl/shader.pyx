from cpython.version cimport PY_MAJOR_VERSION

cimport pyglui.cygl.glew as gl


cdef str _to_str(object s):
    if PY_MAJOR_VERSION > 2:
        if type(s) is unicode:
            return s
        elif type(s) is bytearray:
            return s.decode('utf-8')
        else:
            return (<bytes>s).decode('utf-8')
    else:
        if type(s) is unicode:
            return s.encode('utf-8')
        else:
            return str(s)

cdef bytes _to_utf8_bytes(object s):
    if type(s) is unicode:
        return (<unicode>s).encode('utf-8')
    else:
        return <bytes>s


cdef class Shader:
    ''' Base shader class. '''

    def __cinit__(self, vertex_code = None, fragment_code = None, geometry_code = None):
        pass

    def __init__(self, vertex_code = None, fragment_code = None, geometry_code = None):
        '''
        Compile and link vertex code and fragment code into a shader.

        :Parameters:
            ``vertex_code``: string
                Vertex code

            ``fragment_code``: string
                Fragment code

            ``geometry_code``: string
                Geometry code
        '''

        self.uniforms = {}
        self._vertex_code = _to_utf8_bytes(vertex_code)
        self._fragment_code = _to_utf8_bytes(fragment_code)
        self._geometry_code = _to_utf8_bytes(geometry_code)

        # create the program handle
        self.handle = gl.glCreateProgram()

        # we are not linked yet
        self.linked = False

        # create the vertex shader
        self._build_shader(self._vertex_code, gl.GL_VERTEX_SHADER)

        # create the fragment shader
        self._build_shader(self._fragment_code, gl.GL_FRAGMENT_SHADER)

        # create the geometry shader
        self._build_shader(self._geometry_code, gl.GL_GEOMETRY_SHADER)

        # link the program
        self._link()


    cdef _get_shader_info(self,gl.GLuint shader):
        cdef gl.GLint log_length = 0
        gl.glGetShaderiv(shader,gl.GL_INFO_LOG_LENGTH,&log_length)
        cdef bytearray log = bytearray(log_length)
        gl.glGetShaderInfoLog(shader, log_length, NULL, log)
        return _to_str(log)


    cdef _get_program_info(self):
        cdef gl.GLint log_length = 0
        gl.glGetProgramiv(self.handle,gl.GL_INFO_LOG_LENGTH,&log_length)
        cdef bytearray log = bytearray(log_length)
        gl.glGetProgramInfoLog(self.handle, log_length, NULL, log)
        return log


    cdef _build_shader(self, const char * strings, shader_type):
        ''' Actual building of the shader '''

        count = len(strings)
        # if we have no source code, ignore this shader
        if count < 1:
            return

        # create the shader handle
        cdef gl.GLuint shader = gl.glCreateShader(shader_type)


        # Upload shader code we just have one string
        #void glShaderSource(GLhandle shaderObj, GLsizei count, const GLchar* const *string, const GLint *length)
        gl.glShaderSource(shader,1, &strings, NULL)

        # compile the shader
        gl.glCompileShader(shader)

        # retrieve the compile status
        cdef gl.GLint status = 0
        gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, &status)

        # if compilation failed, raise exception and print the log
        if not status:
            if shader_type == gl.GL_VERTEX_SHADER:
                raise Exception('Vertex compilation: ' + self._get_shader_info(shader))
            elif shader_type == gl.GL_FRAGMENT_SHADER:
                raise Exception('Fragment compilation: ' + self._get_shader_info(shader))
            elif shader_type == gl.GL_GEOMETRY_SHADER:
                raise Exception('Geometry compilation: ' + self._get_shader_info(shader))
            else:
                raise Exception(self._get_shader_info(shader))
        else:
            # all is well, so attach the shader to the program
            gl.glAttachShader(self.handle, shader)

    cdef _link(self):
        ''' Link the program '''

        gl.glLinkProgram(self.handle)
        # retrieve the link status
        cdef gl.GLint status = 0
        gl.glGetProgramiv(self.handle, gl.GL_LINK_STATUS, &status)

        # if linking failed, print the log
        if not status:
            raise Exception('Linking: '+ self._get_program_info())
        else:
            # all is well, so we are linked
            self.linked = True

    cpdef bind(self):
        ''' Bind the program, i.e. use it. '''
        gl.glUseProgram(self.handle)

    cpdef unbind(self):
        ''' Unbind whatever program is currently bound - not necessarily this
            program, so this should probably be a class method instead. '''
        gl.glUseProgram(0)

    cpdef uniformf(self, str name, vals):
        ''' Uploads float uniform(s), program must be currently bound. '''

        loc = self.uniforms.get(name, gl.glGetUniformLocation(self.handle, _to_utf8_bytes(name)))
        #if loc < 0:
        #    raise ShaderException, \
        #        '''Unknow uniform location '%s' ''' % name
        self.uniforms[name] = _to_utf8_bytes(loc)

        cdef int val_len = len(vals)

        if val_len == 1:
            gl.glUniform1f(loc, vals[0])
        elif val_len ==2:
            gl.glUniform2f(loc, vals[0],vals[1])
        elif val_len ==3:
            gl.glUniform3f(loc, vals[0],vals[1],vals[2])
        elif val_len ==4:
            gl.glUniform4f(loc, vals[0],vals[1],vals[2],vals[3])

    cpdef uniform1f(self, str name, float val):
        ''' Upload float uniform, program must be currently bound. '''

        loc = self.uniforms.get(name, gl.glGetUniformLocation(self.handle, _to_utf8_bytes(name)))
        if loc < 0:
            raise Exception("Unknow uniform location '{}'".format(name))
        self.uniforms[name] = _to_utf8_bytes(loc)
        gl.glUniform1f(loc, val)

    cpdef uniform1i(self, str name, int val):
        ''' Upload integer uniform, program must be currently bound. '''

        loc = self.uniforms.get(name, gl.glGetUniformLocation(self.handle, _to_utf8_bytes(name)))
        if loc < 0:
            raise Exception("Unknow uniform location '{}'".format(name))
        self.uniforms[name] = loc
        gl.glUniform1i(loc, val)

    cpdef uniformi(self, str name, vals):
        ''' Upload integer uniform(s), program must be currently bound. '''

        loc = self.uniforms.get(name, gl.glGetUniformLocation(self.handle, _to_utf8_bytes(name)))
        #if loc < 0:
        #    raise ShaderException, \
        #        '''Unknow uniform location '%s' ''' % name
        self.uniforms[name] = loc

        cdef int val_len = len(vals)
        if val_len == 1:
            gl.glUniform1i(loc, vals[0])
        elif val_len ==2:
            gl.glUniform2i(loc, vals[0],vals[1])
        elif val_len ==3:
            gl.glUniform3i(loc, vals[0],vals[1],vals[2])
        elif val_len ==4:
            gl.glUniform4i(loc, vals[0],vals[1],vals[2],vals[3])


    cpdef uniform_matrixf(self, str name, float[:] mat):
        ''' Upload uniform matrix, program must be currently bound. '''

        loc = self.uniforms.get(name, gl.glGetUniformLocation(self.handle,_to_utf8_bytes(name)))
        #if loc < 0:
        #    raise ShaderException, \
        #        '''Unknow uniform location '%s' ''' % name
        self.uniforms[name] = loc

        # Upload the 4x4 floating point matrix
        gl.glUniformMatrix4fv(loc, 1, False, &mat[0])


    def get_vertex_code(self, lineno=True):
        code = ''
        for lineno, line in enumerate(_to_str(self._vertex_code).split('\n')):
            code += '{:3d}: {}\n'.format(lineno+1, line)
        return code

    def get_fragment_code(self,lineno=True):
        code = ''
        for lineno,line in enumerate(_to_str(self._fragment_code).split('\n')):
            code += '{:3d}: {}\n'.format(lineno+1, line)
        return code

    def get_geometry_code(self,lineno=True):
        code = ''
        for lineno,line in enumerate(_to_str(self._geometry_code).split('\n')):
            code += '{:3d}: {}\n'.format(lineno+1, line)
        return code
