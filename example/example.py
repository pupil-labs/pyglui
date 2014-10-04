import logging
from glfw import *
import OpenGL
from OpenGL.GL import *

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
    glClearColor(0., 0., 0., 1.0)

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
    glClearColor(0.7, 0.7, 0.7, 1.0)
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)


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
    window = glfwCreateWindow(width, height, "Python NanoVG Demo", None, None)
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


    basic_gl_setup()

    # glfwSwapInterval(0)
    glfwMakeContextCurrent(window)

    # vg = nanovg.Context()
    import nanovg
    nanovg.create_shared_context() # only needs to be called once per process.
    from nanovg import vg, colorRGBAf,GRAPH_RENDER_FPS,GRAPH_RENDER_PERCENT
    vg.createFont("sans", "Roboto-Regular.ttf")

    img = vg.createImage("../nanovg/example/images/image2.jpg", 0)

    pos = np.arange(0,2000,.1,dtype=np.float)
    print len(pos)
    pos = np.vstack((pos*5,2*pos+(np.sin(pos)*100))).T
    print pos.shape

    fps = nanovg.Graph(vg,GRAPH_RENDER_FPS,"Framerate")
    fps.pos= (20,20)
    cpu = nanovg.Graph(vg,GRAPH_RENDER_PERCENT,"CPU load of Process")
    cpu.pos = (240,20)
    ts = time.time()

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


    import pyglui as ui
    gui = ui.UI()
    gui.update_window(width,height)
    m = ui.Menu("MySideBar",pos=(-200,20),size=(0,-20))
    s = ui.StackBox()

    for x in range(20):
        s.elements.append(ui.Slider("bar",foo,label="bar %s"%x))
        s.elements.append(ui.Slider("bur",foo,label="bur %s"%x))
    m.elements.append(s)
    gui.elements.append(m)

    m = ui.Menu("MyMenu",pos=(400,-200),size=(300,150))
    s = ui.StackBox()
    for x in range(1):
        s.elements.append(ui.Slider("bur",foo,setter=printer))
        s.elements.append(ui.Button("Say Hi!",print_hello))
        sm = ui.Menu("SubMenu",pos=(0,20),size=(0,100))
        ss= ui.StackBox()
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.Slider("bar",foo))
        ss.elements.append(ui.TextInput('mytext',foo,setter=printer))
        sm.elements.append(ss)
        s.elements.append(sm)
    m.elements.append(s)
    gui.elements.append(m)


    import os
    import psutil

    pid = os.getpid()
    ps = psutil.Process(pid)


    while not quit:
        clear_gl_screen()
        # show some nanovg graphics

        vg.beginFrame(width, height, float(width)/float(height))
        # draw_lines(0.,0.,100.)
        # res = vg.textBounds(0.0, 0.0, "here is my text", "t")
        vg.save()
        _dt = 0

        p = vg.linearGradient(0.0, 0.0, 1000.0, 600.0, colorRGBAf(0.0,0.0,1.0,1.0), colorRGBAf(0.,1.,0.2,0.5))
        rg = vg.radialGradient(0.0, 0.0, 100.0, 120.0, colorRGBAf(0.0,0.0,1.0,1.0), colorRGBAf(0.,1.,0.2,0.5))
        vg.beginPath()
        vg.fillColor(colorRGBAf(0.2,0.2,0.2,0.4))
        vg.roundedRect(10.0, 10.0, 490.0, 290.0, 5.0)

        vg.fillPaint(p)
        vg.fill()

        rg = vg.linearGradient(500.0, 300.0, 100.0, 200.0, colorRGBAf(0.0,0.0,0.0,0.0), colorRGBAf(0.,1.,0.2,0.5))
        vg.beginPath()
        vg.fillPaint(rg)
        vg.strokeColor(colorRGBAf(0.0,0.4,0.7,0.9))
        vg.strokeWidth(1.)
        # if 0:
        #     vg.beginPath()
        #     vg.moveTo(0,0)
        #     for x,y in pos:
        #         vg.lineTo(x,y)
        # else:
        #     # pass
        #     vg.Polyline(pos)

        # vg.fill()
        # vg.stroke()
        # import loaded_module
        # loaded_module.draw()
        # # test font rendering
        txt = "Hello World - Python NanoVG bindings."
        # # print vg.textBounds(0,0,txt)
        # # print vg.textMetrics(1.)
        # # print vg.textBreakLines(txt)

        vg.fontFace("bold")
        vg.fontSize(24.0)
        vg.fillColor(colorRGBAf(1.,0.,0.,1.))
        # vg.text(15.0, 30.0, txt)

        vg.fontFace("regular")
        vg.fillColor(colorRGBAf(1.,1.,1.,1.))
        # vg.text(15.0, 50.0, txt)



        dt,ts = time.time()-ts,time.time()
        # print dt
        fps.update(dt)
        fps.render()

        # print foo.bar
        # print foo.bur
        pct = ps.get_cpu_percent()
        # pct = psutil.cpu_percent()
        cpu.update(pct)
        cpu.render()

        gui.update(vg)
        # print foo.bar
        # vg.stroke()
        # vg.roundedRect(600,100,100,100,3)

        vg.endFrame()
        glfwSwapBuffers(window)
        glfwPollEvents()
        # time.sleep(.03)

    vg.reset()
    glfwDestroyWindow(window)
    glfwTerminate()
    logger.debug("Process done")

if __name__ == '__main__':
    demo()

