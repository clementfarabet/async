uname_S=$(shell uname -s)
ifeq (Darwin, $(uname_S))
  CFLAGS=-Ihttp-parser -I ${LUA_INCDIR} -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wall -Werror -fPIC
  LIBS=-lm -lpthread -L ${LUA_LIBDIR} -undefined dynamic_lookup
  SHARED_LIB_FLAGS=-bundle -o lhttp_parser.so lhttp_parser.o http-parser/http_parser.o
  AR=ar cr lhttp_parser.a lhttp_parser.o http-parser/http_parser.o
else
  CFLAGS=-Ihttp-parser -I ${LUA_INCDIR} -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -Wall -Werror -fPIC
  LIBS=-lm -lpthread -lrt
  SHARED_LIB_FLAGS=-shared -o lhttp_parser.so lhttp_parser.o http-parser/http_parser.o
  AR=ar cr lhttp_parser.a lhttp_parser.o http-parser/http_parser.o
endif

all: lhttp_parser.so lhttp_parser.a

http-parser/http_parser.o:
	CPPFLAGS=-fPIC $(MAKE) -C http-parser http_parser.o

lhttp_parser.o: lhttp_parser.c
	$(CC) -c $< -o $@ ${CFLAGS}

lhttp_parser.so: lhttp_parser.o http-parser/http_parser.o
	$(CC) ${SHARED_LIB_FLAGS} ${LIBS}

lhttp_parser.a: lhttp_parser.o http-parser/http_parser.o
	$(AR)

clean:
	make -C http-parser clean
	rm -f *.so *.o *.a
