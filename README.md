pyglui
======

Cython powered OpenGL gui.

* Similar to AntTweakBar but truly python compatible. No need for ctyped variables.

* Uses render-to-texture for ulta low cpu use when static.

* Designed to be used with glfw but should run with other window managers as well.

* Includes [pyfontstash](https://github.com/pupil-labs/pyglui/tree/master/pyglui/pyfontstash) for rendering text.

* Includes [cygl](https://github.com/pupil-labs/pyglui/tree/master/pyglui/cygl) to access GL functions (which in turn uses [GLEW](http://glew.sourceforge.net/))

* cygl and pyfontstash can also be installed separately but are hosted in this project for convenience.


## Setup
Fork and clone to work locally.

```shell
git clone http://github.com/pupil-labs/pyglui --recursive
```

## Installation

* install `glew`

Linux
```shell
sudo apt-get install libglew-dev
```

MacOS
```shell
brew install glew
```

* install pyglui
```shell
sudo pip3 install git+https://github.com/pupil-labs/pyglui
```

## Development

Run command to build pyglui
```shell
sudo python3 setup.py install

```

## Demo
* `pip install psutil` (psutil is used in the demo to show cpu load)
* `cd /example`
* `python3 example.py`

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/demo_screenshot_20141221.png)
*Demo screenshot as of 2017-12-19*
