local floor = math.floor
local pairs = pairs
local type = type
local insert = table.insert
local getmetatable = getmetatable
local setmetatable = setmetatable

local ffi = require("ffi")

local function Buffer_newWriter(size)
	size = size or 4096
	return {size = size, pos = 0, buf = ffi.new("uint8_t[?]", size)}
end

local function Buffer_newReader(str)
	local buf = ffi.new("uint8_t[?]", #str)
	ffi.copy(buf, str, #str)
	return {size = #str, pos = 0, buf = buf}
end

local function Buffer_reserve(self, additional_size)
	while self.pos + additional_size > self.size do
		self.size = self.size * 2
		local oldbuf = self.buf
		self.buf = ffi.new("uint8_t[?]", self.size)
		ffi.copy(self.buf, oldbuf, self.pos)
	end
end

local function Buffer_write_byte(self, x)
	Buffer_reserve(self, 1)
	self.buf[self.pos] = x
	self.pos = self.pos + 1
end

local function Buffer_write_string(self, s)
	Buffer_reserve(self, #s)
	ffi.copy(self.buf + self.pos, s, #s)
	self.pos = self.pos + #s
end

local function Buffer_write_data(self, ct, len, ...)
	Buffer_reserve(self, len)
	ffi.copy(self.buf + self.pos, ffi.new(ct, ...), len)
	self.pos = self.pos + len
end

local function Buffer_get(self)
	return self.buf, self.pos
end

local function Buffer_read_byte(self)
	local x = self.buf[self.pos]
	self.pos = self.pos + 1
	return x
end

local function Buffer_read_string(self, len)
	local pos = self.pos
	self.pos = pos + len
	return ffi.string(self.buf + pos, len)
end

local function Buffer_read_data(self, ct, len)
	local t = ffi.new(ct)
	ffi.copy(t, self.buf + self.pos, len)
	self.pos = self.pos + len
	return t
end

local resource_registry = {}
local resource_name_registry = {}
local class_registry = {}
local class_name_registry = {}
local classkey_registry = {}
local class_deserialize_registry = {}

local serialize_value

local function write_number(value, buffer, _)
	if floor(value) == value and value >= -2147483648 and value <= 2147483647 then
		if value >= -27 and value <= 100 then
			--small int
			Buffer_write_byte(buffer, value + 27)
		elseif value >= -32768 and value <= 32767 then
			--short int
			Buffer_write_byte(buffer, 250)
			Buffer_write_data(buffer, "int16_t[1]", 2, value)
		else
			--long int
			Buffer_write_byte(buffer, 245)
			Buffer_write_data(buffer, "int32_t[1]", 4, value)
		end
	else
		--double
		Buffer_write_byte(buffer, 246)
		Buffer_write_data(buffer, "double[1]", 8, value)
	end
end

local function write_string(value, buffer, seen)
	if #value < 32 then
		--short string
		Buffer_write_byte(buffer, 192 + #value)
	else
		--long string
		Buffer_write_byte(buffer, 244)
		write_number(#value, buffer, seen)
	end
	Buffer_write_string(buffer, value)
end

local function write_nil(_, buffer, _)
	Buffer_write_byte(buffer, 247)
end

local function write_boolean(value, buffer, _)
	Buffer_write_byte(buffer, value and 249 or 248)
end

local function write_table(value, buffer, seen)
	local classkey
	local class = (class_name_registry[value.class] -- MiddleClass
		or class_name_registry[value.__baseclass] -- SECL
		or class_name_registry[getmetatable(value)] -- hump.class
		or class_name_registry[value.__class__]) -- Slither
	if class then
		classkey = classkey_registry[class]
		Buffer_write_byte(buffer, 242)
		write_string(class, buffer)
	else
		Buffer_write_byte(buffer, 240)
	end
	local len = #value
	write_number(len, buffer, seen)
	for i = 1, len do
		serialize_value(value[i], buffer, seen)
	end
	local klen = 0
	for k in pairs(value) do
		if (type(k) ~= 'number' or floor(k) ~= k or k > len or k < 1) and k ~= classkey then
			klen = klen + 1
		end
	end
	write_number(klen, buffer, seen)
	for k, v in pairs(value) do
		if (type(k) ~= 'number' or floor(k) ~= k or k > len or k < 1) and k ~= classkey then
			serialize_value(k, buffer, seen)
			serialize_value(v, buffer, seen)
		end
	end
end

local types = {number = write_number, string = write_string, table = write_table, boolean = write_boolean, ["nil"] = write_nil}

serialize_value = function(value, buffer, seen)
	if seen[value] then
		local ref = seen[value]
		if ref < 64 then
			--small reference
			Buffer_write_byte(buffer, 128 + ref)
		else
			--long reference
			Buffer_write_byte(buffer, 243)
			write_number(ref, buffer, seen)
		end
		return
	end
	local t = type(value)
	if t ~= 'number' and t ~= 'boolean' and t ~= 'nil' then
		seen[value] = seen.len
		seen.len = seen.len + 1
	end
	if resource_name_registry[value] then
		local name = resource_name_registry[value]
		if #name < 16 then
			--small resource
			Buffer_write_byte(buffer, 224 + #name)
			Buffer_write_string(buffer, name)
		else
			--long resource
			Buffer_write_byte(buffer, 241)
			write_string(name, buffer, seen)
		end
		return
	end
	(types[t] or
		error("cannot serialize type " .. t)
		)(value, buffer, seen)
end

local function serialize(value)
	local buffer = Buffer_newWriter()
	local seen = {len = 0}
	serialize_value(value, buffer, seen)
	return Buffer_get(buffer)
end

local function add_to_seen(value, seen)
	insert(seen, value)
	return value
end

local function reserve_seen(seen)
	insert(seen, 42)
	return #seen
end

local function deserialize_value(buffer, seen)
	local t = Buffer_read_byte(buffer)
	if t < 128 then
		--small int
		return t - 27
	elseif t < 192 then
		--small reference
		return seen[t - 127]
	elseif t < 224 then
		--small string
		return add_to_seen(Buffer_read_string(buffer, t - 192), seen)
	elseif t < 240 then
		--small resource
		return add_to_seen(resource_registry[Buffer_read_string(buffer, t - 224)], seen)
	elseif t == 240 then
		--table
		local v = add_to_seen({}, seen)
		local len = deserialize_value(buffer, seen)
		for i = 1, len do
			v[i] = deserialize_value(buffer, seen)
		end
		len = deserialize_value(buffer, seen)
		for _ = 1, len do
			local key = deserialize_value(buffer, seen)
			v[key] = deserialize_value(buffer, seen)
		end
		return v
	elseif t == 241 then
		--long resource
		local idx = reserve_seen(seen)
		local value = resource_registry[deserialize_value(buffer, seen)]
		seen[idx] = value
		return value
	elseif t == 242 then
		--instance
		local instance = add_to_seen({}, seen)
		local classname = deserialize_value(buffer, seen)
		local class = class_registry[classname]
		local classkey = classkey_registry[classname]
		local deserializer = class_deserialize_registry[classname]
		local len = deserialize_value(buffer, seen)
		for i = 1, len do
			instance[i] = deserialize_value(buffer, seen)
		end
		len = deserialize_value(buffer, seen)
		for _ = 1, len do
			local key = deserialize_value(buffer, seen)
			instance[key] = deserialize_value(buffer, seen)
		end
		if classkey then
			instance[classkey] = class
		end
		return deserializer(instance, class)
	elseif t == 243 then
		--reference
		return seen[deserialize_value(buffer, seen) + 1]
	elseif t == 244 then
		--long string
		return add_to_seen(Buffer_read_string(buffer, deserialize_value(buffer, seen)), seen)
	elseif t == 245 then
		--long int
		return Buffer_read_data(buffer, "int32_t[1]", 4)[0]
	elseif t == 246 then
		--double
		return Buffer_read_data(buffer, "double[1]", 8)[0]
	elseif t == 247 then
		--nil
		return nil
	elseif t == 248 then
		--false
		return false
	elseif t == 249 then
		--true
		return true
	elseif t == 250 then
		--short int
		return Buffer_read_data(buffer, "int16_t[1]", 2)[0]
	else
		error("unsupported serialized type " .. t)
	end
end

local function deserialize(buffer)
	local seen = {}
	return deserialize_value(buffer, seen)
end

local function deserialize_MiddleClass(instance, class)
	return setmetatable(instance, class.__instanceDict)
end

local function deserialize_SECL(instance, class)
	return setmetatable(instance, getmetatable(class))
end

local deserialize_humpclass = setmetatable

local function deserialize_Slither(instance, class)
	return getmetatable(class).allocate(instance)
end

return {dump = nil, dumps = function(value)
	return ffi.string(serialize(value))
end, load = nil, loads = function(value)
	return deserialize(Buffer_newReader(value))
end, register = function(name, resource)
	assert(not resource_registry[name], name .. " already registered")
	resource_registry[name] = resource
	resource_name_registry[resource] = name
	return resource
end, unregister = function(name)
	resource_name_registry[resource_registry[name]] = nil
	resource_registry[name] = nil
end, registerClass = function(name, class, classkey, deserializer)
	if not class then
		class = name
		name = class.__name__ or class.name
	end
	if not classkey then
		if class.__instanceDict then
			-- assume MiddleClass
			classkey = 'class'
		elseif class.__baseclass then
			-- assume SECL
			classkey = '__baseclass'
		end
		-- assume hump.class, Slither, or something else that doesn't store the
		-- class directly on the instance
	end
	if not deserializer then
		if class.__instanceDict then
			-- assume MiddleClass
			deserializer = deserialize_MiddleClass
		elseif class.__baseclass then
			-- assume SECL
			deserializer = deserialize_SECL
		elseif class.__index == class then
			-- assume hump.class
			deserializer = deserialize_humpclass
		elseif class.__name__ then
			-- assume Slither
			deserializer = deserialize_Slither
		else
			error("no deserializer given for unsupported class library")
		end
	end
	class_registry[name] = class
	classkey_registry[name] = classkey
	class_deserialize_registry[name] = deserializer
	class_name_registry[class] = name
	return class
end, unregisterClass = function(name)
	class_name_registry[class_registry[name]] = nil
	classkey_registry[name] = nil
	class_deserialize_registry[name] = nil
	class_registry[name] = nil
end}