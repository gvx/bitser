--- Serialize ---
bitser = require "bitser"

class A
  @o = 0
  new: (@b) =>
  u: => @@o += 1
  i: => @b += 5

instance = A 19

print A.o
instance\u!
print A.o

print instance.b
instance\i!
print instance.b

bitser.registerClass A

file = io.open 'output.txt', 'w'
file\write bitser.dumps instance
file\close!


--- Clean Up ---
file = nil
instance = nil
bitser = nil
package.loaded.bitser = nil
collectgarbage!


--- Deserialize ---
bitser = require "bitser"

file = io.open 'output.txt', 'r'
data = file\read!

bitser.registerClass A
print A.o
instance = bitser.loads data

print A.o
instance\u!
print A.o

print instance.b
instance\i!
print instance.b