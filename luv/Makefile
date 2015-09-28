uname_S=$(shell uname -s)
ifeq (Darwin, $(uname_S))
  CFLAGS=-Ilibuv/include -O3 -fno-strict-aliasing -I ${LUA_INCDIR} -DLUV_STACK_CHECK -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wall -Werror -fPIC
  LIBS=-lm -framework CoreServices -framework Cocoa -L ${LUA_LIBDIR} -undefined dynamic_lookup
  SHARED_LIB_FLAGS=-bundle -o luv.so temp/luv.o libuv/libuv.a temp/common.o
  AR=ar cr luv.a temp/luv.o temp/common.o
  RANLIB=ranlib luv.a
else
  CFLAGS=-Ilibuv/include -O3 -fno-strict-aliasing -I ${LUA_INCDIR} -DLUV_STACK_CHECK -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wall -Werror -fPIC
  LIBS=-lm -lrt
  SHARED_LIB_FLAGS=-shared -o luv.so temp/luv.o libuv/libuv.a temp/common.o
  AR=ar cr luv.a temp/luv.o temp/common.o
  RANLIB=ranlib luv.a
endif

all: luv.so luv.a

libuv/libuv.a:
	CPPFLAGS=-fPIC $(MAKE) -C libuv

temp:
	mkdir temp

temp/common.o: src/common.c src/common.h temp
	$(CC) -c $< -o $@ ${CFLAGS}

temp/luv.o: src/luv.c src/luv.h src/luv_functions.c temp
	$(CC) -c $< -o $@ ${CFLAGS}

luv.so: temp/luv.o libuv/libuv.a temp/common.o
	$(CC) ${SHARED_LIB_FLAGS} ${LIBS}

luv.a: temp/luv.o libuv/libuv.a temp/common.o
	$(AR)
	$(RANLIB)

clean:
	make -C libuv clean
	rm -rf temp
	rm -f luv.so
	rm -f luv.a
