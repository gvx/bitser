package = "bitser"
version = "1.1-2"
source = {
   url = "git+https://github.com/gvx/bitser.git",
   tag = "v1.1"
}
description = {
   summary = "Serializes and deserializes Lua values with LuaJIT.",
   detailed = [[
      Serializes and deserializes Lua values with LuaJIT.
      It is blazingly fast, produces compact binary output, and is suitable
      for deserializing untrusted data.
   ]],
   homepage = "https://github.com/gvx/bitser",
   -- issues_url = "https://github.com/gvx/bitser/issues",
   license = "ISC"
}
dependencies = {
   -- "luajit <= 2.1"
}
build = {
   type = "builtin",
   modules = { bitser = "bitser.lua" }
}
