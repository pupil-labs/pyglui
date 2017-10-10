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
cd ~/
git clone http://github.com/pupil-labs/pyglui --recursive
pip install pyglui -U
```

(for Windows Microsoft Visual Studio 2008 is required)

## Demo
* `pip install psutil` (psutil is used in the demo to show cpu load)
* `cd /example`
* `python example.py`


## Update
**See the special instructions below if you upgrade from v1.7 to v1.8**

Since we use submodules please do get and install updates:
```shell
git pull --recurse-submodules
git submodule update --recursive
pip install . -U
```

### Update from v1.7 to v1.8
We moved `cygl` and `pyfontstash` into `pyglui` and removed the git submodules.
You will need to redo the install instructions from scratch:

```
cd <your pyglui folder>
# now we delete this dir!
cd ../
sudo rm -r pylgui

#clone the latest version
git clone --recursive  https://github.com/pupil-labs/pyglui

#and install it.
pip install pyglui -U
```

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/demo_screenshot_20141221.png)
*Demo screenshot as of 2014-12-05*
