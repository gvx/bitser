local bitser = require 'bitser'

local function serdeser(value)
	return bitser.loads(bitser.dumps(value))
end

local function test_serdeser(value)
	assert.are.same(serdeser(value), value)
end

describe("bitser", function()
	it("serializes simple values", function()
		test_serdeser(true)
		test_serdeser(false)
		test_serdeser(nil)
		test_serdeser(1)
		test_serdeser(-1)
		test_serdeser(0)
		test_serdeser(100000000)
		test_serdeser(1.234)
		test_serdeser(10 ^ 20)
		test_serdeser(1/0)
		test_serdeser(-1/0)
		test_serdeser("")
		test_serdeser("hullo")
		test_serdeser([[this
			is a longer string
			such a long string
			that it won't fit
			in the "short string" representation
			no it won't
			listen to me
			it won't]])
		local nan = serdeser(0/0)
		assert.is_not.equal(nan, nan)
	end)
	it("serializes simple tables", function()
		test_serdeser({})
		test_serdeser({10, 11, 12})
		test_serdeser({foo = 10, bar = 99, [true] = false})
		test_serdeser({[1000] = 9000})
		test_serdeser({{}})
	end)
	it("serializes tables with tables as keys", function()
		local thekey = {"Heyo"}
		assert.are.same(thekey, (next(serdeser({[thekey] = 12}))))
	end)
	it("serializes cyclic tables", function()
		local cthulhu = {{}, {}, {}}
		cthulhu.fhtagn = cthulhu
		--note: this does not test tables as keys because assert.are.same doesn't like that
		cthulhu[1].cthulhu = cthulhu[3]
		cthulhu[2].cthulhu = cthulhu[2]
		cthulhu[3].cthulhu = cthulhu

		test_serdeser(cthulhu)
	end)
	it("serializes resources", function()
		local temp_resource = {}
		bitser.register("temp_resource", temp_resource)
		assert.are.equal(serdeser({this = temp_resource}).this, temp_resource)
		bitser.unregister("temp_resource")
	end)
	it("serializes many resources", function()
		local max = 1000
		local t = {}
		for i = 1, max do
			bitser.register(tostring(i), i)
			t[i] = i
		end
		test_serdeser(t)
		for i = 1, max do
			bitser.unregister(tostring(i))
		end
	end)
end)