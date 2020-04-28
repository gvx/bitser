local ffi = require("ffi")

ffi.cdef[[
struct simple_struct {
	int a;
	int b;
};

struct nested_struct {
	int a;
	struct simple_struct b;
};
]]

local int_data = ffi.new('int', 5)

local struct_data = ffi.new('struct nested_struct', {10, {20, 30}})


return {int_data, struct_data, {ffi.new("int",1),5,ffi.new("int",67)}}, 1000, 3