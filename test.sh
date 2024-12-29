lua_install/bin/luacheck --std max+busted bitser.lua spec --globals love --no-max-line-length
lua_install/bin/busted --verbose --coverage
lua_install/bin/luacov bitser$ bitser_spec$
