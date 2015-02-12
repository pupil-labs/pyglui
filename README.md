pyglui
======

Cython powered OpenGL gui.

* Similar to AntTweakBar but truly python compatible. No need for ctyped variables.

* Uses render-to-texture for ulta low cpu use when static.

* Designed to be used with glfw but should run with other window managers as well.

* Requires GLEW.

* Uses pyfonstash for rendering text.



## Install
* install `glew` (instructions can be found here: https://github.com/pupil-labs/cygl/readme.md )
* clone with `--recursive` flag
* `python setup.py install`

## Demo
* `cd /example`
* `python example.py` 

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/demo_screenshot_20141221.png)
*Demo screenshot as of 2014-12-05*
