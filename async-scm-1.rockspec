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
   build_command = "$(MAKE) LUA_BINDIR=$(LUA_BINDIR)  LUA_LIBDIR=$(LUA_LIBDIR)  LUA_INCDIR=$(LUA_INCDIR)",
   install_command = [[
cp -r async $(LUADIR)/
cp luv.so lhttp_parser.so $(LIBDIR)/
   ]]
}
