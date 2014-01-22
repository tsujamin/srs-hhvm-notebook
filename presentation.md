% An Analysis of Memory Management in HipHopVM
% Benjamin Roberts, Nathan Yong, Jan Zimmer
% HHVM Group, Summer Research Scholarship 2013/14

#What is a HipHopVM?


##Background
 - HipHopVM is an Free and Open Source PHP engine
 - Written primarily in C++ with moderate amounts of PHP and x86_64 assembly
 - It uses a JIT compiler (though historically it translated PHP to C++ for AOT compilation)
 - It is the PHP engine designed by and which hosts Facebook
 - Its on GitHub! [https://github.com/facebook/hhvm][hhvm_github]


##Our Tasks
 - To isolate the affect of naive reference counting on HHVM's performance
 - JAN
 - NATHAN

----------------------

Before continuing we will briefly introduce some relevant concepts


#Internals of HHVM

##Reference Counting in the PHP language
 - Based on explicit garbage collection (reference counting)
 - Required by language semantics
 - PHP is **pass by value**

-----------------------

 - Pass by value can be slow due to large amount of copies (especially with large arrays)
 - Solution: Copy on Write!
 - Problem: Need to know current reference count
 - Each mutation requires immediate increment and decrement of reference counts
 - Advantage: Immediate garbage reclamation 

##Reference Counting in HHVM (C++)
 - Reference counted objects have an `int_32t m_count` field and call a macro in [countable.h][countable.h] containing various reference counting operations (`incRefCont()`, `hasMultipleRefs()`, `decRefAndRelease()` etc)
 - Not consistently used (certain places directly mutate `m_count` or define separate ref-counting methods)
 - Difficult to track down all mutations of `m_count`

##Reference Counting in HHVM (JIT)
 - `int_32t m_count` at a common offset (12 bytes) in all refcounted objects
 - Several opcodes emit reference counting assembly via the JIT
 - Simpler to locate, more difficult to understand
 - **Both these systems operate separately from each other (while sharing `m_count`) and the memory manager**
 
##Memory Management

##OTHER

#Our Tasks

##HHVM Without Reference Counting

##JAN TASK

##NATHAN TASK

#Conclusion and Further Work
[render_command]: pandoc -t beamer presentation.md -V theme:Warsaw -o presentation.pdf
[references]: below
[hhvm_github]: https://github.com/facebook/hhvm

[code_references]: below
[countable.h]: https://github.com/TsukasaUjiie/hhvm/blob/master/hphp/runtime/base/countable.h

