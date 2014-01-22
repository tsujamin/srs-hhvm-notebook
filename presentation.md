% An Analysis of Memory Management in HipHopVM
% Benjamin Roberts, Nathan Yong, Jan Zimmer
% HHVM Group, Summer Research Scholarship 2013/14

#What is a HipHopVM?


##Background
 - HipHopVM is an Free and Open Source PHP engine
 - Written primarily in C++ with moderate ammounts of PHP and x86_64 assembly
 - It uses a JIT compiler (though historically was a PHP to C++ transpiler)
 - It is the PHP engine designed by and which hosts Facebook
 - Its on GitHub! [https://github.com/facebook/hhvm][hhvm_github]


##Our Tasks
 - To isolate the affect of naieve reference counting on HHVM's performance
 - JAN
 - NATHAN

----------------------

Before continuing we will briefly introduce some relevant concepts


#Internals of HHVM

##Reference Counting in the PHP language

[links]: below
[hhvm_github]: https://github.com/facebook/hhvm