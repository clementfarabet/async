package = "async"
version = "scm-1"

source = {
   url = "git://github.com/madbits/async",
   dir = "async"
}

description = {
   summary = "An async framework for Torch (based on LibUV)",
   detailed = [[
Async framework for Torch, based on LibUV.
   ]],
   homepage = "https://github.com/madbits/async",
   license = "BSD"
}

dependencies = {
   "torch >= 7.1.alpha",
}

build = {
   type = "command",
   build_command = "",
   install_command = [[
cp async.lua $(LUADIR)/
cp luv.so $(LIBDIR)/
   ]]
}
