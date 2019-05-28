# Sorting a Large Number of Integers

This project is a fun exercise in sorting a very large number of integers while keeping only a subset of integers in memory at any particular time. The number of integers to load and keep in memory at any given time is known as "chunk", and all the integers will be sorted and placed in an output file without ever storing more than one chunk of integers in memory.

How do we sort a bunch of integers without loading them all into memory? The answer is files: we produce a lot of sorted intermediate files and them merge them together one integer at at time to produce the final sorted output file.

I originally saw this listed somewhere as an interview question, and while I figured out the answer fairly quickly ("Store the integers in files, sort them in chunks, and then merge the sorted chunks"), I found myself pondering the implementation details. In other words, how would I implement that solution?

I first solved the problem in the [NodeLargeSort](https://github.com/Maultasche/NodeLargeSort) project using Node.js to help me get better at coding in Node.js. Then I implemented the solution again in the [LargeSortCSharp](https://github.com/Maultasche/LargeSortCSharp) project just to see how well I could do it in C# and to see how the performance differed from the Node.js implementation. Now in this project, I'm going to reimplement the solution in Elixir to practice using Elixir.

This project consists of two runnable programs.

1. A program for generating large numbers of random integers
  - Accepts the number of integers to generate as an input parameter
  - Writes the randomly generated integers to an output file, the name of which is an input parameter
  - The output file contains one integer per line
2. A program for sorting the file of random integers
  - Accepts the input file and the maximum number of integers to load into memory at any time during the process (aka the chunk size)
  - Writes the final result to an output file, the name of which is also an input parameter
  - Accepts a parameter which will tell the sorting program to not erase the intermediate files when it is done
  - The input file is assumed to have one integer per line and will produce an output file with one integer per line
  
## The Sorting Solution

The solution is essentially a version of merge sort that uses files and has variable-length merge chunks, where N chunks can be 
merged together in a single step instead of two at a time like the typical merge sort. I'm going to go into it in more detail below in the Sorting Strategy section.

## Sorting Strategy

If only N integers can be loaded into memory at any given time, but the total number of integers (T) is such that T > N, we'll have to follow a strategy of sorting chunks of integers and then merging those chunks.

1. Analyze the input file to determine how many lines there are, which will tell us how many integers there are (T)
2. Divide T by N (rounding up) to determine how many chunks of integers we'll be sorting
3. Read through the input file, reading chunks of N integers into memory
4. Sort each chunk of integers in memory and write each chunk to an intermediate file, which will result in F intermediate files, where F * N >= T. The last chunk will likely be smaller than N unless T % N === 0. This first batch of intermediate files will be referred to as Gen 1 files.
5. We'll open up to P intermediate files at a time, where P will probably be 10. Each file contains a chunk of sorted integers, so we'll have P pointers to the integers at the beginning of the file.
6. We'll find the min value in that set of P integers, and write that min value to an intermediate output file. Then we'll take the file pointer where the min value originated from and advance that file pointer to the next integer. We'll repeat this until all P file pointers have advanced to the end of the file.
7. Repeat Steps 5 and 6 until all F output files have been processed. The resulting sorted files will be referred to as Gen 2 files. 
8. At this point, we may only have one Gen 2 file, in which case we are be finished, but if F > P, we'll have multiple Gen 2 files where the size of each file is P * N integers or less. In that case, repeat Steps 5 - 7 until all we only produce a single output file (the Gen R file, where R is the number of intermediate file iterations we went through). All the sorted integers from the initial set of intermediate files will now be merged into a single sorted file, and we'll be finished.

Each intermediate file iteration will reduce the number of intermediate files by a factor of P, so the performance of the merging process is O(N Log(N))

The following diagram is a visualization of the sorting strategy for those of you who'd prefer to look at a diagram rather than carefully reading through the above steps.

![Sorting Stategy Diagram](doc/IntegerSortingProcess.png)

## Testing Stategy

In addition to the suite of unit tests, I intend to run the finished product through some tests to verify that the entire thing works under a variety of scenarios.

- Test sorting an empty file [Not Run]
- Test sorting a file with a single number [Not Run]
- Test sorting 20 numbers, where we can easily verify all the numbers [Not Run]
- Test sorting an input file where T < N, and verify that the correct intermediate files were produced [Not Run]
- Test sorting an input file where T === N, and verify that the correct intermediate files were produced [Not Run]
- Test sorting an input file where T > N, and verify that the correct intermediate files were produced [Not Run]
- Test sorting an input file where T > P * N, and verify that the correct intermediate files were produced [Not Run]
- Test sorting an input file where T == (P * N) + 1, and verify that P + 1 intermediate sorted chunk files were produced, with the first P files having N sorted integers in them, and the P + 1 file having one integer in it. The first round of merging should produce two intermediate, the first file with P * N sorted integers in it and the second file having a single integer in it. After the second round of merging, the integer in the second file should be merged with the other integers in the final output file. [Not Run]
- Test sorting a very large number of integers. A billion integers would suffice. [Not Run]
- Test sorting using small (1,000), moderate (10,000), and large numbers for N (1,000,000) [Not Run]

## Current Status

I've not yet begun coding on this project, but that should be starting soon.

## Running the Integer Generator and Sorting Tools

This section will be filled in later.
 
## Running Tests

This section will be filled in later.

## Understanding the Code

If you're interested in understanding the structure of the code, there's documentation describing how the code is structured.

- [IntGen](doc/IntGenImplementationDetails.md)
- [IntSort](doc/IntSortImplementationDetails.md)
