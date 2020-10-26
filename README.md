pyglui
======

Cython powered OpenGL gui.

* Similar to AntTweakBar but truly python compatible. No need for ctyped variables.

* Uses render-to-texture for ulta low cpu use when static.

* Designed to be used with glfw but should run with other window managers as well.

* Includes [pyfontstash](https://github.com/pupil-labs/pyglui/tree/master/pyglui/pyfontstash) for rendering text.

* Includes [cygl](https://github.com/pupil-labs/pyglui/tree/master/pyglui/cygl) to access GL functions (which in turn uses [GLEW](http://glew.sourceforge.net/))

* cygl and pyfontstash can also be installed separately but are hosted in this project for convenience.


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
python -m pip install git+https://github.com/pupil-labs/pyglui
```

### Development

```shell
# Clone the repository to the local filesystem
git clone http://github.com/pupil-labs/pyglui --recursive
cd pyglui

# Build and install `pyglui` in "editable" mode
python -m pip install -e .
```

### Run the demo

```shell
# Clone the repository to the local filesystem
git clone http://github.com/pupil-labs/pyglui --recursive
cd pyglui

# Build and install `pyglui` in "editable" mode, with examples dependencies
python -m pip install -e ".[examples]"

# Run the demo example
cd example
python3 example.py
```

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/pyglui_20171219.png)
*Demo screenshot as of 2017-12-19*
