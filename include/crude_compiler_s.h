// "
// Current poor-man's makefile:
// gcc -fpic -nostartfiles -nostdlib -Wall -g -gdwarf-4 -g3 -F dwarf -m64 crude_compiler.S libmb_s.s -o crude_compiler.elf64 && ./crude_compiler.elf64; echo $?
// Though ultimately I'm using `compile_w_debug.sh` and `compile_optimized.sh` until I can get proper makefile support online.

// 2023-06-25T05:23-07:00 current status:
// subroutineTests are all functioning properly now.
// Next issue is I'm chafing at the performance penalties of ESR's tapview.sh
// I'm doing some quick research on Bash script benchmarking strats before trying
// to bring this up as an issue on his https://gitlab.com/esr/tapview repo
// CGPT suggests `bashprof` which appears to be a python module, so going
// through the snowball of upgrading my python thus upgrading my debian distro.

// 2023-06-23T23:31-07:00 current status:
// adding lots of rigor to subroutine tests
// Current status: in `subroutineTests`, I get part 3 of both decimal tests failing.
// (later ed note: problem was that the endianness of my mask was backwards)

// 2023-06-04T10:07-07:00 simple idea note:
// give weight to syntax sugar for "swizzling" which is
// a method of (short?) vector shuffling popular among shader coders.
// (later ed note:) where did I hear this from though? I want to remember
// the context for the motivation of this idea now. 😭
//
// Also: first draft/placeholder termonology for the counterintuitive
// synthesis of design goals I want to champion sportsmanlike participation in.
// ChatGPT suggested "Semantic Gap" to describe the situation where
// high and low level coding take on disparate short-term abstraction goals.
// ChatGPT rebuffed but failed to offer better options than my ideas of
// "Eloi" and "Morlock" to name the specific perspectives.
//
// * Eloi: The high level coder creating code policed by the compiler with
// strong data types, simplified environmental abstractions that
// *intentionally* render hardware realities as opaque, and restrictive
// flow control such as [immutable variables/lambda purity/no gotos].
// Events that happen under Eloi control are often described as "runtime".
//
// * Morlock: The low level compiler decisions which may *enforce* restrictive
// discipline out of the Eloi, but which are also uniquely licensed to ignore
// those restrictions wholesale when generating and especially optimizing
// bytecode and/or assembly code based upon the clean Eloi source.
//
// One optimization decision I wanted to throw upon the Semantic Gap alter
// is the possibility that while Eloi are both forced to assume that every
// element in the data stack is a full SIMD-width vector (as well as LITERALLY)
// never being ALLOWED to learn what that SIMD-width actually is)
// and that scalars on the stack are actually repeated in every lane,
// I may in fact allow Morlock compiler optimization to break that principle in
// practice by specifically mandating either 64-bit scalar chunks be thrown
// onto the stack — misaligning it and then *maybe* every now and then pad-aligning
// it — or even 32/16/8 bit chunks as well given the expectation that the
// Morlock compiler optimizations will be able to always keep track of
// exact sizes and offsets for this stack and encode those directly into the
// program flow.

// 2022-05-14T07:50-07:00 current status:
// I'unno man, I should just make the IteratableRAM generator
// handle the offsets as bytes, and if the state is client-modifiable
// (like a stack of vectors for example) then client can shift the byte offset.

// 2022-05-13T04:10-07:00 current status:
// As of May 13, we have a "IterableReduce" verb that works over
// iterables that are:
// * UnsignedInterger64 ByteLength
// * UnsignedInterger64 ByteLength (duplicate)
// * [however many you need to fill one vector]
// * VectorArray of data
// Starting today, I want to rework that tested-and-working approach
// into something different.
// I want every Iterator to be a Generator.
// A generator is a macro that consumes a fixed number of vectors of
// "state" from the stack, and replaces it with: 1. the "next" state, 2. the vector of data
// indicated by the last state, and 3. the valid bitmask over said vector.
// Each generator can offer it's own constraints on what bitmasks are valid
// to expect from it. Many of mine for example will guarantee that
// all bits in the same byte/Bitfield8 will hold the same value
// (eg, that its a bytemask).
// I WAS thinking that verbs like Reduce could treat a generator like a black
// box, but now I am leaning more towards disbanding "general iterator verbs"
// in favor of "caller uses this generator however they feel like".
// For example, I feel like reduce over a generator boils away completely into a
// trivial problem for the caller.
// Generators are unfettered from Crude constraints, being Crude
// verbs themselves. (Although Crude users can make their own too)
// There will also be (at least) two broad types of generator
// ("iterable" is the subject and/or product of a generator):
// Random Access and Stream.
// The difference is that caller is allowed to hold multiple state instances
// over the same iterable of a Random Access Stream, and those generators
// probably come with seek facilities (verbs? helpers? something else?)
// that I haven't worked out the nature of yet since tokenizer is not seeking yet.
// Stream Iterables "forget their past". Once you've pulled a vector using a
// state, that state is not guaranteed to be valid anymore, and you aren't
// offered any opportunities to seek.
// -----
// Tokenizer will use, in particular:
// == IterableRAM (Random Access Iterable)
// It's state vector will consist of:
// Pointer to the beginning of the RAM Iterable described above (length at beginning)
// Current Byte offset
//
// == IterableFilemap (Stream Iterable)
// (IterableRAM) inputs (pointer and current byte offset)
// Kernel Filehandle
// Buffer size in bytes. [buffer.length only indicates valid bytes in current buffer-worth of data].
//
// (below will probably not be used by tokenizer)
// == IterableDefoam (Stream Iterable)
// You pass it another generator function and ITS state,
// as well as an accumulator vector and mask.
// STOP CODE: this is where it feels like things are getting problematic.
// IterableDefoam will produce a guaranteed left-packed bitfield concatenated
// onto your accumulator, further guaranteed to end the full iterable
// at the end of the result mask it gives you.
// Calling it again after that will leave input accumulator untouched.
// It operates by pulling vectors from the argument generator,
// packing all bits to the left and concatenating them onto the accumulator,
// until either it fills a whole vector: then it returns
// accumulator and "all valid" mask;
// or it gets a "no valid" mask from its argument generator:
// then it returns the accumulator thus far and whatever mask describes it.

// == IterableNextToken (possibly caller-land, stream iterable)
// State should envelope an IterableFilemap, and a "last found token" vector.
// It will pull vectors from IterableFilemap searching for an end to whitespace
// from it's previous position, and once it finds an end to whitespace it
// will shift the filemap byte offset forward by that many bytes, and perform
// a token match attempt.
//
//
// == Eventually, IterableFileMMAP (Random Access Iterable, with seek performance penalty)
// This will be a lot like IterableFilemap except using the MMAP facility.
// Details not yet decided as I'm not YET using it, but I know it may inevitably
// get drafted into service.
//
// ------
// Current plan is to define input source code as an IterableFilemap,
// and token dictionary as an IterableRAM.


// 2022-04-22T14:35-07:00 planning note:
// Hmm, I've had a potential breakthrough.
// I think I can make `reduce` parallelizable. 🤓
// That wasn't even the problem I was trying to solve.
// Background: `reduce` is a common iterable verb to other languages,
// like Elm, Haskell, Tensorflow, etc.
// If you have a list of data, `reduce` allows you to perform one
// function (lambda) upon each data element (one at a time, eg serially)
// that accepts one data element and an "accumulator"
// of user-defined shape.
// The lambda will process the data element to evolve the accumulator,
// and output the new accumulator that gets fed into the lambda with
// the succeeding data element to repeat the cycle.
// It's the essence of an assembly line.
// So, normally running through N elements takes N iterations
// since for each data element to be processed you have to know
// what output you'll get from the preceeding data element.
// But I have potentially found a new — SIMD-performant way to look at
// the problem which might reduce that big O from N to
// something closer to log₂(n) assuming one has enough
// SIMD lanes. One never does, but the algorithm I'm proposing
// would still allow big speedups for every 2^K data lanes
// one does have available to them.
// Ultimately, my algorithm gathers and curries 2^K data elements
// in K steps to create a huge curried function that ought to be
// able to accept 1 input accumulator and spit out the correct
// accumulator for 2^K elements down.


// 2022-04-22T01:23-07:00 current status:
// OK, I've got some more inspiration to work from about
// how to standardize iterable operation.
// 1: A RAM Iterable is a static one in RAM.
// Could be a buffer you read into with sysread or MMAP
// or read back out of with syswrite or.. uh.. MMAP,
// Could be a literal. You could probably build and manipulate
// one as well, though I'm not yet certain how.
// * Pointer to length (broadcast scalar Bitfield64)
// ** Length must be in BYTES.
// ** Length is succeeded in RAM by the actual data.
// ** Caller has to keep track of whether data is something that
//    can always be guaranteed to be aligned or not.
// 2: A generator is yet to be specifed: to be decided.
// 3: A LOOP will be its own class of critter.
// * It will consist of:
// ** A metafunction (with at least one simple exemplar in crude_compiler)
// ** A Call Stack frame
// *** Last item in call stack frame: address of metafunction
// **** This is handled automatically by "call <lambda>".
// *** Before that, in unknown order — ultimately decided by the metafunction:
// *** address of iterable data
// *** length in bytes of iterable data
// *** Current SIMD Vector index within iterable
// **** EG, address + (index * SIMD_WIDTH) = current location in RAM we're dealing with
// *** Address of "last" clause in this metafunction
// *** Address of Lambda (code that gets looped)
// You can call loop metafunction giving it above data..
// .. possibly just by creating the call stack frame. What do I know?
// .. or I use some looping verb in Crude.
// Loop metafunction either writes and/or reads stack frame, then
// puts the first or next vector onto the stack, and invokes lambda.
// lambda ends with "ret" (or verb-alias "next")
// , which represents "next item".
// Crude will offer a "last" verb, which pops the metafunction
// address off of the callstack and then calls
// the metafunction's "last" pointer.
// Metafunction gets called on ret/next
// due to shape of stack frame.
// It can bail if "last" clause gets called,
// or fail through to last clause if it notices
// that there is no "next" (++index>=length).
// metafunction should also mask final vector of elements
// to match byte length automatically.
// Metafunction:last bails by going through the mundane libc-inspired
// process of unrolling the stack frame via rsp/rbp and then
// performing one final ret.

// 2022-04-21T19:49-07:00 current status:
// I will try to go with the maxim:
// Iterable in RAM is prefixed with 1 SIMD_WIDTH of
// bitfield64 scalar broadcast length of iterable.
// Current fuzzy point: unit length is kept in?
// Bits? Bytes? Cannot be vector lengths. Caller-defined size?

// 2022-04-21T0056-0700 current status:
// OK, I'm writing up a way to loop over the tokens and test for
// more than one against the input. However, I run into the new snag
// of 'How do I know when I'm done with the loop?'.
// This is a problem fundamental to Crude:
// iterables will usually have an end (unless they are endless generators)
// that tells the code when they need to stop looping.
// The best stab I've been able to make so far is
// to define a label "endOfTokenLiterals" at the end.. well..
// of the token literals.
// I can easily do the same for the input buffer, begin + length.
// Now how to fold this finiteness into the fundamental structure
// of how to loop over iterable like structures in RAM.
// Additionally, how to handle when the number of lanes is not
// evenly divisible by the vector lane width. Such as, when read input
// was less than buffer length.

// 2022-04-18 current status:
// Simple token match w/o trim or loop over multiple tokens is working! :D
// Next: need loop over multiple tokens,
// then: need trim

// 2022-04-18 current status:
// Current hangup: agonizing over how every verb should get shortened
// to 15 char or less. Rude truncation is an option I am leaving
// on the table, but graceful renaming is being considered first.
//
// Creating first draft tokenizer token list in
// `tokenizer vocabulary.txt` and `tokenizer_tokens.S`.
// I have decided:
// * Each token in this list will be SIMD_WIDTH aligned.
// * Each will be null terminated
// * The maximum token length I will currently allow is 15 bytes.
// * * This limitation can easily go away
//     the instant I have functioning iterables.
// This way, I can do full-token comparisons in each vector.
// Input stream is handled in chunks, where a chunk starts at
// the end of any example of whitespace.
// That's how we'll always know where in an input stream EVERY
// valid token should START, and we can do all token comparisons
// against that start point and win alignment macro-optimizations.
// Null can be found and converted into a mask
// Mask both token read into vector and input stream read into vector,
// making everything >= the index where the token null was found
// into null in both vectors.
// Then it's a simple "full vector equal", first matching token wins. :)

// 2022-04-17 current status:
// All Bitfield8 operations successfully tested.
// Next up, back to the tokenizer.
// How should I charactarize the tokens I want to search for?
// 1. loose strings in a list, indexed by memory address?
// 2. some kinda btree-like thing? How would I index that?
// What kinda 2-pass parallelizing am I planning here,
// since I do want to iterate over all the bytes in a register
// in parallel.

// 2022-04-17 current status:
// Currently on MaskBlend: needs a rename to clarify data size too.
// Mocking up 8-bit lane instruction variants of as many
// 64-bit lane instructions as I can easily do.
// Goal: try to make a tokenizer, and write up bits using
// pure ASM wherever Crude language doesn't yet have what
// it takes.. including whenever I want to deal with anything iterable.
// Then, once I've got some pain under my belt making vectors
// iterate for me over a concrete problem, it will be that much easier
// to abstract the tool and make real Crude iterables next.

// 2022-04-16 current status:
// Ackermann benchmarks are complete, current results posted to a text file.
// "Writing crude" at this stage is writing an Assembly .S file
// that uses nothing but labels, and Crude's collection of Assembly macros.
// As a result, you interact with the data stack, with the labels
// (sometimes pushing them onto the stack and sometimes directly invoking them)
// and with immediates. But you never directly interact with Memory or
// with Registers.

// Next up: I've got to work out how iterables should work.
// * Premise: an iterable is a list of scalar data objects.
// * Premise: At least for now, said list will be primarily represented by
//   a contiguous block of *lane zero aligned* RAM. Later I might support
//   memory fragmentation, or do strange things with virtual memory pages
//   or something, but not today. There may also be optimizations which
//   represent working fragments of said structures temporarily entirely
//   within registers, but again, not today.
// * Premise: I gotta figure out where these iterables will live.
// * * Do I stow them onto the existing data stack somehow?
// * * If not, then I'm stowing their pointers there and they exist
//     elsewhere in RAM.
// * * Where in RAM?
// * * Will I make a heap in my originally MMAP'ed data store?
// * * Or will I MMAP new data stores?
// * * What strategy would be the friendliest to RAM caches I wonder,
//     aside from the obvious "align 0 lanes to 64 byte blocks".
// * Premise: I must devise some way to act upon an iterable, wherein
//   Crude would automatically decide based both upon scalar data width
//   and upon SIMD register width how many lanes of data to process at a time
//   and just git'r'dun without caller having to micromanage a pump.
// * Premise: I will eventually need to act upon N input iterables (presumably whose
//   pointers are lined up on the top of the Data Stack) and output
//   M output iterables (left in place of the N inputs on top of the stack).
// * For example, A + B = C .. 2 input iterables, 1 output iterable.
//   A / B = C remainder D, etc.
// * I'll need a way to store either first-lane-only, or all-lanes of a
//   data stack item into an iterable. Append to the end (aligned to SIMD-Width),
//   or replace in the middle. No fundamental plan to insert in middle or
//   delete from middle and move all later elements, though.
// * Obv a way to pull a chunk of data from an iterable onto the stack, as well.
// * * Alignment? I think it will prove better to pull unaligned than to
// * * pull-aligned-with-possible-junk-at-start.
// * A way to specify an unaligned range of one iterable in order to treat
//   that as though it were its own iterable.
// * A way to specify a generator: that is a function that creates new
//   iterable items for a potentially indefinite list that is not actually
//   calculated until needed, but can otherwise be treated much like an
//   iterable. If only "can pull ranges from it", and then work on said ranges.
// * I'll need a way to determine and work with iterable length.
// * * Each has two lengths: length in data items, and length in SIMD-widths.
// * * Memory will be used up in length-of-SIMD-widths, and ordinary
//     iterable processes will iterate that many times over the data structure.
// * * I'll need to figure out a philisophical position on how to process
//     multiple input iterators of different total lengths.
//     EG: A+B=C where A has 5 elements and B has 50.
//     Or where A has 5 elements and B is an indefinite generator
//     such as "all of the natural numbers beginning at one".
// * * * First naive thought is "combined output of many input iterables
//       will be the minimum length of the given input iterables".
// * * * Second is feeding input iterables of different lengths
//       in as inputs to certain processes can just kick an error of some sort.
// * * interior process will probably only have to care about SIMD length,
//     and will work with at least some values past the end of many iterables
//     that are garbage, possibly with a mask or other convenience clarifying
//     which is garbage and thus should not push an execution envelope, etc.
// * * Caller and/or wrapper to processes ought to primarily pay attention
//     to data item length however, code writer level must literally never
//     know what the SIMD width even is.

// 2022-04-16 current status:
// Working out Ackermann crude function.
// Current trouble: The Bitfield64Branch features I've just perfected
// all basically amount to "if(X) { call Y } ... ret"
// I don't have any else support just yet, and w/o that the "..." above
// gets run wether X is true or false.
// Somehow I'd gotten confused and thought that everything down to the return
// would get skipped in a then clause?
// Plan B: (first naive idea, lets explore better ones)
// make Bitfield64Branches support else. Eww.
// Plan A: Are there any evil callstack manip we can do to skip
// everything between a call and the caller's ret? ;)

// 2022-04-12 current status:
// PrintStackMessage is the bees knees. Assuming that Crude tokens function properly,
// it basically undermines 99% of the cases where I would need to use gdb,
// speeding up troubleshooting immensely.
// Current problem:
// Only with mixed inputs, the smaller input over-calculates to "0"..
// .. but that shouldn't matter because the CMBOA ought to be filtering out that
// zero and keeping the 1 one place upstream from it.
// It's not doing that, but AFAICT it's down to an error in my calling logic,
// instead of an error in CMBOA's logic. But I can't yet be sure. :P

// 2022-04-10 current status:
// EndAlienCallStackFrame now successfully allocates and *I think* prepares the
// data stack.
// I'm pretty sure that ReturnToAlienCaller will clean it up too, but I'm not
// in a rush to test that yet as the harness would be a pain to prepare and to
// verify.
// Next up, we do reach "printStack" at the end but it is still probably
// trying to stop at the end of the incorrect stack. :P

// 2022-04-09 current status:
// What I'll need:
// * 0 => %rdi // requested address, eg "we don't care"
// * DATA_STACK_SIZE => %rsi // constant will prolly be 2^24
// * PROT_READ | PROT_WRITE => %rdx
// * MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN | MAP_STACK => %r10
// * -1 => %r8 // no file descriptor, we're going anonymous unshared.
// * 0 => %r9 // no offset, also required for anonymous.
// Since page size is such a fraught concept, I confirmed that
// the mmap syscall will bump up the amount you request to match
// whatever the page size is (and report back to you how much
// was actually allocated), so I ultimately don't have to think
// about it anyway.
// So, my plan: configure a Crude default pagesize hardcoded.
// Maybe 16MB?
// So now I just have to finish reading up on mmap itself. :)
// Note: I've also confirmed that mmap does NOT support Pipes, such as
// interactive TTYs or 99% of uses of STDIN, STDOUT, STDERR.
// 2022-04-07 current status:
// checking out: https://igm.univ-mlv.fr/~yahya/progsys/linux.pdf
// page 104 for mmap.
// cached to local file "Linux System Programming.pdf".
// Running into segfaults due to "call" not keeping application stack
// aligned to 16 byte boundaries (just 8 byte I guess?).
// Solution I want to explore: allocate a whole new stack for my data.
// That way execution can continue to be handled in the application stack,
// calls and returns can be stored there etc.
// To that end: I have decided to try eschewing the "brk(12)" syscall
// (which I understand REQUESTS a move of the "end" of the program's
// memory space and thus allows writing into more pages of memory
// without causing segmentation faults)
// and instead look into the more sophisticated "mmap(9)" syscall,
// which appears to allocate memory "from wherever OS thinks is convenient"
// to your app, and also optionally links it to a file descriptor to much
// more speedily read/write files.
// What I really want is a decent set of documentation for mmap syscall.
// Biggest hurdle being that glibc's "mmap / munmap" wrapper functions
// get all of the attention and trying to reach behind that is
// functionally unheard of.
// //
// best idea I have right now is to look at the glibc docs as a "hint"
// at what the (probably thinly wrapped) syscall behind it wants.
// https://man7.org/linux/man-pages/man2/mmap.2.html
// Linux x64 Syscall argument order:
// * x86-64	rdi	rsi	rdx	r10	r8	r9
// * Sycall number goes in rax, obviously.
// == earlier today
// Trying to set up a Factorial function 90% made out of crude macros.
// Finally got it to compile (eg, call to variable/lambda
// ought to be working?) but echo $? said 0 which doesn't match
// my expectations, so I'll have to look deeper. Meantime, bzz. :P

// 2022-04-04 current status:
// All currently implemented functions are fully implemented, tested, and
// lane independant.
// Stack manipulation functions like
// * rollElements
// * reverseElements
// * deleteElements
// * copyElements
// .. basically every command I just renamed to have an "Elements" suffix
// while typing this out, will be especially challenging to implemenet
// in a lane-independant fastion. "ClearDataStack" only gets off easy
// because it can cheat on the assumption that all stacks are
// the same length.
// I think I might need to break down and yield lane independance for
// "manipulate elements of the stack" commands, in order to
// enforce the SIMD "elements in a lane ought to remain in lockstep
// (or be masked out)" principle. In which case, "element counts get
// implicitly broadcast from lane 1" will be the order of the day.
// Imma call OPs that do yield to that principle "scalar broadcast ops".
// My bitshift ops are NOT scalar broadcast ops dawg,
// they are lane independant! ;D
//
// I've got some work put into 2022-04-04T0501-0700 scratchpad.txt :
// a list of all active macros at the moment,
// and a quick sketchup of a possible "factorial" procedure.
// Ops we need to support factorial include:
// * Being able to invoke a "named subroutine" from the execution stream.
// * Being able to return from a subroutine (however it got called).
// * First class subroutines (eg, storing an anonymous subroutine as data)
// will be quite helpful, though factorial in particular doesn't seem
// to benefit from that give or take the "if" flow control feature which
// might wind up using it.
// * "if" flow control mechanism of some form.
// .. how do we reconcile that with lanes I wonder?
// ** perhaps a :scalarBroadcast variant that does full flow control
// ** and a slightly more lane-independant variant that does some
// not-yet-planned-out mix of masking and blending to perform some
// operation to only the "True" lanes of the next single item on the stack,
// while leaving the "False" lanes unchanged.
// I'll call this lane-independant version conditionalMaskBlend.


// 2022-04-03 Current status:
// I'm debugging Index verb, which is just now really starting to
// rock and roll thanks to the magic (and allegedly slow! pextrq/pinsrq
// opcodes.
// Index into my current test stack of 1 position, or 2 position works.
// 3 position is failing, where the target has different values in
// each lane so I need to find out why.
// I also need to test "different indices in each lane" after that.
// "

// SSE-related values.
// Later expansion to AVX & AVX512 will use .ifdef to define these per platform.
// SIMD_WIDTH = 16
#define SIMD_WIDTH 16
#define SIMD_WIDTH_TIMES_2 32
#define SIMD_WIDTH_TIMES_3 48
#define SIMD_WIDTH_TIMES_4 64
#define CACHE_LINE_WIDTH 64
// how many bits long is the number describing the width in bytes.
// So for example, N<<SIMD_META_WIDTH == N * SIMD_WIDTH,
// and N>>SIMD_META_WIDTH == floor(N / SIMD_WIDTH)
#define SIMD_META_WIDTH 4
// " a bitmask with all zeros except for SIMD_META_WIDTH lowest bits set to ones.
// ANDing any value by this is the same as modulo'ing by SIMD_WIDTH itself.
// "
#define SIMD_META_BITMASK 0x0F
#define CACHE_LINE_META_WIDTH 6
// A "scalar native" is 64 bits on 64 bit processors. :P
#define SCALAR_NATIVE_WIDTH_IN_BYTES 8

#define SCALAR_LESS_THAN 0
#define SCALAR_BELOW 0
#define SCALAR_GREATER_THAN 1
#define SCALAR_ABOVE 1
#define SCALAR_EQUAL 2
#define SCALAR_ZERO 2
#define SCALAR_XNOR 2
#define SCALAR_AND 3
#define SCALAR_GREATER_THAN_OR_EQUAL 4
#define SCALAR_ABOVE_OR_EQUAL 4
#define SCALAR_LESS_THAN_OR_EQUAL 5
#define SCALAR_BELOW_OR_EQUAL 5
#define SCALAR_NOT_EQUAL 6
#define SCALAR_NONZERO 6
#define SCALAR_XOR 6
#define SCALAR_NAND 7
#define SCALAR_ALWAYS 8
#define SCALAR_TRUE 8
#define SCALAR_UNCONDITIONAL 8

#define SCALAR_BRANCH_TEST_0 cmp
#define SCALAR_BRANCH_TEST_1 cmp
#define SCALAR_BRANCH_TEST_2 cmp
#define SCALAR_BRANCH_TEST_3 test
#define SCALAR_BRANCH_TEST_4 cmp
#define SCALAR_BRANCH_TEST_5 cmp
#define SCALAR_BRANCH_TEST_6 cmp
#define SCALAR_BRANCH_TEST_7 test

#define SCALAR_BRANCH_REJECT_0 jae
#define SCALAR_BRANCH_REJECT_1 jbe
#define SCALAR_BRANCH_REJECT_2 jne
#define SCALAR_BRANCH_REJECT_3 jnz
#define SCALAR_BRANCH_REJECT_4 jb
#define SCALAR_BRANCH_REJECT_5 ja
#define SCALAR_BRANCH_REJECT_6 je
#define SCALAR_BRANCH_REJECT_7 jz

#define SCALAR_MASK_OUTPUT_NOT 4
#define SCALAR_MASK_BITWISE 2
#define SCALAR_MASK_BIGGER 1
#define SCALAR_MASK_AND 1

// Linux ABI Syscall identifiers
// Later expansion to Windows/BSD/Mac will use .ifdef to define these per platform.
// 64 bit registers:
#define ALIEN_INTEGER64_ARGUMENT1 rdi
#define ALIEN_INTEGER64_ARGUMENT2 rsi
#define ALIEN_INTEGER64_ARGUMENT3 rdx
#define ALIEN_INTEGER64_ARGUMENT4 rcx
#define ALIEN_INTEGER64_ARGUMENT5 r8
#define ALIEN_INTEGER64_ARGUMENT6 r9
#define ALIEN_INTEGER64_RETURN1 rax
#define ALIEN_INTEGER64_RETURN2 rdx
#define KERNEL_INTEGER64_ARGUMENT1 rdi
#define KERNEL_INTEGER64_ARGUMENT2 rsi
#define KERNEL_INTEGER64_ARGUMENT3 rdx
#define KERNEL_INTEGER64_ARGUMENT4 r10
#define KERNEL_INTEGER64_ARGUMENT5 r8
#define KERNEL_INTEGER64_ARGUMENT6 r9
#define KERNEL_INTEGER64_RETURN1 rax

// 32 bit registers (same regs, just bottom 4 bytes)
#define ALIEN_INTEGER32_ARGUMENT1 edi
#define ALIEN_INTEGER32_ARGUMENT2 esi
#define ALIEN_INTEGER32_ARGUMENT3 edx
#define ALIEN_INTEGER32_ARGUMENT4 ecx
#define ALIEN_INTEGER32_ARGUMENT5 r8d
#define ALIEN_INTEGER32_ARGUMENT6 r9d
#define ALIEN_INTEGER32_RETURN1 eax
#define ALIEN_INTEGER32_RETURN2 edx
#define KERNEL_INTEGER32_ARGUMENT1 edi
#define KERNEL_INTEGER32_ARGUMENT2 esi
#define KERNEL_INTEGER32_ARGUMENT3 edx
#define KERNEL_INTEGER32_ARGUMENT4 r10d
#define KERNEL_INTEGER32_ARGUMENT5 r8d
#define KERNEL_INTEGER32_ARGUMENT6 r9d
#define KERNEL_INTEGER32_RETURN1 eax

// 16 bit registers (same regs, just bottom 2 bytes)
#define ALIEN_INTEGER16_ARGUMENT1 di
#define ALIEN_INTEGER16_ARGUMENT2 si
#define ALIEN_INTEGER16_ARGUMENT3 dx
#define ALIEN_INTEGER16_ARGUMENT4 cx
#define ALIEN_INTEGER16_ARGUMENT5 r8w
#define ALIEN_INTEGER16_ARGUMENT6 r9w
#define ALIEN_INTEGER16_RETURN1 ax
#define ALIEN_INTEGER16_RETURN2 dx
#define KERNEL_INTEGER16_ARGUMENT1 di
#define KERNEL_INTEGER16_ARGUMENT2 si
#define KERNEL_INTEGER16_ARGUMENT3 dx
#define KERNEL_INTEGER16_ARGUMENT4 r10w
#define KERNEL_INTEGER16_ARGUMENT5 r8w
#define KERNEL_INTEGER16_ARGUMENT6 r9w
#define KERNEL_INTEGER16_RETURN1 ax

// 8 bit registers (same regs, just bottom byte)
#define ALIEN_INTEGER8_ARGUMENT1 dil
#define ALIEN_INTEGER8_ARGUMENT2 sil
#define ALIEN_INTEGER8_ARGUMENT3 dl
#define ALIEN_INTEGER8_ARGUMENT4 cl
#define ALIEN_INTEGER8_ARGUMENT5 r8b
#define ALIEN_INTEGER8_ARGUMENT6 r9b
#define ALIEN_INTEGER8_RETURN1 al
#define ALIEN_INTEGER8_RETURN2 dl
#define KERNEL_INTEGER8_ARGUMENT1 dil
#define KERNEL_INTEGER8_ARGUMENT2 sil
#define KERNEL_INTEGER8_ARGUMENT3 dl
#define KERNEL_INTEGER8_ARGUMENT4 r10b
#define KERNEL_INTEGER8_ARGUMENT5 r8b
#define KERNEL_INTEGER8_ARGUMENT6 r9b
#define KERNEL_INTEGER8_RETURN1 al

#define SYSCALL_REGISTER rax
#define SYSCALL_SYS_READ 0x00
#define SYSCALL_SYS_WRITE 0x01
#define SYSCALL_SYS_MMAP 0x09
#define SYSCALL_SYS_MUNMAP 0x11
#define SYSCALL_SYS_EXIT 60

// x64 values
#define CALL_STACK_BASE_POINTER rbp
#define CALL_STACK_POINTER rsp
#define DATA_STACK_POINTER rbx
#define DATA_STACK_POINTER32 ebx
#define TOP_OF_CALL_STACK (%CALL_STACK_POINTER)
#define TOP_OF_DATA_STACK (%DATA_STACK_POINTER)
#define BOTTOM_OF_CALL_STACK -8(%CALL_STACK_BASE_POINTER)
// This should be exactly 2^24 bytes or 16MiB
#define DATA_STACK_SIZE 16777216

// " sensitive to SIMD_WIDTH :P  I'm too lazy to look up how to do gas variable arithmetic right now.
// "
#define DATA_STACK_NEGATIVE3 -48(%DATA_STACK_POINTER)
#define DATA_STACK_NEGATIVE2_5 -40(%DATA_STACK_POINTER)
#define DATA_STACK_NEGATIVE2 -32(%DATA_STACK_POINTER)
#define DATA_STACK_NEGATIVE1_5 -24(%DATA_STACK_POINTER)
#define DATA_STACK_NEGATIVE1 -16(%DATA_STACK_POINTER)
#define DATA_STACK_NEGATIVE0_5 -8(%DATA_STACK_POINTER)
#define DATA_STACK0 (%DATA_STACK_POINTER)
#define DATA_STACK0_5 8(%DATA_STACK_POINTER)
#define DATA_STACK1 16(%DATA_STACK_POINTER)
#define DATA_STACK1_5 24(%DATA_STACK_POINTER)
#define DATA_STACK2 32(%DATA_STACK_POINTER)
#define DATA_STACK2_5 40(%DATA_STACK_POINTER)
#define DATA_STACK3 48(%DATA_STACK_POINTER)
#define DATA_STACK3_5 56(%DATA_STACK_POINTER)
#define DATA_STACK4 64(%DATA_STACK_POINTER)
#define DATA_STACK4_5 72(%DATA_STACK_POINTER)
#define DATA_STACK5 80(%DATA_STACK_POINTER)
#define DATA_STACK5_5 88(%DATA_STACK_POINTER)
#define DATA_STACK6 96(%DATA_STACK_POINTER)
#define DATA_STACK6_5 104(%DATA_STACK_POINTER)
#define DATA_STACK7 112(%DATA_STACK_POINTER)
#define DATA_STACK7_5 120(%DATA_STACK_POINTER)

#define DATA_STACK0_QUOTED "(%rbx)"

// " sensitive to SCALAR_NATIVE_WIDTH_IN_BYTES :P  I'm too lazy to look up how to do gas variable arithmetic right now.
// "
#define CALL_STACK_NEGATIVE5 -40(%CALL_STACK_POINTER)
#define CALL_STACK_NEGATIVE4 -32(%CALL_STACK_POINTER)
#define CALL_STACK_NEGATIVE3 -24(%CALL_STACK_POINTER)
#define CALL_STACK_NEGATIVE2 -16(%CALL_STACK_POINTER)
#define CALL_STACK_NEGATIVE1 -8(%CALL_STACK_POINTER)
#define CALL_STACK0 (%CALL_STACK_POINTER)
#define CALL_STACK1 8(%CALL_STACK_POINTER)
#define CALL_STACK2 16(%CALL_STACK_POINTER)
#define CALL_STACK3 24(%CALL_STACK_POINTER)
#define CALL_STACK4 32(%CALL_STACK_POINTER)
#define CALL_STACK5 40(%CALL_STACK_POINTER)
#define CALL_STACK6 48(%CALL_STACK_POINTER)
#define CALL_STACK7 56(%CALL_STACK_POINTER)

// copied from /usr/include/sys/mman.h, et al
#define PROT_NONE     0x0  /* Page can not be accessed.  */
#define PROT_READ     0x1  /* Page can be read.  */
#define PROT_WRITE    0x2  /* Page can be written.  */
#define PROT_EXEC     0x4  /* Page can be executed.  */
#define MAP_SHARED    0x01 /* Share changes.  */
#define MAP_PRIVATE   0x02 /* Changes are private.  */
#define MAP_FIXED     0x10 /* Interpret addr exactly.  */
#define MAP_ANONYMOUS 0x20 /* "Don't use a file."  */

#define TRUE 0xFFFFFFFFFFFFFFFF
#define FALSE 0

#define PROT_READ_WRITE 0x03
#define MAP_ANONYMOUS_PRIVATE 0x22

##############
##  Macros  ##
##############

#define _CallStackPopGeneral pop
#define _CallStackPushGeneral push

.macro _DataStackAdvance
  // advance downwards
_DataStackAdvance\@: sub $SIMD_WIDTH, %DATA_STACK_POINTER
.endm

.macro DataStackRetreat
  // retreat by climbing back upwards again
DataStackRetreat\@: add $SIMD_WIDTH, %DATA_STACK_POINTER
.endm

.macro DataStackRetreatTwice
  // retreat by climbing back upwards again
DataStackRetreatTwice\@: add $SIMD_WIDTH_TIMES_2, %DATA_STACK_POINTER
.endm

.macro DataStackRetreatThrice
  // retreat by climbing back upwards again
DataStackRetreatTwice\@: add $SIMD_WIDTH_TIMES_3, %DATA_STACK_POINTER
.endm

# Currently assumes 2x64bit lane SSE
.macro _DataStackPopGeneral register=%rax
_DataStackPopGeneral\@:
  mov DATA_STACK0, \register
  DataStackRetreat
.endm

.macro _Bitfield64DataStackPushGeneral register=%rax
_Bitfield64DataStackPushGeneral\@:
  _DataStackAdvance
  mov \register, DATA_STACK0
  mov \register, DATA_STACK0_5
.endm

# Broadcast Push CONTENTS of a given ALIGNED Qword onto data stack
.macro _Bitfield64DataStackPushRAM address:req, clobberGeneral=%rax
_Bitfield64DataStackPushRAM\@:
  _DataStackAdvance
  mov \address, \clobberGeneral
  mov \clobberGeneral, DATA_STACK0
  mov \clobberGeneral, DATA_STACK0_5
.endm

# Broadcast Push ADDRESS itself onto data stack.
.macro _Bitfield64DataStackPushAddress address:req, clobberGeneral=%rax
_Bitfield64DataStackPushAddress\@:
  _DataStackAdvance
  leaq \address, \clobberGeneral
  mov \clobberGeneral, DATA_STACK0
  mov \clobberGeneral, DATA_STACK0_5
.endm

// Broadcasts low 8 bits of named 32 or 64 bit
// general purpose register into every lane of a
// SIMD register, then pushes that value onto
// the stack.
// New top of stack => %xmm0
// all 0 => %xmm7
// Testcase confirmed passed 2023-06-10T16:21-07:00
.macro _Bitfield8DataStackPushGeneral register=%eax
_Bitfield8DataStackPushGeneral\@:
  // 32 bits gets moved here, but only low 8 bits will survive.
  movd \register, %xmm0
  _SIMDPush %xmm0
  Bitfield8ScalarBroadcast
.endm

// clobbers %xmm0
// Tested 2022-04-21T19:35-07:00
.macro Bitfield64ScalarBroadcast
  pshufd $0x44, DATA_STACK0, %xmm0
  movdqa %xmm0, DATA_STACK0
.endm

// clobbers %xmm0, %xmm7
// Tested 2022-04-21T19:35-07:00
.macro Bitfield8ScalarBroadcast
  _SetAllBitsZero %xmm7 // lane 0 new source for every lane
  movdqa DATA_STACK0, %xmm0
  pshufb %xmm7, %xmm0 // "broadcast xmm0's lowest 8 bits to all lanes."
  movdqa %xmm0, DATA_STACK0
.endm

// Does not return, does not tidy stack. Yields control back to the calling shell.
.macro systemExit
systemExit\@:
  // mov SYSCALL_SYS_EXIT, %SYSCALL_REGISTER
  mov $SYSCALL_SYS_EXIT, %SYSCALL_REGISTER
  movq TOP_OF_DATA_STACK, %ALIEN_INTEGER64_ARGUMENT1 // Lane 1 should be shallowest. I think?
  // movq (%rsp),%ALIEN_INTEGER64_ARGUMENT1
  // "don't need to pop call stack or fix parent frame.. just bail! :D"
  syscall
.endm

.macro PushParentOwnedRegisters
PushParentOwnedRegisters\@:
  // This one will get used as our data stack pointer
  _CallStackPushGeneral %rbx

  // "This is the parent's call stack base pointer"
  _CallStackPushGeneral %rbp

  // These are just .. other parent-owned registers by alien ABI standards.
  _CallStackPushGeneral %r12
  _CallStackPushGeneral %r13
  _CallStackPushGeneral %r14
  _CallStackPushGeneral %r15
.endm

.macro PopParentOwnedRegisters
PopParentOwnedRegisters\@:
  // These are parent-owned registers by alien ABI standards.
  _CallStackPopGeneral %r15
  _CallStackPopGeneral %r14
  _CallStackPopGeneral %r13
  _CallStackPopGeneral %r12

  // "This is the parent's call stack base pointer"
  _CallStackPopGeneral %rbp

  // "This register got borrowed long-term for our ABI's data stack pointer"
  _CallStackPopGeneral %rbx
.endm

.macro PrepareSimpleCallStackFrame
  _CallStackPushGeneral %CALL_STACK_BASE_POINTER
  mov %CALL_STACK_POINTER, %CALL_STACK_BASE_POINTER
.endm

.macro DismantleSimpleCallStackFrame
  mov %CALL_STACK_BASE_POINTER, %CALL_STACK_POINTER
  _CallStackPopGeneral %CALL_STACK_BASE_POINTER
.endm

// "
//Allocates a Data Stack,
//prepares it's stack head (%rbx) and base ( (%rbp) ) pointers
//stows a "child preamble stack frame" of fixed length with the
//following 64-bit values in call stack push order:
// Parent's %rbx
// Parent's %rbp // This is the parent's call stack base pointer
// Parent's %r12
// Parent's %r13
// Parent's %r14
// Parent's %r15
// Child's data stack base pointer
// That last position gets fed into both %rbp and %rsp.
// "
.macro EndAlienCallStackFrame
EndAlienCallStackFrame\@:
  // "
  // End parent's stack frame, start fixed length child preamble frame.
  // First up, stowing all parent-owned registers.
  // "
  PushParentOwnedRegisters

  mov $SYSCALL_SYS_MMAP\
    , %SYSCALL_REGISTER

  xor %KERNEL_INTEGER64_ARGUMENT1\
    , %KERNEL_INTEGER64_ARGUMENT1

  mov $DATA_STACK_SIZE\
    , %KERNEL_INTEGER64_ARGUMENT2

  mov $PROT_READ_WRITE\
    , %KERNEL_INTEGER64_ARGUMENT3

  mov $MAP_ANONYMOUS_PRIVATE\
    , %KERNEL_INTEGER64_ARGUMENT4

  mov $-1, %KERNEL_INTEGER64_ARGUMENT5

  xor %KERNEL_INTEGER64_ARGUMENT6\
    , %KERNEL_INTEGER64_ARGUMENT6

  syscall
  cmpq $-4095, %KERNEL_INTEGER64_RETURN1 /* Check for error.  */
  jb SYSCALL_MMAP_SUCCESS\@ /* Jump past error handler if success.  */
SYSCALL_MMAP_ERROR_HANDLER\@:
  // store sys_mmap return while printing text
  _CallStackPushGeneral %KERNEL_INTEGER64_RETURN1
  putLiteralMacro "Error! ERRNO=0x", fileDescriptor=$STDERR
  // restore sys_mmap return into first userland argument
  _CallStackPopGeneral %ALIEN_INTEGER64_ARGUMENT1

  // "but two's-compliment it first"
  mov $0, %r15d
  subq %ALIEN_INTEGER64_ARGUMENT1, %r15
  mov %r15, %ALIEN_INTEGER64_ARGUMENT1

  leaq MEMORY_SCRATCHPAD(%rip), %ALIEN_INTEGER64_ARGUMENT2
  call _unsignedIntegerToStringBase16
  //%ALIEN_INTEGER64_RETURN1 has new pointer to string
  //%ALIEN_INTEGER64_RETURN2 has length of new string
  putMemoryMacro \
    messageLocation=(%ALIEN_INTEGER64_RETURN1) \
  , length=%ALIEN_INTEGER64_RETURN2 \
  , fileDescriptor=$STDERR
  putNewlineMacro fileDescriptor=$STDERR
  systemExit

SYSCALL_MMAP_SUCCESS\@:
  mov %KERNEL_INTEGER64_RETURN1, %DATA_STACK_POINTER

  // flip our pointer to the highest address in the allocated range,
  // so that we can grow down from there.
  add %KERNEL_INTEGER64_ARGUMENT2, %DATA_STACK_POINTER
  // _DataStackAdvance // safely bump down by one entry, out of neighboring page.

  PrepareSimpleCallStackFrame
  // ensures that BOTTOM_OF_CALL_STACK remembers our Data Stack Base Pointer for us.
  _CallStackPushGeneral %DATA_STACK_POINTER
  // Finish fixed length preamble, begin child frame in earnest,
  // and this way BOTTOM_OF_CALL_STACK aka (%CALL_STACK_BASE_POINTER)
  // can always tell us where the bottom of the data stack is as well. :)
.endm

// Is this Linux only, or does it also work the same for Windows/BSD/Mac?
// This macro is compatible with already-prepared return values through Registers,
// and/or registers-pointing-to-RAM. It is not compatible with return
// values being passed through the stack.
.macro ReturnToAlienCaller
ReturnToAlienCaller\@:
  // Dump our entire child frame, but leave the preamble intact.
  ClearDataStack

  // "
  // Next we'll deallocate our Data Stack Base Pointer,
  // exuming it from the preamble along the way.
  // "
  _CallStackPopGeneral %DATA_STACK_POINTER

  // flip address back down to bottom of its allocated range.
  // DataStackRetreat // first bump safely up to the bottom of next page,
  mov $DATA_STACK_SIZE\
    , %KERNEL_INTEGER64_ARGUMENT2
  // then shift all the way up to the bottom of our page.
  sub %KERNEL_INTEGER64_ARGUMENT2, %DATA_STACK_POINTER

  mov $SYSCALL_SYS_MUNMAP\
    , %SYSCALL_REGISTER

  mov %DATA_STACK_POINTER\
    , %KERNEL_INTEGER64_ARGUMENT1

  mov $DATA_STACK_SIZE\
    , %KERNEL_INTEGER64_ARGUMENT2

  syscall
  // "
  // Here one can check for errors from the munmap syscall.
  // 0 means success,
  // -4095 through -1 is the two's compliment of an ERRNO error token.
  // Anything else I think should be unreturnable.
  // My strategy today is going to be:
  // we are bailing anyway so ignore any error and hastily GTFO.
  // "

  // "Next we'll restore all of the caller's other registers."
  PopParentOwnedRegisters
  ret
.endm

// Tested and passed 2022-04-17T20:05-07:00
.macro ClearDataStack
ClearDataStack\@:
  mov BOTTOM_OF_CALL_STACK, %DATA_STACK_POINTER
.endm

// .macro SIMDPop register=%xmm0 // Pop into a register
// SIMDPop\@:
//   // shrink stack pointer upward width of a SIMD register.
//   movdqa TOP_OF_DATA_STACK, \register
//   DataStackRetreat
// .endm

.macro _SIMDPush register=%xmm0
_SIMDPush\@:
  _DataStackAdvance
  movdqa \register, DATA_STACK0
.endm

.macro _DataStackPushFromRAM address:req SIMDClobber=%xmm0 aligned=TRUE
  .if \aligned
    movdqa \address, \SIMDClobber
  .else
    movdqu \address, \SIMDClobber
  .endif
  _SIMDPush \SIMDClobber
.endm

.macro _DataStackCopyToRAM address:req SIMDClobber=%xmm0 aligned=TRUE
  movdqa DATA_STACK0, \SIMDClobber
  .if \aligned
    movdqa \SIMDClobber, \address
  .else
    movdqu \SIMDClobber, \address
  .endif
.endm

// "
// Copies the value in a 64 bit scalar aka "general purpose" register
// directly into EVERY lane of an SIMD register.
// Currently only coded for 128 bit registers,
// I need to dream up the best way to make this more general
// for future expansion.
// luckily, in AVX2 and AVX512 there's a single opcode for it lel!
// "
.macro _Scalar64BroadcastToSIMD128 scalarRegister:req receiveRegister:req
_Scalar64BroadcastToSIMD128\@:
  pinsrq $0, \scalarRegister, \receiveRegister
  pinsrq $1, \scalarRegister, \receiveRegister
.endm

// "
// Gathers all of the Integer64 data found at each memory location in
// each lane of indexRegister and loads those into the same lanes
// of receiveRegister.
// No clobbering goes on here.
// "
.macro _SIMD128GatherBitfield64 indexRegister=%xmm1 receiveRegister=%xmm0
_SIMD128GatherBitfield64\@:
  pextrq $0, \indexRegister, %rax
  pinsrq $0, (%rax), \receiveRegister
  pextrq $1, \indexRegister, %rax
  pinsrq $1, (%rax), \receiveRegister
.endm

// "
// Accepts two scalar registers (any size I think? al/ax/eax/rax?)
// and sets the "destination" one equal to whichever value
// is the smallest.
// "
.macro _ScalarMinimum source=%rdx destination=%rax
_ScalarMinimum\@:
  cmp %rdx, %rax
  cmovg %rdx, %rax # %rax > %rdx? then %rax := %rdx.
.endm

// "
// Accepts two scalar registers (any size I think? al/ax/eax/rax?)
// and sets the "destination" one equal to whichever value
// is the largest.
// "
.macro _ScalarMaximum source=%rdx destination=%rax
_ScalarMaximum\@:
  cmp %rdx, %rax
  cmovl %rdx, %rax # %rax < %rdx? then %rax := %rdx.
.endm

// "
// Always clobbers %xmm0
// Tested and passed 2022-05-11T03:44-07:00
// "
.macro MinimumSignedInteger64 ClobberSIMD=%xmm1
MinimumSignedInteger64\@:
  DataStackRetreat
  movdqa DATA_STACK0, %xmm0
  pcmpgtq DATA_STACK_NEGATIVE1, %xmm0
  movdqa DATA_STACK0, \ClobberSIMD
  blendvpd DATA_STACK_NEGATIVE1, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm

// Always clobbers %xmm0
// Tested and passed 2022-05-11T03:44-07:00
.macro MinimumUnsignedInteger64 ClobberSIMD1=%xmm1 ClobberSIMD2=%xmm2 ClobberScalar=%rax
MinimumUnsignedInteger64\@:
  DataStackRetreat
  mov $0x8000000000000000, \ClobberScalar
  _Scalar64BroadcastToSIMD128 scalarRegister=\ClobberScalar,receiveRegister=\ClobberSIMD2
  movdqa DATA_STACK0, %xmm0
  pxor \ClobberSIMD2, %xmm0
  movdqa DATA_STACK_NEGATIVE1, \ClobberSIMD1
  pxor \ClobberSIMD2, \ClobberSIMD1
  pcmpgtq \ClobberSIMD1, %xmm0
  movdqa DATA_STACK0, \ClobberSIMD1
  blendvpd DATA_STACK_NEGATIVE1, \ClobberSIMD1
  movdqa \ClobberSIMD1, DATA_STACK0
.endm

// Tested and passed 2022-05-11T03:44-07:00
.macro MinimumSignedInteger8 ClobberSIMD=%xmm1
MinimumSignedInteger8\@:
  DataStackRetreat
  movdqa DATA_STACK0, \ClobberSIMD
  pminsb DATA_STACK_NEGATIVE1, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm

// Tested and passed 2022-05-11T03:44-07:00
.macro MinimumUnsignedInteger8 ClobberSIMD=%xmm0
MinimumUnsignedInteger8\@:
  DataStackRetreat
  movdqa DATA_STACK0, \ClobberSIMD
  pminub DATA_STACK_NEGATIVE1, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm

// Always clobbers %xmm0
// Tested and passed 2022-05-11T03:44-07:00
.macro MaximumSignedInteger64 ClobberSIMD=%xmm1
MaximumSignedInteger64\@:
  DataStackRetreat
  movdqa DATA_STACK0, %xmm0
  pcmpgtq DATA_STACK_NEGATIVE1, %xmm0
  movdqa DATA_STACK_NEGATIVE1, \ClobberSIMD
  blendvpd DATA_STACK0, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm

// Always clobbers %xmm0
// Tested and passed 2022-05-11T03:44-07:00
.macro MaximumUnsignedInteger64 ClobberSIMD1=%xmm1 ClobberSIMD2=%xmm2 ClobberScalar=%rax
MaximumUnsignedInteger64\@:
  DataStackRetreat
  mov $0x8000000000000000, \ClobberScalar
  _Scalar64BroadcastToSIMD128 scalarRegister=\ClobberScalar,receiveRegister=\ClobberSIMD2
  movdqa DATA_STACK0, %xmm0
  pxor \ClobberSIMD2, %xmm0
  movdqa DATA_STACK_NEGATIVE1, \ClobberSIMD1
  pxor \ClobberSIMD2, \ClobberSIMD1
  pcmpgtq \ClobberSIMD1, %xmm0
  movdqa DATA_STACK_NEGATIVE1, \ClobberSIMD1
  blendvpd DATA_STACK0, \ClobberSIMD1
  movdqa \ClobberSIMD1, DATA_STACK0
.endm

// Tested and passed 2022-05-11T03:44-07:00
.macro MaximumSignedInteger8 ClobberSIMD=%xmm1
MaximumSignedInteger8\@:
  DataStackRetreat
  movdqa DATA_STACK0, \ClobberSIMD
  pmaxsb DATA_STACK_NEGATIVE1, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm

// Tested and passed 2022-05-11T03:44-07:00
.macro MaximumUnsignedInteger8 ClobberSIMD=%xmm0
MaximumUnsignedInteger8\@:
  DataStackRetreat
  movdqa DATA_STACK0, \ClobberSIMD
  pmaxub DATA_STACK_NEGATIVE1, \ClobberSIMD
  movdqa \ClobberSIMD, DATA_STACK0
.endm


// .macro SIMDScatter indexRegister=%xmm1 sendRegister=%xmm0 tempRegister=%xmm2
//   movdqa (\indexRegister), \sendRegister
// .endm


// "
// Pushes current length of stack onto top of stack,
// which in turn makes it one longer and instantly out of date lol.
// EG: () Count (0)
// EG: (9 9 9) Count (9 9 9 3)
// Current count => Top of stack (all lanes) and %rax
// "
.macro Bitfield64Count
Count\@:
  mov BOTTOM_OF_CALL_STACK, %rax
  sub %DATA_STACK_POINTER, %rax
  sarl $SIMD_META_WIDTH, %eax
  _Bitfield64DataStackPushGeneral %rax
.endm

// "
// Pushes a duplicate of the current top of stack onto the stack.
// EG: (1 2 3 4) Duplicate (1 2 3 4 4)
// () Duplicate <like all "reads stack contents" ops, undefined probable crash>
// New (and identical old) top of stack => xmm0
// "
.macro Duplicate
Duplicate\@:
  movdqa DATA_STACK0, %xmm0
  _SIMDPush %xmm0
.endm

// "
// Swaps the top two positions on the stack, does not change stack length.
// EG: (1 2 3 4) Exchange (1 2 4 3)
// New top of stack (old second item) => xmm0
// New second item (old top of stack) => xmm1
// "
.macro Exchange
Exchange\@:
  movdqa DATA_STACK0, %xmm1
  movdqa DATA_STACK1, %xmm0
  movdqa %xmm1, DATA_STACK1
  movdqa %xmm0, DATA_STACK0
.endm

// "
// Replaces top of stack N with the stack element N places back.
// 0 does nothing (it fetches 0 and replaces 0 with 0..)
// 1+ gets older stack elements.
// Does not change the length of the stack.
// Ex: (11 22 33 44 3) index -> (11 22 33 44 22)
// Ex: (11 22 33 44 0) index -> (11 22 33 44 0)
// New top of stack => xmm0
// Current stack pointer => every lane of xmm1
// "
.macro Bitfield64Index
Bitfield64Index\@:
  movdqa DATA_STACK0, %xmm0 // get index
  // turn into memory offset depths into the stack
  psllq $SIMD_META_WIDTH, %xmm0
  // Load stack pointer into xmm1
  // _ScalarBroadcastToSIMD scalarRegister=%rsp,receiveRegister=%xmm1
  // least significant half gets most recent data lane
  pinsrq $0, %DATA_STACK_POINTER, %xmm1
  // most significant half will be offset into lane 2
  addq $SCALAR_NATIVE_WIDTH_IN_BYTES, %DATA_STACK_POINTER
  pinsrq $1, %DATA_STACK_POINTER, %xmm1
  subq $SCALAR_NATIVE_WIDTH_IN_BYTES, %DATA_STACK_POINTER
  // add offsets, yielding target locations in xmm0.
  paddq %xmm1, %xmm0
  _SIMD128GatherBitfield64 indexRegister=%xmm0,receiveRegister=%xmm0
  movdqa %xmm0, DATA_STACK0
.endm

.macro _SetAllBitsZero register=%xmm7
_SetAllBitsZero\@:
  pxor \register, \register
.endm

.macro _SetAllBitsOne register=%xmm7
_SetAllBitsOne\@:
  pcmpeqd \register, \register
.endm

// "
// Pop top of stack, calculate its two's compliment
// and push the result.
// NEW top of stack => %xmm0
// 0 in every lane => %xmm1
// input 1 unit, output 1 unit
// If output high bit set, then input was a valid Bitfield64.
// Tested and passed 2022-04-03T02:23-07:00
// "
.macro Bitfield64negate
Bitfield64negate\@:
  movdqa DATA_STACK0, %xmm1
  _SetAllBitsZero register=%xmm0
  psubq %xmm1, %xmm0
  movdqa %xmm0, DATA_STACK0
.endm

// "
// Pop top of stack, calculate its two's compliment
// and push the result.
// NEW top of stack => %xmm0
// 0 in every lane => %xmm1
// input 1 unit, output 1 unit
// If output high bit set, then input was a valid Bitfield8.
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro Bitfield8negate
Bitfield8negate\@:
  movdqa DATA_STACK0, %xmm1
  _SetAllBitsZero register=%xmm0
  psubb %xmm1, %xmm0
  movdqa %xmm0, DATA_STACK0
.endm

// "
// NEW top of stack => %xmm0
// old DATA_STACK1 => %xmm1
// input 2 unit, output 1 unit
// If output high bit set, then overflow Bitfield64.
// Tested and passed 2022-04-03T06:07-07:00
// "
.macro Bitfield64add
Bitfield64add\@:
  movdqa DATA_STACK0, %xmm0
  movdqa DATA_STACK1, %xmm1
  paddq %xmm1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// NEW top of stack => %xmm0
// old DATA_STACK1 => %xmm1
// input 2 unit, output 1 unit
// If output high bit set, then overflow Bitfield8.
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro Bitfield8add
Bitfield8add\@:
  movdqa DATA_STACK0, %xmm0
  movdqa DATA_STACK1, %xmm1
  paddb %xmm1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// NEW top of stack => %xmm0
// Clobbered => %xmm1, %xmm2, %xmm3
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T08:15-07:00
// Does this method return signed or unsigned when input has high bit set?
// I think in two's compliment those two outcomes are always identical?
// "
.macro UnsignedInteger63multiply
UnsignedInteger63multiply\@:
  movdqa  DATA_STACK0, %xmm0
  movdqa  DATA_STACK1, %xmm1
  movdqa  %xmm0, %xmm3
  movdqa  %xmm0, %xmm2
  psrlq   $32, %xmm3
  pmuludq %xmm1, %xmm2
  pmuludq %xmm1, %xmm3
  psrlq   $32, %xmm1
  pmuludq %xmm1, %xmm0
  paddq   %xmm3, %xmm0
  psllq   $32, %xmm0
  paddq   %xmm2, %xmm0
  movdqa  %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// No Bitfield8 or SignedInteger8 or UnsignedInteger8
// version of multiplication at this time.

// "
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
// Tested and passed 2022-04-03T06:07-07:00
// "
.macro Bitfield64equal
Bitfield64equal\@:
  movdqa DATA_STACK0, %xmm0
  pcmpeqq DATA_STACK1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro Bitfield8equal
Bitfield8equal\@:
  movdqa DATA_STACK0, %xmm0
  pcmpeqb DATA_STACK1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// test DATA_STACK1 > DATA_STACK0
// EG: (1 2 3 4) greaterThan -> (1 2 FALSE)
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
// Tested and passed 2022-04-17T20:05-07:00
// "
.macro SignedInteger64greaterThan
SignedInteger64greaterThan\@:
  movdqa DATA_STACK1, %xmm0
  pcmpgtq DATA_STACK0, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// test DATA_STACK1 > DATA_STACK0
// EG: (1 2 3 4) greaterThan -> (1 2 FALSE)
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro SignedInteger8greaterThan
SignedInteger8greaterThan\@:
  movdqa DATA_STACK1, %xmm0
  pcmpgtb DATA_STACK0, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// DATA_STACK1 will be shifted by DATA_STACK0%64 bits to the right (lesser significance).
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x300 4) bitShiftDownZeroPad -> (1 2 0x30)
// NEW top of stack => %xmm0
// Normalized number of bits shifted (modulo number of data element bits) => %xmm1
// 0x3F => xmm2
// input 2 unit, output 1 unit
// If output high bit set, then count must have been zero and source unchanged.
// Tested and passed 2022-04-03T14:53-07:00
// "
.macro Bitfield64bitShiftDownZeroPad
Bitfield64bitShiftDownZeroPad\@:
  movq DATA_STACK0, %rcx
  movq DATA_STACK1, %rax
  shrx %rcx, %rax, %rax
  movq %rax, DATA_STACK1
  movq DATA_STACK0_5, %rcx
  movq DATA_STACK1_5, %rax
  shrx %rcx, %rax, %rax
  movq %rax, DATA_STACK1_5
  DataStackRetreat
.endm

// No Bitfield8 shift or rotate options.
// Check https://stackoverflow.com/questions/35002937/sse-simd-shift-with-one-byte-element-size-granularity
// for some ideas on perhaps emulating some, if they ever
// become seriously needed.

// "
// DATA_STACK1 will be shifted by DATA_STACK0%64 bits to the left (greater significance).
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x300 4) bitShiftUpZeroPad -> (1 2 0x3000)
// NEW top of stack => %xmm0
// Normalized number of bits shifted (modulo number of data element bits) => %xmm1
// 0x3F => xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow Bitfield64.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
// "
.macro Bitfield64bitShiftUpZeroPad
Bitfield64bitShiftUpZeroPad\@:
  movq DATA_STACK0, %rcx
  movq DATA_STACK1, %rax
  shlx %rcx, %rax, %rax
  movq %rax, DATA_STACK1
  movq DATA_STACK0_5, %rcx
  movq DATA_STACK1_5, %rax
  shlx %rcx, %rax, %rax
  movq %rax, DATA_STACK1_5
  DataStackRetreat
.endm

// "
// DATA_STACK1 will be shifted by DATA_STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// 0x40 => %xmm3
// 0x3F => %xmm7
// input 2 unit, output 1 unit
// If output high bit set, then overflow Bitfield64.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
// "
.macro Bitfield64bitRotateDown
Bitfield64bitRotateDown\@:
  movb DATA_STACK0, %cl
  movq DATA_STACK1, %rax
  ror %cl, %rax
  movq %rax, DATA_STACK1
  movb DATA_STACK0_5, %cl
  movq DATA_STACK1_5, %rax
  ror %cl, %rax
  movq %rax, DATA_STACK1_5
  DataStackRetreat
.endm

// "
// DATA_STACK1 will be shifted by DATA_STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow Bitfield64.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
// "
.macro Bitfield64bitRotateUp
Bitfield64bitRotateUp\@:
  movb DATA_STACK0, %cl
  movq DATA_STACK1, %rax
  rol %cl, %rax
  movq %rax, DATA_STACK1
  movb DATA_STACK0_5, %cl
  movq DATA_STACK1_5, %rax
  rol %cl, %rax
  movq %rax, DATA_STACK1_5
  DataStackRetreat
.endm

// "
// DATA_STACK0 will be set to all 0 if high bit is 0, or all 1 if high bit is 1.
// EG: (-1) castToBoolean -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// EG: (0) castToBoolean -> (0) aka Boolean FALSE
// EG: (0xFFFFF) -> (0) aka Boolean FALSE
// EG: (0x8000000000000000) -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// NEW top of stack => %xmm1
// All zeros => %xmm0
// input 1 unit, output 1 unit
// "
.macro Bitfield64castToBoolean
Bitfield64castToBoolean\@:
  // movdqa DATA_STACK0, %xmm1 // Bitfield64 to cast
  _SetAllBitsZero register=%xmm0 // fill bits on %xmm1
  _SetAllBitsZero register=%xmm1 // fill bits on %xmm1
  pcmpeqq DATA_STACK0, %xmm0 // Is subject equal to 0?
  // (nonzero becomes 0, 0 becomes 0xFFFFFFFFFFFFFFFF)
  pcmpeqq %xmm1, %xmm0 // Is subject equal to 0 now?
  // (original nonzero becomes 0xFFFFFFFFFFFFFFFF, original 0 turns back to 0)
  movdqa %xmm0, DATA_STACK0
.endm

// "
// DATA_STACK0 will be set to all 0 if high bit is 0, or all 1 if high bit is 1.
// EG: (-1) castToBoolean -> (0xFF) aka Boolean TRUE
// EG: (0) castToBoolean -> (0) aka Boolean FALSE
// EG: (0x7F) -> (0) aka Boolean FALSE
// EG: (0x80) -> (0xFF) aka Boolean TRUE
// NEW top of stack => %xmm0
// OLD top of stack => %xmm1
// input 1 unit, output 1 unit
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro Bitfield8castToBoolean
Bitfield8castToBoolean\@:
  // movdqa DATA_STACK0, %xmm1 // Bitfield8 to cast
  _SetAllBitsZero register=%xmm0 // fill bits on %xmm1
  _SetAllBitsZero register=%xmm1 // fill bits on %xmm1
  pcmpeqb DATA_STACK0, %xmm0 // Is subject equal to 0?
  // (nonzero becomes 0, 0 becomes 0xFF)
  pcmpeqb %xmm1, %xmm0 // Is subject equal to 0 now?
  // (original nonzero becomes 0xFF, original 0 turns back to 0)
  movdqa %xmm0, DATA_STACK0
.endm

// "
// EG: () BooleanPushTrue (TRUE)
// NEW top of stack (always TRUE) => %xmm0
// Tested and passed 2022-04-03T09:57-07:00
// "
.macro BooleanPushTrue
BooleanPushTrue\@:
  _SetAllBitsOne register=%xmm0
  _SIMDPush %xmm0
.endm

// "
// EG: () BooleanPushFalse (FALSE)
// NEW top of stack (always FALSE) => %xmm0
// Tested and passed 2022-04-03T09:57-07:00
// "
.macro BooleanPushFalse
BooleanPushFalse\@:
  _SetAllBitsZero register=%xmm0
  _SIMDPush %xmm0
.endm

// "
// EG: () Bitfield64PushZero (0)
// NEW top of stack (always 0) => %xmm0
// Tested and passed ???
// "
.macro Bitfield64PushZero
  BooleanPushFalse
.endm

// "
// EG: (1 2 3 TRUE) Bitfield64BooleanNot (1 2 3 FALSE)
// EG: (1 2 3 FALSE) Bitfield64BooleanNot (1 2 3 TRUE)
// EG: (1 2 3 [something that would cast to TRUE]) Bitfield64BooleanNot
//      ==> (1 2 3 FALSE), and vice versa.
// NEW top of stack (pure Bitfield64 Booleans) => %xmm0
// Testcase confirmed passed 2023-06-23T22:46-07:00
// "
.macro Bitfield64BooleanNot
Bitfield64BooleanNot\@:
  _SetAllBitsZero register=%xmm0
  pcmpeqq DATA_STACK0, %xmm0 // Is subject equal to 0?
  // (nonzero becomes 0, 0 becomes 0xFFFFFFFFFFFFFFFF)
  movdqa %xmm0, DATA_STACK0
.endm

// "
// EG: (1 2 3 TRUE) Bitfield8BooleanNot (1 2 3 FALSE)
// EG: (1 2 3 FALSE) Bitfield8BooleanNot (1 2 3 TRUE)
// EG: (1 2 3 [something that would cast to TRUE]) Bitfield8BooleanNot
//      ==> (1 2 3 FALSE), and vice versa.
// NEW top of stack (pure Bitfield8 Booleans) => %xmm0
// Testcase confirmed passed 2023-06-23T22:46-07:00
// "
.macro Bitfield8BooleanNot
Bitfield8BooleanNot\@:
  _SetAllBitsZero register=%xmm0
  pcmpeqb DATA_STACK0, %xmm0 // Is subject equal to 0?
  // (nonzero becomes 0, 0 becomes 0xFFFFFFFFFFFFFFFF)
  movdqa %xmm0, DATA_STACK0
.endm

// "
// EG: (1 7 TRUE FALSE) BooleanAnd (1 7 FALSE)
// EG: (6 9 FALSE TRUE) BooleanAnd (6 9 FALSE)
// EG: (666 FALSE FALSE) BooleanAnd (666 FALSE)
// EG: (999 TRUE TRUE) BooleanAnd (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with Bitfield(size)castToBoolean: job done.
// Testcase confirmed passed 2023-06-23T22:46-07:00
// "
.macro BooleanAnd
BooleanAnd\@:
  movdqa DATA_STACK0, %xmm0
  pand DATA_STACK1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// EG: (1 7 TRUE FALSE) BooleanOr (1 7 FALSE)
// EG: (6 9 FALSE TRUE) BooleanOr (6 9 TRUE)
// EG: (666 FALSE FALSE) BooleanOr (666 TRUE)
// EG: (999 TRUE TRUE) BooleanOr (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with Bitfield(size)castToBoolean: job done.
// Testcase confirmed passed 2023-06-23T22:46-07:00
// "
.macro BooleanOr
BooleanOr\@:
  movdqa %xmm0, DATA_STACK0
  por DATA_STACK1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
// EG: (1 7 TRUE FALSE) BooleanXor (1 7 TRUE)
// EG: (6 9 FALSE TRUE) BooleanXor (6 9 FALSE)
// EG: (666 FALSE FALSE) BooleanXor (666 FALSE)
// EG: (999 TRUE TRUE) BooleanXor (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with Bitfield(size)castToBoolean: job done.
// Testcase confirmed passed 2023-06-23T22:46-07:00
// "
.macro BooleanXor
BooleanXor\@:
  movdqa DATA_STACK0, %xmm0
  pxor DATA_STACK1, %xmm0
  movdqa %xmm0, DATA_STACK1
  DataStackRetreat
.endm

// "
//Consumes in pop order: A, B, and Mask.
// Returns A and B blended such that Mask lanes that cast to True (high bit set)
// shine through the A term, while cast to false (high bit unset)
// shine through the B term.
// "
.macro Bitfield64MaskBlend
Bitfield64MaskBlend\@:
  movdqa DATA_STACK0, %xmm0 # Load the mask
  movdqa DATA_STACK2, %xmm1 # load A
  blendvpd DATA_STACK1, %xmm1 # blend with B: %xmm0=mask is implicit.
  DataStackRetreatTwice # pop off Mask and B
  movdqa %xmm1, DATA_STACK0 # replace old A with new answer.
.endm

// "
//Consumes in pop order: A, B, and Mask.
// Returns A and B blended such that Mask lanes that cast to True (high bit set)
// shine through the A term, while cast to false (high bit unset)
// shine through the B term.
// Testcase confirmed passed 2023-06-10T16:21-07:00
// "
.macro Bitfield8MaskBlend
Bitfield8MaskBlend\@:
  movdqa DATA_STACK0, %xmm0 # Load the mask
  movdqa DATA_STACK2, %xmm1 # load A
  pblendvb DATA_STACK1, %xmm1 # blend with B: %xmm0=mask is implicit.
  DataStackRetreatTwice # pop off Mask and B
  movdqa %xmm1, DATA_STACK0 # replace old A with new answer.
.endm

// "
# Consumes 3 arguments from the stack. In push order they are:
# * 2:test Mask:Boolean
# * 1:Data argument:Raw64
# * 0:pointerToRun:pointer64:scalarBroadcast
# If test mask is 100% false, this macro exits early.
# If not, then it leaves a copy of the data argument on the stack and
# it runs the pointer. Pointer is expected to either ignore its 1-argument
# input, or consume it and replace it with a single result.
# That result will be blended with the original input using the mask,
# and the result of blending will be left on stack as 1 return value.
# Clobber.. everything is fair game due to lambda that gets run.
# %xmm0 = what the test mask was initially
# %xmm1 = new top of stack (blended result)
// "
.macro Bitfield64ConditionalMaskBlendOneArgument
Bitfield64ConditionalMaskBlendOneArgument\@:
  _DataStackPopGeneral %rdx # get subroutine to call from DATA_STACK0 lane #1
  #Test the mask (position 1 now due to above pop)
  movdqa DATA_STACK1, %xmm0
  ptest %xmm0, %xmm0
  jnz showtime\@
  movdqa DATA_STACK0, %xmm1 # load a copy of the CMBOA input into xmm1
  DataStackRetreat
  jmp skip\@
showtime\@:
  Duplicate # duplicate the input on the stack
  call *%rdx # call subroutine
  # Stack should now have 2:test, 1:original input, and 0:subroutine result.
  movdqa DATA_STACK2, %xmm0 # Reload the mask, tainted by lambda.
  movdqa DATA_STACK1, %xmm1 # load input
  blendvpd DATA_STACK0, %xmm1 # blend with output: %xmm0=mask is implicit.
  # Pop off 2/3 of the current arguments.
  DataStackRetreatTwice
skip\@:
  movdqa %xmm1, DATA_STACK0 # replace remaining argument with final result
.endm

// "
# Consumes 3 arguments from the stack. In push order they are:
# * 2:test Mask:Boolean
# * 1:Data argument:Raw64
# * 0:pointerToRun:pointer64:scalarBroadcast
# If test mask is 100% false, this macro exits early.
# If not, then it leaves a copy of the data argument on the stack and
# it runs the pointer. Pointer is expected to either ignore its 1-argument
# input, or consume it and replace it with a single result.
# That result will be blended with the original input using the mask,
# and the result of blending will be left on stack as 1 return value.
# Clobber.. everything is fair game due to lambda that gets run.
# %xmm0 = what the test mask was initially
# %xmm1 = new top of stack (blended result)
// "
.macro Bitfield8ConditionalMaskBlendOneArgument
Bitfield8ConditionalMaskBlendOneArgument\@:
  _DataStackPopGeneral %rdx # get subroutine to call from DATA_STACK0 lane #1
  #Test the mask (position 1 now due to above pop)
  movdqa DATA_STACK1, %xmm0
  ptest %xmm0, %xmm0
  jnz showtime\@
  movdqa DATA_STACK0, %xmm1 # load a copy of the CMBOA input into xmm1
  DataStackRetreat
  jmp skip\@
showtime\@:
  Duplicate # duplicate the input on the stack
  call *%rdx # call subroutine
  # Stack should now have 2:test, 1:original input, and 0:subroutine result.
  movdqa DATA_STACK2, %xmm0 # Reload the mask, tainted by lambda.
  movdqa DATA_STACK1, %xmm1 # load input
  pblendvb DATA_STACK0, %xmm1 # blend with output: %xmm0=mask is implicit.
  # Pop off 2/3 of the current arguments.
  DataStackRetreatTwice
skip\@:
  movdqa %xmm1, DATA_STACK0 # replace remaining argument with final result
.endm


.macro _Bitfield64BranchPrep
_Bitfield64BranchPrep\@:
  mov DATA_STACK1, %rax # Only take lane 1
  mov DATA_STACK0, %rcx # Only take lane 1
  DataStackRetreatTwice
.endm

.macro _Bitfield64BranchDecideForceCallerToReturn forceBranchCallerToReturn=FALSE
  .if \forceBranchCallerToReturn
_Bitfield64BranchDecideForceCallerToReturn\@:
    ret
  .endif
.endm

.macro BranchUnconditional destination:req forceBranchCallerToReturn=FALSE
BranchUnconditional\@:
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
.endm

// "
# Test STACK1 < STACK0
# signed or unsigned is controlled by data type mode,
# which isn't yet implemented so always unsigned until then.
# If true then branch. If false, do nothing.
// "
.macro Bitfield64BranchLessThan destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchLessThan\@:
  cmp %rcx, %rax
  jae skip\@ # reject above or equal
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// "
# Test STACK1 > STACK0
# signed or unsigned is controlled by data type mode,
# which isn't yet implemented so always unsigned until then.
# If true then branch. If false, do nothing.
// "
.macro Bitfield64BranchGreaterThan destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchGreaterThan\@:
  cmp %rcx, %rax
  jbe skip\@ # reject below or equal
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

# Test STACK1 == STACK0
# If true then branch. If false, do nothing.
.macro Bitfield64BranchEqual destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchEqual\@:
  cmp %rcx, %rax
  jne skip\@ # reject not equal
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

# Test STACK1 bitwise_& STACK0
# EG "do any set bits match between these two bitfields?"
# If nonzero then branch. If zero, do nothing.
.macro Bitfield64BranchAnd destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchAnd\@:
  test %rcx, %rax
  jz skip\@ # reject zero after and
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// "
# Test STACK1 >= STACK0
# signed or unsigned is controlled by data type mode,
# which isn't yet implemented so always unsigned until then.
# If true then branch. If false, do nothing.
// "
.macro Bitfield64BranchGreaterThanOrEqual destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchGreaterThanOrEqual\@:
  cmp %rcx, %rax
  jb skip\@ # reject below
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// "
# Test STACK1 <= STACK0
# signed or unsigned is controlled by data type mode,
# which isn't yet implemented so always unsigned until then.
# If true then branch. If false, do nothing.
// "
.macro Bitfield64BranchLessThanOrEqual destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchLessThanOrEqual\@:
  cmp %rcx, %rax
  ja skip\@ # reject above
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

# Test STACK1 != STACK0
# If true then branch. If false, do nothing.
.macro Bitfield64BranchNotEqual destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchNotEqual\@:
  cmp %rcx, %rax
  je skip\@ # reject if equal
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

# Test logical_not(STACK1 bitwise_& STACK0)
# EG "do zero set bits match between these two bitfields?"
# If zero then branch. If nonzero, do nothing.
.macro Bitfield64BranchNand destination:req forceBranchCallerToReturn=FALSE
  _Bitfield64BranchPrep
Bitfield64BranchNand\@:
  test %rcx, %rax
  jnz skip\@ # reject nonzero after and
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// input value should not use a sigil, that will get added in the macro.
.macro Bitfield64Immediate value:req
Immediate\@:
  movq $\value, %rax
  _Bitfield64DataStackPushGeneral %rax
.endm

// input values should not use sigils, those will get added in the macro.
.macro Bitfield64ImmediateVector128 value1:req value2:req
ImmediateVector\@:
  movq $\value1, %rax
  _DataStackAdvance
  mov %rax, DATA_STACK0
  movq $\value2, %rax
  mov %rax, DATA_STACK0_5
.endm

// Testcase confirmed passed 2023-06-10T16:21-07:00
.macro Bitfield8Immediate value:req
Immediate\@:
  // only lowest 8 bits will survive,
  // but hardware limitations require me
  // to pass this value around as 32-bit or greater.
  mov $\value, %eax
  _Bitfield8DataStackPushGeneral %eax
.endm

// New top of stack => %xmm0
// Testcase confirmed passed 2023-06-10T16:21-07:00
.macro Bitfield8ImmediateVector128 \
  value1:req  value2:req  value3:req  value4:req \
  value5:req  value6:req  value7:req  value8:req \
  value9:req  value10:req value11:req value12:req \
  value13:req value14:req value15:req value16:req
ImmediateVector\@:
  movaps ImmediateVector128InMemory\@(%rip), %xmm0
  _SIMDPush
  jmp EndImmediateVector\@
.balign SIMD_WIDTH
ImmediateVector128InMemory\@:
.byte \value1,  \value2,  \value3,  \value4
.byte \value5,  \value6,  \value7,  \value8
.byte \value9,  \value10, \value11, \value12
.byte \value13, \value14, \value15, \value16
EndImmediateVector\@:
.endm

# Prepend a caller-specified literal/immediate string message
# to a call to PrintStack.
.macro PrintStackMessage message:req
PrintStackMessage\@:
  putNewlineMacro
  putLiteralMacro "== "
  putLiteralMacro "\message"
  putNewlineMacro
  call PrintStack
.endm

// clobbers xmm0
// Branch if high bit of every byte of STACK0 is all ones.
// tested 2022-04-18
.macro VectorBranchTrue destination:req forceBranchCallerToReturn=FALSE
VectorBranchTrue\@:
  movdqa DATA_STACK0, %xmm0
  DataStackRetreat
  pmovmskb %xmm0, %rax
  cmp $0xFFFF, %rax
  jnz skip\@
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// clobbers xmm0
// Branch if high bit of every byte of STACK0 is all zeros.
// tested 2022-04-20T22:59-07:00
.macro VectorBranchFalse destination:req forceBranchCallerToReturn=FALSE
VectorBranchFalse\@:
  movdqa DATA_STACK0, %xmm0
  DataStackRetreat
  ptest %xmm0, %xmm0
  jnz skip\@
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// clobbers xmm0
// Untested
.macro VectorBranchAnd destination:req forceBranchCallerToReturn=FALSE
VectorBranchAnd\@:
  DataStackRetreatTwice
  movdqa DATA_STACK_NEGATIVE2, %xmm0
  pand DATA_STACK_NEGATIVE1, %xmm0
  jz skip\@
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// clobbers xmm0
// Tested 2022-04-21T00:35-07:00
.macro VectorBranchMaskEqual destination:req forceBranchCallerToReturn=FALSE
VectorBranchMaskEqual\@:
  DataStackRetreatThrice
  movdqa DATA_STACK_NEGATIVE1, %xmm0
  pand DATA_STACK_NEGATIVE3, %xmm0
  pxor DATA_STACK_NEGATIVE2, %xmm0
  ptest %xmm0, %xmm0
  jnz skip\@
  call \destination
  _Bitfield64BranchDecideForceCallerToReturn \forceBranchCallerToReturn
skip\@:
.endm

// UnderTested
.macro indexedRAMtoStack metaIndex=0 basePointer:req ClobberRegisterSIMD=%xmm0 ClobberRegisterScalarA=%rax ClobberRegisterScalarB=%rcx
  Bitfield64Immediate \metaIndex
  Bitfield64Index
  mov DATA_STACK0, \ClobberRegisterScalarA // scoop up index
  shl $SIMD_META_WIDTH, \ClobberRegisterScalarA // convert to number of SIMD widths
  lea \basePointer, \ClobberRegisterScalarB // get RAM base pointer
  add \ClobberRegisterScalarB, \ClobberRegisterScalarA // Add to index number of SIMD widths
  movdqa (\ClobberRegisterScalarA), \ClobberRegisterSIMD // xmm0 now has contents of index row out of RAM
  movdqa \ClobberRegisterSIMD, DATA_STACK0
.endm

##### End of macros
