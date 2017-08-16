# -*- coding: utf-8 -*-
from __future__ import print_function
import logging

from glfw import *
from OpenGL.GL import *

import numpy as np
# create logger for the context of this function
logger = logging.getLogger(__name__)

import time
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
    print(w,h)
    glViewport(0, 0, int(w), int(h))
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, w, h, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()




def demo():
    global quit
    quit = False

    # Callback functions
    def on_resize(window,w, h):
        h = max(h,1)
        w = max(w,1)
        hdpi_factor = glfwGetFramebufferSize(window)[0]/glfwGetWindowSize(window)[0]
        w,h = w*hdpi_factor,h*hdpi_factor
        gui.update_window(w,h)
        active_window = glfwGetCurrentContext()
        glfwMakeContextCurrent(active_window)
        # norm_size = normalize((w,h),glfwGetWindowSize(window))
        # fb_size = denormalize(norm_size,glfwGetFramebufferSize(window))
        adjust_gl_view(w,h,window)
        glfwMakeContextCurrent(active_window)


    def on_iconify(window,iconfied):
        pass

    def on_key(window, key, scancode, action, mods):
        gui.update_key(key,scancode,action,mods)

        if action == GLFW_PRESS:
            if key == GLFW_KEY_ESCAPE:
                on_close(window)
            if mods == GLFW_MOD_SUPER:
                if key == 67:
                    # copy value to system clipboard
                    # ideally copy what is in our text input area
                    test_val = "copied text input"
                    glfwSetClipboardString(window,test_val)
                    print("set clipboard to: %s" %(test_val))
                if key == 86:
                    # copy from system clipboard
                    clipboard = glfwGetClipboardString(window)
                    print("pasting from clipboard: %s" %(clipboard))


    def on_char(window,char):
        gui.update_char(char)

    def on_button(window,button, action, mods):
        gui.update_button(button,action,mods)
        # pos = normalize(pos,glfwGetWindowSize(window))
        # pos = denormalize(pos,(frame.img.shape[1],frame.img.shape[0]) ) # Position in img pixels

    def on_pos(window,x, y):
        hdpi_factor = float(glfwGetFramebufferSize(window)[0]/glfwGetWindowSize(window)[0])
        x,y = x*hdpi_factor,y*hdpi_factor
        gui.update_mouse(x,y)

    def on_scroll(window,x,y):
        gui.update_scroll(x,y)

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
    # Register callbacks for the window
    glfwSetWindowSizeCallback(window,on_resize)
    glfwSetWindowCloseCallback(window,on_close)
    glfwSetWindowIconifyCallback(window,on_iconify)
    glfwSetKeyCallback(window,on_key)
    glfwSetCharCallback(window,on_char)
    glfwSetMouseButtonCallback(window,on_button)
    glfwSetCursorPosCallback(window,on_pos)
    glfwSetScrollCallback(window,on_scroll)
    # test out new paste function

    glfwMakeContextCurrent(window)
    init()
    basic_gl_setup()

    print(glGetString(GL_VERSION))


    class Temp(object):
        """Temp class to make objects"""
        def __init__(self):
            pass

    foo = Temp()
    foo.bar = 34
    foo.sel = 'mi'
    foo.selection = ['€','mi', u"re"]

    foo.mytext = "some text"
    foo.T = True
    foo.L = False

    def set_text_val(val):
        foo.mytext = val
        # print 'setting to :',val

    def pr():
        print("pyglui version: %s" %(ui.__version__))

    gui = ui.UI()
    gui.scale = 1.0
    thumbbar = ui.Scrolling_Menu("ThumbBar",pos=(-80,0),size=(0,0),header_pos='hidden')
    menubar = ui.Scrolling_Menu("MenueBar",pos=(-500,0),size=(-90,0),header_pos='left')


    gui.append(menubar)
    gui.append(thumbbar)



    T = ui.Growing_Menu("T menu",header_pos='hidden')
    menubar.append(T)
    L = ui.Growing_Menu("L menu",header_pos='hidden')
    menubar.append(L)
    M = ui.Growing_Menu("M menu",header_pos='hidden')
    menubar.append(M)

    def toggle_menu(collapsed, menu):
        menubar.collapsed = collapsed
        for m in menubar.elements:
            m.collapsed = True
        menu.collapsed = collapsed


    thumbbar.append(ui.Thumb('collapsed',T,label='T',on_val=False, off_val=True,setter=lambda x:toggle_menu(x,T)))
    thumbbar.append(ui.Thumb('collapsed',L,label='L',on_val=False, off_val=True,setter=lambda x:toggle_menu(x,L)))
    thumbbar.append(ui.Thumb('collapsed',M,label='M',on_val=False, off_val=True,setter=lambda x:toggle_menu(x,M)))

    T.append(ui.Button("T test",pr))
    T.append(ui.Info_Text("T best finerfpiwnesdco'n wfo;ineqrfo;inwefo'qefr voijeqfr'p9qefrp'i 'iqefr'ijqfr eqrfiqerfn'ioer"))
    L.append(ui.Button("L test",pr))
    L.append(ui.Button("L best",pr))
    M.append(ui.Button("M test",pr))
    M.append(ui.Button("M best",pr))
    MM = ui.Growing_Menu("MM menu",pos=(0,0),size=(0,400))
    M.append(MM)
    for x in range(20):
        MM.append(ui.Button("M test%s"%x,pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    M.append(ui.Button("M best",pr))
    # label = 'Ï'
    # label = 'R'
    # gui.append(
    import os
    import psutil
    pid = os.getpid()
    ps = psutil.Process(pid)
    ts = time.time()


    from pyglui import graph
    print(graph.__version__)
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
        gui.update()
        # print(T.collapsed,L.collapsed,M.collapsed)
        # T.collapsed = True
        # glfwMakeContextCurrent(window)
        glfwSwapBuffers(window)
        glfwPollEvents()
        # adjust_gl_view(1280,720,window)
        glClearColor(.3,.4,.1,1)
        glClear(GL_COLOR_BUFFER_BIT)

    gui.terminate()
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
        print("created cpu time graph for example. Please check out the png next to this.")
