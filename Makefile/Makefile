COMPILER=
ARCHIVER=
CP=cp
COMPILER_FLAGS=
EXTRA_COMPILER_FLAGS=
LIB=libxil.a

RELEASEDIR=../../../lib
INCLUDEDIR=../../../include
INCLUDES=-I./. -I${INCLUDEDIR}

# =============================================================
# PHẦN TỰ ĐỘNG (AUTO-DETECTION)
# Tự động tìm tất cả file .c và .h trong thư mục hiện tại
# =============================================================
LIBSOURCES := $(wildcard *.c)
INCLUDEFILES := $(wildcard *.h)
OBJECTS := $(LIBSOURCES:.c=.o)

# =============================================================
# CÁC TARGET BIÊN DỊCH
# =============================================================

libs:
	echo "Compiling drivers..."
	$(COMPILER) $(COMPILER_FLAGS) $(EXTRA_COMPILER_FLAGS) $(INCLUDES) $(LIBSOURCES)
	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} $(OBJECTS)
	make clean

include:
	${CP} $(INCLUDEFILES) $(INCLUDEDIR)

clean:
	rm -rf $(OBJECTS)
