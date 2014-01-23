% An Analysis of Memory Management in HipHopVM
% Benjamin Roberts, Nathan Yong, Jan Zimmer
% HHVM Group, Summer Research Scholarship 2013/14

#Background
HipHopVM is an Free and Open Source PHP engine written primarily in C++, with moderate amounts of PHP and x86_64 assembly, totalling approximately 1.2 million lines of code. It uses a Just In Time compiler, though historically it translated PHP to C++ for ahead of time compilation. It is the primary PHP backend used on Facebook's infrastructure.

#Our Tasks
Our specific tasks as part of the ANU Summer Research Scholarship were to:
 - To isolate the affect of naive reference counting on HHVM's performance (Benjamin Roberts)
 - To observe how memory access maps to actual physical memory access (Jan Zimmer)
 - To map and analyse the behaviour of HHVM's internal memory management (Nathan Yong)
 
##HHVM Without Reference Counting (Benjamin Roberts)
When using an allocator which free's all allocated memory at request end (such as that used in HHVM), the immediate reclamation provided by naive reference counting become less attractive. Whilst the semantics of the PHP language enforce the use of naive reference counting we can still try to analyse its impact.



[render_command]: pandoc report.md -o report.pdf
[references]: below
[hhvm_github]: https://github.com/facebook/hhvm

[code_references]: below
[countable.h]: https://github.com/TsukasaUjiie/hhvm/blob/master/hphp/runtime/base/countable.h
[center-of-mass.php]: https://github.com/TsukasaUjiie/srs-hhvm-notebook/blob/master/refcount_analysis/benchmarks/center-of-mass.php

[repo_branches]: below
[inconsistant_refcounting_commit]: https://github.com/TsukasaUjiie/hhvm/commit/8ed7fcac87a3b9dc9d07078a619c2db1506089b4
[norefcount-master-compare]: https://github.com/TsukasaUjiie/hhvm/compare/master...consistant_refcounting#diff-346a8263f676cff3a20324eb9fb34231R4199
[hhvmclean]: https://github.com/TsukasaUjiie/hhvm/tree/master
[hhvmnocount]: https://github.com/TsukasaUjiie/hhvm/tree/consistant_refcounting
[hhvmbump]: https://github.com/TsukasaUjiie/hhvm/tree/master-bumppoint
[hhvmbumpnocount]: https://github.com/TsukasaUjiie/hhvm/tree/bump-point-no-refcounting
