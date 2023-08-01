
appname := UE1MapDowngrade226fTo225f

# common/os specific things borrowed from CE C toolchain /meta/makefile.mk https://github.com/CE-Programming/toolchain
ifeq ($(OS),Windows_NT)

SHELL      = cmd.exe
NATIVEPATH = $(subst /,\,$1)
DIRNAME    = $(filter-out %:,$(patsubst %\,%,$(dir $1)))
RM         = del
RMDIR      = call && (if exist $1 rmdir /s /q $1)
MKDIR      = call && (if not exist $1 mkdir $1)
PREFIX    ?= C:
INSTALLLOC := $(call NATIVEPATH,$(DESTDIR)$(PREFIX))
CP         = copy /y
EXMPL_DIR  = $(call NATIVEPATH,$(INSTALLLOC)/CEdev/examples)
CPDIR      = xcopy /e /i /q /r /y /b
CP_EXMPLS  = $(call MKDIR,$(EXMPL_DIR)) && $(CPDIR) $(call NATIVEPATH,$(CURDIR)/examples) $(EXMPL_DIR)
ARCH       = $(call MKDIR,release) && cd tools\installer && ISCC.exe /DAPP_VERSION=8.4 /DDIST_PATH=$(call NATIVEPATH,$(DESTDIR)$(PREFIX)/CEdev) installer.iss && \
             cd ..\.. && move /y tools\installer\CEdev.exe release\\
QUOTE_ARG  = "$(subst ",',$1)"#'
APPEND     = @echo.$(subst ",^",$(subst \,^\,$(subst &,^&,$(subst |,^|,$(subst >,^>,$(subst <,^<,$(subst ^,^^,$1))))))) >>$@

CC := C:\raylib\w64devkit\bin\gcc.exe
CCFLAGS := -s -static -O3 -std=c99 -Iexternal -DPLATFORM_DESKTOP -DPLATFORM_WINDOWS  -Wextra
LDLIBS  := -Lsrc -lgdi32 -lwinmm

else

NATIVEPATH = $(subst \,/,$1)
DIRNAME    = $(patsubst %/,%,$(dir $1))
RM         = rm -f
RMDIR      = rm -rf $1
MKDIR      = mkdir -p $1
PREFIX    ?= $(HOME)
INSTALLLOC := $(call NATIVEPATH,$(DESTDIR)$(PREFIX))
CP         = cp
CPDIR      = cp -r
CP_EXMPLS  = $(CPDIR) $(call NATIVEPATH,$(CURDIR)/examples) $(call NATIVEPATH,$(INSTALLLOC)/CEdev)
ARCH       = cd $(INSTALLLOC) && tar -czf $(RELEASE_NAME).tar.gz $(RELEASE_NAME) ; \
             cd $(CURDIR) && $(call MKDIR,release) && mv -f $(INSTALLLOC)/$(RELEASE_NAME).tar.gz release
CHMOD      = find $(BIN) -name "*.exe" -exec chmod +x {} \;
QUOTE_ARG  = '$(subst ','\'',$1)'#'
APPEND     = @echo $(call QUOTE_ARG,$1) >>$@
CC := gcc
RAYLIB_PATH := ~/raylib
CCFLAGS := -s -static -O3 -std=c99 -Iexternal -DPLATFORM_DESKTOP -DPLATFORM_LINUX -Wextra -D_DEFAULT_SOURCE
LDLIBS  := -Lsrc -lm -lpthread -ldl -lrt
endif

# source: http://blog.jgc.org/2011/07/gnu-make-recursive-wildcard-function.html
rwildcard = $(strip $(foreach d,$(wildcard $1/*),$(call rwildcard,$d,$2) $(filter $(subst %%,%,%$(subst *,%,$2)),$d)))
CCFLAGS += -Wno-unused-parameter -Werror=write-strings -Werror=redundant-decls -Werror=format -Werror=format-security -Werror=declaration-after-statement -Werror=implicit-function-declaration -Werror=date-time -Werror=return-type -Werror=pointer-arith -Winit-self

# DEBUGFLAGS ?= -g
# LDFLAGS ?= -g

srcfiles    :=  $(call NATIVEPATH,src/main.c)
objects     :=  $(patsubst %.c, %.o, $(srcfiles))
headers     :=  

all: $(appname)

ifeq ($(OS),Windows_NT)
$(appname): $(objects)
	windres -i Main.rc -o Main.rc.data
	$(CC) $(DEBUGFLAGS) Main.rc.data $(CCFLAGS) $(LDFLAGS) $(objects) $(LDLIBS) -o $(appname)
else
$(appname): $(objects)
	$(CC) $(DEBUGFLAGS) $(CCFLAGS) $(LDFLAGS) $(objects) $(LDLIBS) -o $(appname)
endif

%.o: %.c $(headers)
	$(CC) $(DEBUGFLAGS) $(CCFLAGS) -c $< -o $@

clean:
	$(RM) $(objects)

