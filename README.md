[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Build and deploy](https://github.com/pupil-labs/pyglui/actions/workflows/build-and-deploy.yml/badge.svg)](https://github.com/pupil-labs/pyglui/actions/workflows/build-and-deploy.yml)
[![PyPI version](https://badge.fury.io/py/pyglui.svg)](https://pypi.org/project/pyglui/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

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

```
pip install pyglui
```

### Source installation

#### Dependencies
* install `glew`

Linux (via apt-get)
```shell
sudo apt-get install libglew-dev
```

Linux (via yum)
```shell
yum install glew-devel
```

MacOS
```shell
brew install glew
```

* install pyglui
```shell
python -m pip install git+https://github.com/pupil-labs/pyglui
```

#### Source code

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
