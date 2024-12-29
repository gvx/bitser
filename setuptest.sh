python3 -m pip install hererocks
python3 -m hererocks lua_install -r^ --luajit=2.0
export PATH=$PATH:$PWD/lua_install/bin
luarocks install luacheck 
luarocks install busted
luarocks install luacov
luarocks install luacov-coveralls
luarocks install middleclass
wget https://raw.githubusercontent.com/bartbes/slither/b9cf6daa1e8995093aa80a40ee9ff98402eeb602/slither.lua
wget https://raw.githubusercontent.com/vrld/hump/038bc9025f1cb850355f4b073357b087b8122da9/class.lua
wget https://raw.githubusercontent.com/rxi/classic/e5610756c98ac2f8facd7ab90c94e1a097ecd2c6/classic.lua
