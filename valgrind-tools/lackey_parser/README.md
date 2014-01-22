##Lackey Parser
This tool is meant for combing Valgrind's tool lackey, with an application in order to monitor how many loads and stores happen between particular addresses. 

###Disclaimer
This was a draft about how something like this could be achieved, but this is not a useable tool in its current state. 

###Preparing Valgrind
You need to slightly patch Lackey to output normal base.10 numbers as the parser can't parse hex. It may also be useful to disable the output of Instruction Addresses (marked with the letter 'I' on Lackey's output). 
Then the Valgrind command of: `valgrind --tool=lackey --trace-mem=yes ./program program-args > log/destination 2>&1`

###Preparing the program
The program needs to tell the parser which memory blocks in particular it should watch out for. This is done by parsing from the same log which Valgrind is also outputting into with the above command.

To enable the tracking: `Start Lackey` (it is disabled at startup)  
To disable the tracking: `Stop Lackey`  
To start tracking a block: `Malloc 123start_address321, 123size_in_bytes321`  
To disable the tracking: `Free 123start_address321`

The commands which are left by lackey are proceeded by S (for store), L (for load) or M (for modify (read and write)). As an example of a parsable file with examples of how things are supposed to look in the file, take a look at sample_parsable. 

###Running lackey_parser
Once the log has been created using the methods above, run the parser on the file simply as `path/to/lackey_parser parsable_file`. It will output to the same filename with an extension. 

###Known Problems
Because of the asynchrony of Valgrind and program execution, it's very possible that the hint to start following a memory address appears after all references have already been interpreted by Valgrind. This is due to the Valgrind instrumentation always executing before any normal code. Hence the normal code will tell the log file too late about something to monitor.  