This document lays out the API provided for extension authors by bitser.

An extension object is a table that contains at least the following keys:

* `"bitser-type"`: a string, like `"userdata"`. The extension will only be
  used to serialize a value `v` if `type(v)` equals the value of this key.
  A value of this type is called a "potential match" in the rest of this
  document. Note that this type does not need to be natively supported by
  bitser.
* `"bitser-match"`: a function that takes a single argument and returns a
  boolean. The extension will only be used if this function returns `true`.
  It does not need to check `type(v)`, as it will only be called for potential
  matches.
* `"bitser-dump"`: a function that takes a single potential match as argument
  and returns a single value that bitser is able to serialize (either natively
  or through an extension).
* `"bitser-load"`: a function that takes a single argument that is a
  deserialized copy of a value previously returned by the dump function, that
  returns a potential match.

All other keys will be ignored, but string keys that start with `"bitser-"`
are reserved for future versions of this API.

Extension authors SHOULD NOT call `bitser.registerExtension`. This should be
left to extension users, so they may choose an ID that does not conflict with
other extensions they may be using.

The matching function SHOULD be highly performant, as it is called for every
potential match that is to be serialized.
