# cython: language_level=3

IF UNAME_SYSNAME == "Windows":
    cdef extern from 'Windows.h':
        pass
    cdef extern from '<GL/gl.h>':
        pass
ELSE:
    cdef extern from 'gl.h':
        pass

cdef extern from 'stb_truetype.h':
    pass

cdef extern from 'fontstash.h':

    enum: FONS_INVALID

    cdef enum FONSflags:
        FONS_ZERO_TOPLEFT
        FONS_ZERO_BOTTOMLEFT

    cdef enum FONSalign:
        FONS_ALIGN_LEFT
        FONS_ALIGN_CENTER
        FONS_ALIGN_RIGHT
        FONS_ALIGN_TOP
        FONS_ALIGN_MIDDLE
        FONS_ALIGN_BOTTOM
        FONS_ALIGN_BASELINE

    cdef enum FONSerrorCode:
        FONS_ATLAS_FULL
        FONS_SCRATCH_FULL
        FONS_STATES_OVERFLOW
        FONS_STATES_UNDERFLOW

    cdef struct FONSparams:
        int width
        int height
        unsigned char flags
        void *userPtr
        int (*renderCreate)(void *, int, int)
        int (*renderResize)(void *, int, int)
        void (*renderUpdate)(void *, int *, unsigned char *)
        void (*renderDraw)(void *, float *, float *, unsigned int *, int)
        void (*renderDelete)(void *)

    cdef struct FONSquad:
        float x0
        float y0
        float s0
        float t0
        float x1
        float y1
        float s1
        float t1

    cdef struct FONStextIter:
        float x
        float y
        float nextx
        float nexty
        float scale
        float spacing
        unsigned int codepoint
        short int isize
        short int iblur
        FONSfont *font
        int prevGlyphIndex
        char *str
        char *next
        char *end
        unsigned int utf8state

    cdef struct FONSfont:
        pass

    cdef struct FONScontext:
        pass

    FONScontext *fonsCreateInternal(FONSparams *params)

    void fonsDeleteInternal(FONScontext *s)

    void fonsSetErrorCallback(FONScontext *s, void (*callback)(void *, int, int), void *uptr)

    void fonsGetAtlasSize(FONScontext *s, int *width, int *height)

    int fonsExpandAtlas(FONScontext *s, int width, int height)

    int fonsResetAtlas(FONScontext *stash, int width, int height)

    int fonsAddFont(FONScontext *s, char *name, char *path)

    int fonsAddFontMem(FONScontext *s, char *name, unsigned char *data, int ndata, int freeData)

    int fonsGetFontByName(FONScontext *s, char *name)

    void fonsPushState(FONScontext *s)

    void fonsPopState(FONScontext *s)

    void fonsClearState(FONScontext *s)

    void fonsSetSize(FONScontext *s, float size)

    void fonsSetColor(FONScontext *s, unsigned int color)

    void fonsSetSpacing(FONScontext *s, float spacing)

    void fonsSetBlur(FONScontext *s, float blur)

    void fonsSetAlign(FONScontext *s, int align)

    void fonsSetFont(FONScontext *s, int font)

    float fonsDrawText(FONScontext *s, float x, float y, char *string, char *end)

    float fonsTextBounds(FONScontext *s, float x, float y, char *string, char *end, float *bounds)

    void fonsLineBounds(FONScontext *s, float y, float *miny, float *maxy)

    void fonsVertMetrics(FONScontext *s, float *ascender, float *descender, float *lineh)

    int fonsTextIterInit(FONScontext *stash, FONStextIter *iter, float x, float y, char *str, char *end)

    int fonsTextIterNext(FONScontext *stash, FONStextIter *iter, FONSquad *quad)

    unsigned char *fonsGetTextureData(FONScontext *stash, int *width, int *height)

    int fonsValidateTexture(FONScontext *s, int *dirty)

    void fonsDrawDebug(FONScontext *s, float x, float y)

cdef extern from 'glfontstash.h':

    FONScontext *glfonsCreate(int width, int height, int flags)
    void glfonsDelete(FONScontext* ctx)
    unsigned int glfonsRGBA(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
