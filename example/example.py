import functools
import logging
import time

import glfw
import numpy as np
from OpenGL.GL import *

# create logger for the context of this function
logger = logging.getLogger(__name__)

import time

from pyglui import ui
from pyglui.cygl.shader import Shader
from pyglui.cygl.utils import RGBA, draw_points, init
from pyglui.pyfontstash import fontstash as fs

width, height = (1280, 720)


def basic_gl_setup():
    glEnable(GL_POINT_SPRITE)
    glEnable(GL_VERTEX_PROGRAM_POINT_SIZE)  # overwrite pointsize
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_BLEND)
    glClearColor(0.8, 0.8, 0.8, 1.0)
    glEnable(GL_LINE_SMOOTH)
    # glEnable(GL_POINT_SMOOTH)
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
    glEnable(GL_POLYGON_SMOOTH)
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)


def adjust_gl_view(w, h, window):
    """
    adjust view onto our scene.
    """
    print(w, h)
    glViewport(0, 0, int(w), int(h))
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, w, h, 0, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()


_MARKER_CIRCLE_RGB_OUTER = (0.0, 0.0, 0.0)
_MARKER_CIRCLE_RGB_MIDDLE = (1.0, 1.0, 1.0)
_MARKER_CIRCLE_RGB_INNER = (0.0, 0.0, 0.0)
_MARKER_CIRCLE_RGB_FEEDBACK_INVALID = (0.8, 0.0, 0.0)
_MARKER_CIRCLE_RGB_FEEDBACK_VALID = (0.0, 0.8, 0.0)

_MARKER_CIRCLE_SIZE_OUTER = 60
_MARKER_CIRCLE_SIZE_MIDDLE = 38
_MARKER_CIRCLE_SIZE_INNER = 19
_MARKER_CIRCLE_SIZE_FEEDBACK = 3

_MARKER_CIRCLE_SHARPNESS_OUTER = 0.9
_MARKER_CIRCLE_SHARPNESS_MIDDLE = 0.8
_MARKER_CIRCLE_SHARPNESS_INNER = 0.55
_MARKER_CIRCLE_SHARPNESS_FEEDBACK = 0.5


@functools.lru_cache(4)  # 4 circles needed to draw calibration marker
def _circle_points_around_zero(radius: float, num_points: int) -> np.ndarray:
    t = np.linspace(0, 2 * np.pi, num_points, dtype=np.float64)
    t.shape = -1, 1
    points = np.hstack([np.cos(t), np.sin(t)])
    points *= radius
    return points


@functools.lru_cache(4)  # 4 circles needed to draw calibration marker
def _circle_points_offset(
    offset, radius: float, num_points: int, flat: bool = True
) -> np.ndarray:
    # NOTE: .copy() to avoid modifying the cached result
    points = _circle_points_around_zero(radius, num_points).copy()
    points[:, 0] += offset[0]
    points[:, 1] += offset[1]
    if flat:
        points.shape = -1
    return points


def _draw_circle_filled(screen_point, size: float, color: RGBA, num_points: int = 50):
    points = _circle_points_offset(
        screen_point, radius=size, num_points=num_points, flat=False
    )
    glColor4f(color.r, color.g, color.b, color.a)
    glEnableClientState(GL_VERTEX_ARRAY)
    glVertexPointer(2, GL_DOUBLE, 0, points)
    glDrawArrays(GL_POLYGON, 0, points.shape[0])


def _draw_circle_marker_polygon(position):

    r2 = 2
    screen_point = position

    # _draw_circle_filled(
    #     screen_point,
    #     size=_MARKER_CIRCLE_SIZE_OUTER * r2,
    #     color=RGBA(1.0, 0.0, 0.0, alpha),
    #     num_points=50,
    # )
    alpha = 1

    _draw_circle_filled(
        screen_point,
        size=_MARKER_CIRCLE_SIZE_OUTER * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_OUTER, alpha),
    )
    _draw_circle_filled(
        screen_point,
        size=_MARKER_CIRCLE_SIZE_MIDDLE * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_MIDDLE, alpha),
    )
    _draw_circle_filled(
        screen_point,
        size=_MARKER_CIRCLE_SIZE_INNER * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_INNER, alpha),
    )
    _draw_circle_filled(
        screen_point,
        size=_MARKER_CIRCLE_SIZE_FEEDBACK * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_FEEDBACK_VALID, alpha),
    )


def _draw_circle_marker_pointshader(position):

    r2 = 2 * 2
    screen_point = position
    alpha = 1

    draw_points(
        [screen_point],
        size=_MARKER_CIRCLE_SIZE_OUTER * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_OUTER, alpha),
        sharpness=_MARKER_CIRCLE_SHARPNESS_OUTER,
    )
    draw_points(
        [screen_point],
        size=_MARKER_CIRCLE_SIZE_MIDDLE * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_MIDDLE, alpha),
        sharpness=_MARKER_CIRCLE_SHARPNESS_MIDDLE,
    )
    draw_points(
        [screen_point],
        size=_MARKER_CIRCLE_SIZE_INNER * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_INNER, alpha),
        sharpness=_MARKER_CIRCLE_SHARPNESS_INNER,
    )
    draw_points(
        [screen_point],
        size=_MARKER_CIRCLE_SIZE_FEEDBACK * r2,
        color=RGBA(*_MARKER_CIRCLE_RGB_FEEDBACK_VALID, alpha),
        sharpness=_MARKER_CIRCLE_SHARPNESS_FEEDBACK,
    )


class Timer:
    def __init__(self):
        self._times = []

    def __enter__(self, *args, **kwargs):
        self.t0 = time.perf_counter()

    def __exit__(self, *args, **kwargs):
        self._times.append(time.perf_counter() - self.t0)
        del self.t0

    def result(self):
        import pandas as pd

        return pd.Series(self._times).describe()


def demo():
    global quit
    quit = False

    # Callback functions
    def on_resize(window, w, h):
        h = max(h, 1)
        w = max(w, 1)
        hdpi_factor = (
            glfw.get_framebuffer_size(window)[0] / glfw.get_window_size(window)[0]
        )
        w, h = w * hdpi_factor, h * hdpi_factor
        active_window = glfw.get_current_context()
        glfw.make_context_current(active_window)
        # norm_size = normalize((w,h),glfw.get_window_size(window))
        # fb_size = denormalize(norm_size,glfw.get_framebuffer_size(window))
        adjust_gl_view(w, h, window)
        glfw.make_context_current(active_window)

    def on_close(window):
        global quit
        quit = True
        logger.info("Process closing from window")

    # get glfw started
    glfw.init()

    window = glfw.create_window(width, height, "pyglui demo", None, None)
    if not window:
        exit()

    glfw.set_window_pos(window, 0, 0)
    # Register callbacks for the window
    glfw.set_window_size_callback(window, on_resize)
    glfw.set_window_close_callback(window, on_close)
    # test out new paste function

    glfw.make_context_current(window)
    init()
    basic_gl_setup()
    glfw.swap_interval(0)

    print(glGetString(GL_VERSION))

    on_resize(window, *glfw.get_window_size(window))

    t_pointshader = Timer()
    t_polygon = Timer()
    t_swap = Timer()
    t_poll = Timer()

    while not quit:

        with t_pointshader:
            _draw_circle_marker_pointshader((320, 320))
        with t_polygon:
            _draw_circle_marker_polygon((960, 320))

        with t_swap:
            glfw.swap_buffers(window)

        with t_poll:
            glfw.poll_events()
        # adjust_gl_view(1280,720,window)
        glClearColor(1.0, 1.0, 1.0, 1)
        glClear(GL_COLOR_BUFFER_BIT)

    print(f"{t_pointshader.result()=}")
    print(f"{t_polygon.result()=}")
    print(f"{t_swap.result()=}")
    print(f"{t_poll.result()=}")

    glfw.terminate()
    logger.debug("Process done")


if __name__ == "__main__":
    if 1:
        demo()
    else:
        import cProfile
        import os
        import subprocess

        cProfile.runctx("demo()", {}, locals(), "example.pstats")
        gprof2dot_loc = "gprof2dot.py"
        subprocess.call(
            "python "
            + gprof2dot_loc
            + " -f pstats example.pstats | dot -Tpng -o example_profile.png",
            shell=True,
        )
        print(
            "created cpu time graph for example. Please check out the png next to this."
        )
