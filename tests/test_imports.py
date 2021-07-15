import platform

import pytest


def test_import_numpy():
    import numpy


@pytest.mark.skipif(
    platform.system() == "Windows", reason="cysignals is not required on Windows"
)
def test_import_cysignals():
    import cysignals


def test_import_glfw():
    import glfw


def test_import_pyglui():
    import pyglui

    assert pyglui


def test_import_cygl():
    import pyglui.cygl


def test_import_cygl_shader():
    from pyglui.cygl import shader


def test_import_cygl_utils():
    from pyglui.cygl import utils


def test_import_ui():
    import pyglui.ui

    assert pyglui.ui
