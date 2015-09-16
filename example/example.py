
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
from pyglui.cygl.utils import draw_concentric_circles
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

    while not quit:
        dt,ts = time.time()-ts,time.time()
        clear_gl_screen()


        draw_concentric_circles( (500,250), 200, 6 , 1.0 )
        draw_concentric_circles( (600,250), 200, 7 , 1.0 )
        draw_concentric_circles( (700,250), 200, 8 , 0.1 )



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
