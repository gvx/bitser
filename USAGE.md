* [Basic usage](#basic-usage)
* [Serializing class instances](#serializing-class-instances)
* [Advanced usage](#advanced-usage)
* [Reference](#reference)

# Basic usage

```lua
local bitser = require 'bitser'

-- some_thing can be almost any lua value
local binary_data = bitser.dumps(some_thing)

-- binary_data is a string containing some serialized value
local copy_of_some_thing = bitser.loads(binary_data)
```

Bitser can't dump values of type `function`, `userdata` or `thread`, or anything that
contains one of those. If you need to, look into [`bitser.register`](#register).

# Serializing class instances

(I need to finish this section.)

## Supported class libraries

* MiddleClass
* SECL
* hump.class
* Slither
* Moonscript classes

# Advanced usage

(I need to finish this section.)

# Reference

## dumps

```lua
local string = bitser.dumps(value)
```

Basic serialization of `value` into a Lua string.

See also: [`bitser.loads`](#loads).

## dumpLoveFile

```lua
bitser.dumpLoveFile(file_name, value)
```

Serializes `value` and writes the result to `file_name` more efficiently than serializing to a string and writing
that string to a file. Only useful if you're running [LÖVE](https://love2d.org/).

See also: [`bitser.loadLoveFile`](#loadlovefile).

## loads

```lua
local value = bitser.loads(string)
```

Deserializes `value` from `string`.

See also: [`bitser.dumps`](#dumps).

## loadData

```lua
local value = bitser.loadData(light_userdata, size)
```

Deserializes `value` from raw data. You probably won't need to use this function ever.

## loadLoveFile

```lua
local value = bitser.loadLoveFile(file_name)
```

Reads from `file_name` and deserializes `value` more efficiently than reading the file and then deserializing that string.
Only useful if you're running [LÖVE](https://love2d.org/).

See also: [`bitser.dumpLoveFile`](#dumplovefile).

## register

```lua
bitser.register(name, resource)
```

Registers the value `resource` with the name `name`, which has to be a unique string. Registering static resources like images,
functions, classes and huge strings, makes sure bitser doesn't attempt to serialize them, but only stores a named
reference to them.

See also: [`bitser.unregister`](#unregister).

## registerClass

```lua
bitser.registerClass(class)
bitser.registerClass(name, class)
bitser.registerClass(name, class, classkey, deserializer)
```

Registers the class `class`, so that bitser can correctly serialize and deserialize instances of `class`.

Note that if you want to serialize the class _itself_, you'll need to [register the class as a resource](#register).

Most of the time the first variant is enough, but some class libraries don't store the
class name on the class object itself, in which case you'll need to use the second variant.

Class names also have to be unique, so if you use multiple classes with the same name, you'll need to use the second
variant as well to give them different names.

The arguments `classkey` and `deserializer` exist so you can hook in unsupported class libraries without needing
to patch bitser. [See the list of supported class libraries](#supported-class-libraries)

If not nil, the argument `classkey` should be a string such that
`rawget(obj, classkey) == class` for any `obj` whose type is `class`. This is done so that key is skipped for serialization.

If not nil, the argument `deserializer` should be a function such that `deserializer(obj, class)` returns a valid
instance of `class` with the properties of `obj`. `deserializer` is allowed to mutate `obj`.

See also: [`bitser.unregisterClass`](#unregisterclass).

## unregister

```lua
bitser.unregister(name)
```

Deregisters the previously registered value with the name `name`.

See also: [`bitser.register`](#register).

## unregisterClass

```lua
bitser.unregisterClass(name)
```

Deregisters the previously registered class with the name `name`. Note that this works by name and not value,
which is useful in a context where you don't have a reference to the class you want to unregister.

See also: [`bitser.registerClass`](#registerclass).

## reserveBuffer

```lua
bitser.reserveBuffer(num_bytes)
```

Makes sure the buffer used for reading and writing serialized data is at least `num_bytes` large.
You probably don't need to ever use this function.

## clearBuffer

```lua
bitser.clearBuffer()
```

Frees up the buffer used for reading and writing serialized data for garbage collection.
You'll rarely need to use this function, except if you needed a huge buffer before and now only need a small buffer
(or are done (de)serializing altogether). Most of the time, using this function will decrease performance needlessly.
