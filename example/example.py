
import logging
from glfw import *
from OpenGL.GL import *

import numpy as np
# create logger for the context of this function
logger = logging.getLogger(__name__)

import time
import uvc
from pyglui import ui
from pyglui.cygl.utils import init
from pyglui.cygl.utils import RGBA
from pyglui.cygl.utils import create_named_texture, destroy_named_texture, update_named_texture, draw_named_texture
from pyglui.cygl.utils import create_named_yuv422_texture, update_named_yuv422_texture, draw_named_yuv422_texture
from pyglui.pyfontstash import fontstash as fs
from pyglui.cygl.shader import Shader


width, height = (1280,720)



def basic_gl_setup():
    glEnable(GL_POINT_SPRITE )
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE) # overwrite pointsize
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_BLEND)
    glClearColor(.8,.8,.8,1.)
    glEnable(GL_LINE_SMOOTH)
    # glEnable(GL_POINT_SMOOTH)
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
    glEnable(GL_LINE_SMOOTH)
    glEnable(GL_POLYGON_SMOOTH)
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)


def adjust_gl_view(w,h,window):
    """
    adjust view onto our scene.
    """

    glViewport(0, 0, w, h)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, w, h, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()



def clear_gl_screen():
    glClearColor(.9,.9,0.9,1.)
    glClear(GL_COLOR_BUFFER_BIT)


def demo():
    global quit
    quit = False

    # Callback functions
    def on_resize(window,w, h):
        h = max(h,1)
        w = max(w,1)
        hdpi_factor = glfwGetFramebufferSize(window)[0]/glfwGetWindowSize(window)[0]
        w,h = w*hdpi_factor,h*hdpi_factor
        active_window = glfwGetCurrentContext()
        glfwMakeContextCurrent(window)
        # norm_size = normalize((w,h),glfwGetWindowSize(window))
        # fb_size = denormalize(norm_size,glfwGetFramebufferSize(window))
        adjust_gl_view(w,h,window)
        glfwMakeContextCurrent(active_window)


    def on_iconify(window,iconfied):
        pass

    def on_key(window, key, scancode, action, mods):

        if action == GLFW_PRESS:
            if key == GLFW_KEY_ESCAPE:
                on_close(window)


    def on_close(window):
        global quit
        quit = True
        logger.info('Process closing from window')


    # get glfw started
    glfwInit()

    window = glfwCreateWindow(width, height, "pyglui demo", None, None)
    if not window:
        exit()

    glfwSetWindowPos(window,0,0)
    # Register callbacks window
    glfwSetWindowSizeCallback(window,on_resize)
    glfwSetWindowCloseCallback(window,on_close)
    glfwSetWindowIconifyCallback(window,on_iconify)
    glfwSetKeyCallback(window,on_key)

    glfwMakeContextCurrent(window)
    init()
    basic_gl_setup()

    print glGetString(GL_VERSION)

    class Temp(object):
        """Temp class to make objects"""
        def __init__(self):
            pass

    foo = Temp()
    foo.bar = 34
    foo.bur = 4
    foo.mytext = [203,12]
    foo.myswitch = 10
    foo.select = 'Tiger'
    foo.record = False
    foo.calibrate = False
    foo.stream = True
    foo.test = False


    d = {}

    d['one'] = 1
    def print_hello():
        foo.select = 'Cougar'
        gui.scale += .1
        print 'hello'

        # m.configuration = sidebar.configuration

    def printer(val):
        print 'setting to :',val


    print "pyglui version: %s" %(ui.__version__)

    import os
    import psutil
    pid = os.getpid()
    ps = psutil.Process(pid)
    ts = time.time()

    from pyglui import graph
    print graph.__version__
    cpu_g = graph.Line_Graph()
    cpu_g.pos = (50,100)
    cpu_g.update_fn = ps.cpu_percent
    cpu_g.update_rate = 5
    cpu_g.label = 'CPU %0.1f'

    fps_g = graph.Line_Graph()
    fps_g.pos = (50,100)
    fps_g.update_rate = 5
    fps_g.label = "%0.0f FPS"
    fps_g.color[:] = .1,.1,.8,.9

    on_resize(window,*glfwGetWindowSize(window))

    dev_list =  uvc.device_list()
    print dev_list
    if not dev_list:
        return
    cap = uvc.Capture(dev_list[0]['uid'])
    cap.frame_size = 1280,720
    frame = cap.get_frame_robust()

    rgb_tex = create_named_texture(frame.img.shape)
    yuv_tex  = create_named_yuv422_texture( (frame.width, frame.height ) )



    while not quit:
        dt,ts = time.time()-ts,time.time()
        clear_gl_screen()

        frame = cap.get_frame_robust()
        #draw rgb image
        update_named_texture(rgb_tex, frame.img)
        draw_named_texture( rgb_tex, quad  =((0.,0.),(1280./2,0.),(1280./2,720./2),(0.,720./2)))

        #draw yuv422 image
        update_named_yuv422_texture( yuv_tex, frame.yuv_buffer, frame.width, frame.height )
        draw_named_yuv422_texture( yuv_tex,  quad  =((700 + 0.,0.),(700 +1280./2,0.),(700 +1280./2,720./2),(700 +0.,720./2)))

        cpu_g.update()
        cpu_g.draw()
        fps_g.add(1./dt)
        fps_g.draw()

        glfwSwapBuffers(window)
        glfwPollEvents()

    glfwDestroyWindow(window)
    glfwTerminate()
    logger.debug("Process done")

if __name__ == '__main__':
    if 1:
        demo()
    else:
        import cProfile,subprocess,os
        cProfile.runctx("demo()",{},locals(),"example.pstats")
        gprof2dot_loc = 'gprof2dot.py'
        subprocess.call("python "+gprof2dot_loc+" -f pstats example.pstats | dot -Tpng -o example_profile.png", shell=True)
        print "created cpu time graph for example. Please check out the png next to this."
