-- how to use the extension API to implement templates ala
-- https://github.com/bakpakin/binser#templates

local bitser = require 'bitser'
local bitser_templates = require 'examples.bitser-templates'

bitser.registerExtension('templates', bitser_templates)

local template = {
	"name", "age", "salary", "email", "nested"
	--nested = {'more', 'nested', 'keys'}
}

local Employee_MT = {
	__name__ = 'Employee_MT',
	name = "Employee",
	_template = template
}
Employee_MT.__index = Employee_MT

local joe = setmetatable({
	name = "Joe",
	age = 11,
	salary = "$1,000,000",
	email = "joe@example.com",
	nested = {
		more = "blah",
		nested = "FUBAR",
		keys = "lost"
	}
}, Employee_MT)

bitser.registerClass(Employee_MT)
print('without templates:', #bitser.dumps(joe))
bitser.unregisterClass('Employee_MT')

bitser_templates.registerClass(Employee_MT)
print('with templates:', #bitser.dumps(joe))
