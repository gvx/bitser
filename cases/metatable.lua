-- test metatables
local metatable = {__mode = 'k', foo={1,2,3,4,5,6,7,8,10,11,12}}
metatable.__index = metatable

return setmetatable({test=true}, metatable), 10000, 3
