LUA=luajit

all: lhttp_parser/lhttp_parser.so luv/luv.so

lhttp_parser/Makefile:
	git submodule update --init --recursive lhttp_parser

lhttp_parser/lhttp_parser.so: lhttp_parser/Makefile
	$(MAKE) -C lhttp_parser

luv/Makefile:
	git submodule update --init --recursive luv

luv/luv.so: luv/Makefile
	$(MAKE) -C luv

clean:
	$(MAKE) -C lhttp_parser clean
	$(MAKE) -C luv clean
