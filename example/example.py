import logging
from glfw import *
import OpenGL
from OpenGL.GL import *
import pyfontstash as fs

import numpy as np
# create logger for the context of this function
logger = logging.getLogger(__name__)

import time

width, height = (1000,600)


def basic_gl_setup():
    glEnable( GL_POINT_SPRITE )
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE) # overwrite pointsize
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_BLEND)
    glClearColor(.8,.8,.8,1.)
    glEnable(GL_LINE_SMOOTH)
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
    # glEnable(GL_POINT_SMOOTH)


def adjust_gl_view(w,h,window):
    """
    adjust view onto our scene.
    """
    h = max(h,1)
    w = max(w,1)

    hdpi_factor = glfwGetFramebufferSize(window)[0]/glfwGetWindowSize(window)[0]
    w,h = w*hdpi_factor,h*hdpi_factor
    glViewport(0, 0, w, h)



def clear_gl_screen():

    glClear(GL_COLOR_BUFFER_BIT)


def demo():
    global quit
    quit = False

    # Callback functions
    def on_resize(window,w, h):
        gui.update_window(w,h)
        active_window = glfwGetCurrentContext()
        glfwMakeContextCurrent(window)
        # norm_size = normalize((w,h),glfwGetWindowSize(window))
        # fb_size = denormalize(norm_size,glfwGetFramebufferSize(window))
        adjust_gl_view(w,h,window)
        glfwMakeContextCurrent(active_window)
        global width
        global height
        width,height = w,h

    def on_iconify(window,iconfied):
        pass

    def on_key(window, key, scancode, action, mods):
        gui.update_key(key,scancode,action,mods)

        if action == GLFW_PRESS:
            if key == GLFW_KEY_ESCAPE:
                on_close(window)

    def on_char(window,char):
        gui.update_char(char)

    def on_button(window,button, action, mods):
        gui.update_button(button,action,mods)
        # pos = normalize(pos,glfwGetWindowSize(window))
        # pos = denormalize(pos,(frame.img.shape[1],frame.img.shape[0]) ) # Position in img pixels

    def on_pos(window,x, y):
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
    glfwSetWindowPos(window,0,0)
    # Register callbacks window
    glfwSetWindowSizeCallback(window,on_resize)
    glfwSetWindowCloseCallback(window,on_close)
    glfwSetWindowIconifyCallback(window,on_iconify)
    glfwSetKeyCallback(window,on_key)
    glfwSetCharCallback(window,on_char)
    glfwSetMouseButtonCallback(window,on_button)
    glfwSetCursorPosCallback(window,on_pos)
    glfwSetScrollCallback(window,on_scroll)


    # glfwSwapInterval(0)
    glfwMakeContextCurrent(window)
    basic_gl_setup()

    class t(object):
        pass

    foo = t()
    foo.bar = 34
    foo.bur = 60
    foo.mytext = 'change me!'

    def print_hello():
        print 'hello'


    def printer(val):
        print 'setting to :',val


    from pyglui import ui
    gui = ui.UI()
    gui.update_window(width,height)
    m = ui.Menu("MySideBar",pos=(-200,20),size=(0,-20))
    s = ui.StackBox()

    for x in range(100):
        s.elements.append(ui.Slider("bar",foo,label="bar %s"%x))
        s.elements.append(ui.Slider("bur",foo,label="bur %s"%x))
        sm = ui.Menu("SubMenu",pos=(0,0),size=(0,100))
        ss= ui.StackBox()
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.TextInput('mytext',foo,setter=printer))
        sm.elements.append(ss)
        s.elements.append(sm)
        s.elements.append(ui.Button("Say Hi!",print_hello))
        s.elements.append(ui.Button("Say Hi!",print_hello))
        s.elements.append(ui.Button("Say Hi!",print_hello))
    m.elements.append(s)
    gui.elements.append(m)

    m = ui.Menu("MyMenu",pos=(400,-200),size=(300,150))
    s = ui.StackBox()
    for x in range(1):
        s.elements.append(ui.Slider("bur",foo,setter=printer))
        s.elements.append(ui.Button("Say Hi!",print_hello))
        s.elements.append(ui.Button("Say Hi!",print_hello))

        s.elements.append(ui.Button("Say Hi!",print_hello))
        sm = ui.Menu("SubMenu",pos=(0,0),size=(0,100))
        ss= ui.StackBox()
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.TextInput('mytext',foo,setter=printer))
        sm.elements.append(ss)
        s.elements.append(sm)
        s.elements.append(ui.Button("Say Hi!",print_hello))
        s.elements.append(ui.Button("Say Hi!",print_hello))
        s.elements.append(ui.Button("Say Hi!",print_hello))
    m.elements.append(s)
    gui.elements.append(m)


    glfont = fs.Context()
    glfont.add_font('roboto', 'Roboto-Regular.ttf')
    import os
    import psutil

    pid = os.getpid()
    ps = psutil.Process(pid)


    while not quit:
        clear_gl_screen()
        # show some nanovg graphics

        glfont.set_font('roboto')
        for x in range(0):
            glfont.set_color_float(.1,.4,.7,.5)
            glfont.set_size(x*4)
            glfont.draw_text(300,50*x,"Oh my dear this is awesome.")
        # foo.bar += .5
        # if foo.bar >= 100:
        #     foo.bar = 0
        gui.update()

        glfwSwapBuffers(window)
        glfwPollEvents()
        # time.sleep(.03)

    glfwDestroyWindow(window)
    glfwTerminate()
    logger.debug("Process done")

if __name__ == '__main__':
    demo()

