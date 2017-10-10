pyglui
======

Cython powered OpenGL gui.

* Similar to AntTweakBar but truly python compatible. No need for ctyped variables.

* Uses render-to-texture for ulta low cpu use when static.

* Designed to be used with glfw but should run with other window managers as well.

* Uses [pyfontstash](http://github.com/pupil-labs/pyfontstash) for rendering text.

* Uses [cygl](http://github.com/pupil-labs/cygl) to access GL functions (which in turn uses [GLEW](http://glew.sourceforge.net/))



## Install
* install `glew` (instructions can be found [here](https://github.com/pupil-labs/cygl/blob/master/README.md))
```shell
cd ~/
git clone http://github.com/pupil-labs/pyglui --recursive
cd pyglui
sudo python setup.py install
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
You will either need to redo the install instructions from scratch or follow
these instructions:

```
cd <your pyglui folder>
# Make sure that you do not have any uncommited changes
git submodule deinit --all -f
rm -rf .git/modules/pyglui/cygl/
rm -rf .git/modules/pyglui/pyfontstash/

# Note: No trailing slash!
git rm -f pyglui/cygl
git rm -f pyglui/pyfontstash

# Commit changes before merging v1.8
git commit -m "Remove submodules"

# We merge using the changes of the master. This prevents an merge issue
# in the `.gitmodules` file.
git merge origin/master -Xtheirs

# Re-init fontstash submodule
git submodule init
git submodule update

# Upgrade installation to v1.8
pip install . -U
```

![](https://raw.github.com/wiki/pupil-labs/pyglui/media/demo_screenshot_20141221.png)
*Demo screenshot as of 2014-12-05*
