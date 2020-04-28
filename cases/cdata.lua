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

local bitser = require 'bitser'

local int_data = ffi.new('int', 5)

local struct_data = ffi.new('struct nested_struct', {10, {20, 30}})

local value = ffi.new('struct { int a; double b; }', 42, 1.25)

return {int_data, struct_data, value}, 1000, 3