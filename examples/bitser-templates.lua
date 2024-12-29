-- this implements a simplified form of binser templates (without nested keys)

local templates_by_identity = {} -- template -> name
local templates_by_name = {}
local class_by_templatename = {}

local function bitser_match(value)
	return value._template ~= nil and templates_by_identity[value._template]
end

local function bitser_dump(value)
	local templatename = templates_by_identity[value._template]
	local template = templates_by_name[templatename]
	local output = {templatename}
	local extras = {}
	for k, v in pairs(value) do
		extras[k] = v
	end
	for i, key in ipairs(template) do
		output[i + 1] = extras[key]
		extras[key] = nil
	end
	output[#output + 1] = extras
	return output
end


local function bitser_load(value)
	local templatename = value[1]
	local obj = {}
	local template = templates_by_name[templatename]
	for i, keyname in ipairs(template) do
		obj[keyname] = value[i + 1]
	end
	for k, v in pairs(value[#value]) do
		obj[k] = v
	end
	return setmetatable(obj, class_by_templatename[templatename])
end

local function register(class, name)
	name = name or class.name
	templates_by_identity[class._template] = name
	templates_by_name[name] = class._template ---parse_template(class._template)
	class_by_templatename[name] = class
	return class
end

return {
	registerClass = register,
	["bitser-type"] = 'table',
	["bitser-match"] = bitser_match,
	["bitser-dump"] = bitser_dump,
	["bitser-load"] = bitser_load,
}
