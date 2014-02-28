Uneval
======

Ruby Object Serialization in Text Script Format


Synopsis
========
first:
```ruby
  require 'uneval' 
```
or copy it somewhere.

```ruby
>print Uneval.dump(3)
3
>print Uneval.dump("Hello world") 
"Hello world"
>print Uneval.dump([1,2,3])
"[
1,
2,
3,
]"
>print Uneval.dump({:a=>3, :b=>5})
Hash[[
[
    :a,
    3],
[
    :b,
    5],
 ]]
>print Uneval.dump [1,2,3,{4=>5,6=>:symbol}]
[
    1,
    2,
    3,
    Hash[[
    [
        4,
        5],
    [
        6,
        :symbol],
     ]],
 ]

```





Brief
=======

Marshal is good enough, but it's not very friendly to modify by hand.

Yaml is good enough, however, I can not get any YAML library to work in my RPG Maker, a limited Ruby environment.


So there comes Uneval.

By 'to serialize something', we mean save the object's inner states.

But we know a Ruby object can have even zero states(it behaviors differently by changing singleton methods other than instance_variables.

So we define three properties here about what and how Uneval dumps an object.

An object can be uneval-dumped must satisfy one or more of following:

1) eval(obj.inspect) == obj    i.e. obj is a primitive-like object, e.g. 3, "123", /abc/

2) obj.methods.grep(/=/).all?{|x|

     obj.respond_to?(x.to_s.chop) and

     #we always assume after setting obj.x=y, then whenever we have obj.x == y until we change it again

   }

   i.e. obj is like a 'struct' object, or its methods are all defined by attr_accessor

3) We can safely assume after setting obj[x] = y, then whenever we have obj[x] == y until we change it again.

   In this case, we assume obj is like an Array or a Hash object.


As a convention, we assume the object can be converted from a nullary constructed object.

i.e. no matter what the object was, it can be converted from another obj = T.new.

  

