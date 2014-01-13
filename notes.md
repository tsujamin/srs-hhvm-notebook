#HipHop VM Notes

##JIT/Interpreter

##Reference Counting
The semantics of the PHP language require [reference counting][php_refcounting] to be immediate, specifically in relation to the passing and copying of arrays (Copy on Write semantics). This obviously causes some major performance penalties as each php reference mutation requires the destination objects reference count to be modified.
###Reference counting in C++ 
Parallel to the reference counting operations performed in HHVM's JIT there is another reference counting infrastructure involving precompiled C++ code. This will be referred to as the C++ Reference Counting. 

This type of reference counting is primarily implemented by the calling of various macro's defined in [countable.h][countable.h] by various counted classes (different macros exist for non-static and potentially-static reference counted objects). The macros operate on a `int_32t` field named `m_count` which is defined in each of the various reference counted classes. It is asserted that this field is at a 12 byte offset from the start of the object as defined by the `FAST_REFCOUNT_OFFSET` constant in [types.h][types.h]. A atomic variant of m_count is defined in [countable.h][countable.h].
###Reference counting in the JIT
When code is executed using the JIT a new set of reference counting functions become involved. These can be found in [code-gen-x64.cpp][cg-x64], [code-gen-helpers-x64.cpp][cgh-x64] and their respective ARM equivalents. The modification of these functions such that they perform no operation seems to disable reference counting in the JIT (this can observed by analysing the IR emmited by hhvm's printir trace). A list of these functions follows:
####[code-gen-helpers-x64.cpp][cgh-x64]
 + void emitIncRef(Asm& as, PhysReg base)
 + void emitIncRefCheckNonStatic(Asm& as, PhysReg base, DataType dtype)
 + void emitIncRefGenericRegSafe(Asm& as, PhysReg base, int disp, PhysReg tmpReg)

####[code-gen-x64.cpp][cg-x64]
 + `void CodeGenerator::cgIncRefWork(Type type, SSATmp* src)`
 + `void CodeGenerator::cgIncRef(IRInstruction* inst)`
 + `void CodeGenerator::cgIncRefCtx(IRInstruction* inst)`
 + `void CodeGenerator::cgDecRefStack(IRInstruction* inst)`
 + `void CodeGenerator::cgDecRefThis(IRInstruction* inst)`
 + `void CodeGenerator::cgDecRefLoc(IRInstruction* inst)`
 + `void CodeGenerator::cgGenericRetDecRefs(IRInstruction* inst)`
 + ```template <typename F> Address CodeGenerator::cgCheckStaticBitAndDecRef(Type type, 
 			PhysReg dataReg, Block* exit, F destroy)```
 + `void CodeGenerator::cgDecRefStaticType(Type type, PhysReg dataReg, Block* exit, bool genZeroCheck)`
 + `void CodeGenerator::cgDecRefDynamicType(PhysReg typeReg, PhysReg dataReg, Block* exit, bool genZeroCheck)`
 + `void CodeGenerator::cgDecRefDynamicTypeMem(PhysReg baseReg, int64_t offset, Block* exit)`
 + `void CodeGenerator::cgDecRefMem(Type type, PhysReg baseReg, int64_t offset, Block* exit)`
 + `void CodeGenerator::cgDecRefMem(IRInstruction* inst)`
 + `void CodeGenerator::cgDecRefWork(IRInstruction* inst, bool genZeroCheck)`
 + `void CodeGenerator::cgDecRef(IRInstruction *inst)`
 + `void CodeGenerator::cgDecRefNZ(IRInstruction* inst)`

This is may not be an exhaustive list of the functions involved; it simply lists those that were identified and modified in the process of disabling reference counting. There exists other sections of the JIT where reference counting is performed (through the direct manipulation of the data at an objects `FAST_REFCOUNT_OFFSET`) and these can be in [this branch comparison][norefcount-master-compare].

Some pairs of reference counting operations can be [ommited][refcount-opts.cpp] by the JIT if proven to not affect the overall reachability of objects. 

##Memory Management

##Profiling/Instrumentation 
###IR Tracing
HHVM can be configured to output the IR (Intermediate Representation) of each function it encounters. This is enabled by running HHVM in an environment where `TRACE=printir:2` is enabled. The trace will be found in `/tmp/hphp.log`. The JIT emiited assembly can also be output alongside the IR, but this requires HHVM to be compiled against libxed (which can be found in the tarball for [Intel PIN][intel_pin]). The subsequent cmake command is:
```cmake -DCMAKE_BUILD_TYPE=Debug 
 -DLibXed_INCLUDE_DIR=/home/benjamin/Downloads/pin-2.13-62141-gcc.4.4.7-linux/extras/xed2-intel64/include
 -DLibXed_LIBRARY=/home/benjamin/Downloads/pin-2.13-62141-gcc.4.4.7-linux/extras/xed2-intel64/lib/libxed.a```

###Jemalloc Memory Profiler Dump
The jemalloc memory profiler can be accessed through hhvm, while running in server mode through the admin interface.

For this, jemalloc must be compiled with the profiler enabled.  
`./configure --prefix=$CMAKE_PREFIX_PATH --enable-prof`

Start the hhvm in server mode, and assign an admin port. Start the jemalloc profiler:  
`GET http://hhvmserverip:adminport/jemalloc-prof-activate`  
If you get Error 2 at this point, it means you didn't compile jemalloc with the profiler enabled.

And then you can also get a jemalloc memory profiler dump by:  
`GET http://hhvmserverip:adminport/jemalloc-prof-dump`

If successful, a file starting with `jeprof` should appear in the directory that hhvm was started from.  
If however you got `Error 14` when attempting to get the jemalloc-prof-dump, it probably means that the leak memory profiler wans't enabled in jemalloc. This can be enabled by changing the jemalloc sources.  
`jemalloc/src/prof.c:25: bool opt_prof_leak = true;`

To get all possible jemalloc commands, check the admin interface of hhvm.

###HHProf (pprof compatible)
For the hhprof, you need to enable it in the compile flags of hhvm.  
`-DMEMORY_PROFILING`
To make this part of debug mode, you can add it to hhvm/CMake/HPHPSetup.cmake . In the if statement for `CMAKE_BUILD_TYPE`, you can add it underneath `add_definitions(-DDEBUG)` as `add_definitions(-DMEMORY_PROFILING)`

You also need to enable it during runtime using `-vHHProfServer.Enabled=true`  
Other HHProfServer options are:  
```
-vHHProfServer.Port                    -- 4327
-vHHProfServer.Threads                 -- 2
-vHHProfServer.TimeoutSeconds          -- 30
-vHHProfServer.ProfileClientMode       -- true
-vHHProfServer.AllocationProfile       -- false
-vHHProfServer.Filter.MinAllocPerReq   -- 2
-vHHProfServer.Filter.MinBytesPerReq   -- 128
```

Just list with jemalloc, you can then activate and deactivate HHProf using:  
`GET http://localhost:4327/hhprof/start`  
`GET http://localhost:4327/hhprof/stop`

You can then access the HHProf server using pprof:  
`pprof http://localhost:4327/pprof/heap`

##Achievements

##Other

[references]: below
[php_refcounting]: http://www.php.net/manual/en/features.gc.refcounting-basics.php
[intel_pin]: http://download-software.intel.com/sites/landingpage/pintool/downloads/pin-2.13-62141-gcc.4.4.7-linux.tar.gz

[code_references]: below
[refcount-opts.cpp]: https://github.com/facebook/hhvm/blob/e08ed9c6369459f17a6be8cd9cf988e840fb17bf/hphp/runtime/vm/jit/refcount-opts.cpp
[cg-x64]: https://github.com/facebook/hhvm/blob/e08ed9c6369459f17a6be8cd9cf988e840fb17bf/hphp/runtime/vm/jit/code-gen-x64.cpp
[cgh-x64]: https://github.com/facebook/hhvm/blob/e08ed9c6369459f17a6be8cd9cf988e840fb17bf/hphp/runtime/vm/jit/code-gen-helpers-x64.cpp
[norefcount-master-compare]: https://github.com/TsukasaUjiie/hhvm/compare/master...consistant_refcounting#diff-346a8263f676cff3a20324eb9fb34231R4199
[countable.h]: https://github.com/TsukasaUjiie/hhvm/blob/master/hphp/runtime/base/countable.h
[types.h]: https://github.com/facebook/hhvm/blob/e08ed9c6369459f17a6be8cd9cf988e840fb17bf/hphp/runtime/base/types.h
