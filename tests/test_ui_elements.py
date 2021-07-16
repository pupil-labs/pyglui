import pytest


@pytest.fixture
def pyglui_ui_instance():
    import glfw

    from pyglui import cygl, ui

    glfw.ERROR_REPORTING = "raise"
    try:
        glfw_init_successful = glfw.init()
        assert glfw_init_successful, "Failed to initialize GLFW"
        glfw.window_hint(glfw.VISIBLE, glfw.FALSE)
        window = glfw.create_window(200, 200, "Test window", None, None)
    except glfw.GLFWError as err:
        # Skip if CI does not allow creating a window, e.g. on macOS:
        # > NSGL: Failed to find a suitable pixel format
        glfw.terminate()
        pytest.skip(str(err))

    glfw.make_context_current(window)  # required for GLEW init
    cygl.utils.init()
    global_ui_instance = ui.UI()
    yield global_ui_instance
    global_ui_instance.terminate()
    glfw.destroy_window(window)
    glfw.terminate()


@pytest.fixture
def attribute_context():
    return {"test": 5}


def test_Color_Legend(pyglui_ui_instance, attribute_context):
    import pyglui.ui

    black = (0.0, 0.0, 0.0, 1.0)
    pyglui.ui.Color_Legend(black, "test color")
