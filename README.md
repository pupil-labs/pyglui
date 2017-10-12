pyglui
======

Cython powered OpenGL gui.

* Similar to AntTweakBar but truly python compatible. No need for ctyped variables.

* Uses render-to-texture for ulta low cpu use when static.

* Designed to be used with glfw but should run with other window managers as well.

* Includes [pyfontstash](https://github.com/pupil-labs/pyglui/tree/master/pyglui/pyfontstash) for rendering text.

* Includes [cygl](https://github.com/pupil-labs/pyglui/tree/master/pyglui/cygl) to access GL functions (which in turn uses [GLEW](http://glew.sourceforge.net/))

* cygl and pyfonstash can also be install sepertly but are hosted in this project for convenience.



## Install
* install `glew` (instructions can be found [here](https://github.com/pupil-labs/cygl/blob/master/README.md))
```shell
sudo pip3 install git+https://github.com/pupil-labs/pyglui
```

(for Windows Microsoft Visual Studio 2008 is required)

## Demo
* `pip install psutil` (psutil is used in the demo to show cpu load)
* `cd /example`
* `python example.py`

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/demo_screenshot_20141221.png)
*Demo screenshot as of 2014-12-05*
