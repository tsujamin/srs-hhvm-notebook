#HipHop VM Notes

##JIT/Interpreter

##Reference Counting
The semantics of the PHP language require [reference counting][php_refcounting] to be immediate, specifically in relation to the passing and copying of arrays (Copy on Write semantics). This obviously causes some major performance penalties as each php reference mutation requires the destination objects reference count to be modified.
###Reference counting in C++ 
###Reference counting in the JIT
Some pairs of reference counting operations can be [ommited][refcount-opts.cpp] by the JIT if proven to not affect the overall reachability of objects. 

##Memory Management

##Profiling/Instrumentation 

##Achievements

##Other

[doc_references]: below
[php_refcounting]: http://www.php.net/manual/en/features.gc.refcounting-basics.php

[code_references]: below
[refcount-opts.cpp]: https://github.com/facebook/hhvm/blob/e08ed9c6369459f17a6be8cd9cf988e840fb17bf/hphp/runtime/vm/jit/refcount-opts.cpp
