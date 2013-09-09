LUA=luajit

all: lhttp_parser/lhttp_parser.so luv/luv.so

lhttp_parser/lhttp_parser.so:
	$(MAKE) -C lhttp_parser

luv/luv.so: luv/Makefile
	$(MAKE) -C luv

clean:
	$(MAKE) -C lhttp_parser clean
	$(MAKE) -C luv clean
