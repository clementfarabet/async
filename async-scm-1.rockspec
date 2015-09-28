package = "async"
version = "scm-1"

source = {
   url = "git://github.com/clementfarabet/async",
   dir = "async"
}

description = {
   summary = "An async framework for Torch (based on LibUV)",
   detailed = [[
Async framework for Torch, based on LibUV.
   ]],
   homepage = "https://github.com/clementfarabet/async",
   license = "BSD"
}

dependencies = {
   "torch >= 7.1.alpha",
   "lua-cjson >= 0.1"
}

build = {
   type = "command",
   build_command = "$(MAKE)  LUA=$(LUA)  LUA_BINDIR=$(LUA_BINDIR)  LUA_LIBDIR=$(LUA_LIBDIR)  LUA_INCDIR=$(LUA_INCDIR)",
   install_command = [[
cp -r async $(LUADIR)/
cp luv/luv.so lhttp_parser/lhttp_parser.so $(LIBDIR)/
cp luv/libuv/libuv.a $(LUA_LIBDIR)/libuv.a
cp luv/luv.a $(LUA_LIBDIR)/libluv.a
cp lhttp_parser/lhttp_parser.a $(LUA_LIBDIR)/liblhttp_parser.a
   ]]
}
