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

A modified version of HipHopVM ([hhvmnocount][hhvmnocount]) was created in which reference counting operations (such as those in [countable.h][countable.h], the JIT and various direct manipulations) were removed. When compared to a clean build of HHVM this modified version ran much slower due to wildly different memory usage characteristics; the clean build was able to reuse free'd memory through its Memory Manager whilst hhvmnocount continuously allocated new memory.

In order to isolate the effects of reference counting the memory manager was modified. These modifications include:

- Disabling of memory freeing (even at requests end)
- Removing of free list based allocator
- Single case treatment for all object sizes

The 'sweeping' of memory (a process usually performed before their freeing to deallocate any self-managed memory) was still preformed as, without it, assets like databases and files became unusable (due to too many instances). These modifications resulted in the [hhvmbump][hhvmbump] and [hhvmbumpnocount][hhvmbumpnocount] builds.

These modified builds were unable to run standard PHP applications (such as the Wordpress CMS). As such a modified version of an included HHVM benchmark ([center-of-mass.php][center-of-mass.php]). While it does not accurately represent a standard PHP request it does make heavy usage of the memory subsystems. The configuration used for benchmarking was:

- Linux kernel version: 3.12.6-300.fc20.x86_64
- CPU: Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz
- Memory: 4x4G DDR3 memory at 1600MHz (no swap partiton)
- internal ssd for HHVM builds
- Release configuration
- Apache Benchmark (ab) with various levels of concurrency and test lengths
- Results graphed using Matlab
- All sources and results available [here][srs_notebook]

###Results:
Unfortunately due to segmentation faults in Release mode: hhvmnocount was omitted from the following graphs.

![Time taken for the quickest 50% of requests to execute (lower is better)](images/percentage_50_surf_graph_s.png "Time taken for the quickest 50% of requests to execute (lower is better)")

Figure 1 shows that the hhvmbumpnocount build, which logically should have performed the least operations due to its lack of reference counting, performed consistently worse than hhvmbump.

![Average requests per second of benchmark (higher is better)](images/request_ps_surf_graph_s.png "Average requests per second of benchmark (higher is better)")

![Total execution time of benchmark (lower is better)](images/total_time_surf_graph_s.png "Total execution time of benchmark (lower is better)")

Figures 2 and 3 show respectively that hhbmbump no count processed the least requests per second and took overall the longest amount of time to execute the benchmarks.

###Analysis
This data was gathered late in the project timeline so the following analysis is fairly rough. One major issue 

[render_command]: pandoc report.md -o report.pdf
[references]: below
[hhvm_github]: https://github.com/facebook/hhvm
[srs_notebook]: https://github.com/TsukasaUjiie/srs-hhvm-notebook

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
