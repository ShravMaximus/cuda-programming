# OMSCS-CS8803 Project-5: Warp Branch Divergence Detection 

In this assignment, you will implement a branch divergence detection module on a framework that parses SASS instructions and generates IR code. This assignment aims to give you an insight into the practical usage of assembly codes, basic blocks, and control flow graphs. 

Normally, this analysis is done with a compiler frame as we discussed in Module #11. (https://llvm.org/devmtg/2018-04/slides/Moll-A%20new%20divergence%20analysis%20for%20LLVM.pdf, https://llvm.org/devmtg/2021-11/slides/2021-LateDivergenceAnalysis.pdf)
However, adding a compiler pass on LLVM requires background knowledge of LLVM, we are providing a GT developed project SASS Lifter which converts SASS to LLVM IR. With this frame, we can handle IR just like compilers but the code is written in python. 

## Pre-requirement Software   
The pre-requirement of the development environment includes: Python 3, LLVM and its Python interface LLVMLite. Students might use the PACE-ICE cluster. The installation instructions for pre-requirement are list below:


### Setup :
- Login to PACE-ICE 
- Install anaconda - 
  - cd into scratch space (/home/hice1/<username>/scratch) [This step is very important to not run out of home directory space]
  - wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  - bash ./Miniconda3-latest-Linux-x86_64.sh ; 
  > During the install step, ensure the path is /home/hice1/<username>/scratch/miniconda3 
  > Default would be : /home/hice1/<username>/miniconda3 [change this]
  - Restart terminal [ensure that conda is installed : conda –version]
- Setup the conda environment - 
  - conda create --name prj5_conda
  - conda activate prj5_conda
  - conda install -c conda-forge llvm llvmlite

- Running the tool :
  - Clone the repo : git clone : https://github.gatech.edu/summer2024GPUTAs/CS8803_GPU_prj5.git
  - python3 main.py -i test/<SASS file> -o <name of the output IR (.ll) file>
  
 > Note: For this project, it is not necessary to use PACE-ICE, and it can be completed locally if desired.


## Branch Divergence in GPUs
Branch divergence in GPUs occurs when threads within a GPU warp (a group of threads executing in lockstep) take different paths through conditional branches in a kernel. It arises from conditional statements that lead different threads in the same warp to execute different instructions. When this happens, the GPU must execute each path sequentially, potentially reducing parallelism and performance. Minimizing branch divergence is crucial for achieving optimal performance in GPU computing, as it ensures that threads within a warp remain synchronized, allowing for efficient execution of parallel tasks. Techniques such as predication, loop unrolling, and careful kernel design can help mitigate branch divergence effects. The first step in all these techniques is the detection of branch divergence which is the objective of this assignment.

## Basic Blocks (BB) and Control Flow Graphs (CFG)
In the compiler concept, a basic block refers to a sequence of code within a program. It is the essential building block of the control-flow graph (CFG). A basic block has a single entry point (the first instruction) and a single exit point (the last instruction). Control flow graphs represent a program's flow with nodes as basic blocks and edges as control flow. Further details about their role and construction are covered in lecture modules.

## Def - Use Table
Def-Use tables are data structures used to track the definitions and uses of variables within a program. Each entry records where a variable is defined (its "def") and where it is subsequently used (its "use"). This information is used for several purposes, like optimizing compilers to analyze dependencies, eliminating redundant computations, and performing register allocation efficiently. Def-Use tables are fundamental in dataflow analysis, enabling compilers to understand how variables are manipulated throughout a program's execution. In this assignment you will be using the def-use table for branch divergence detection.

## SASS Lifter

SASS Lifter is a GT developed project for converting CUDA low-level assembly (SASS) into LLVM intermediate representation (IR). This process enables application portability and makes it possible to apply a wider range of program analysis.

- The `parse` folder contains parsers specialized for different compute architectures, which recognize and process SASS assembly code.
- The `sir` folder contains higher-level data structures and the implementation of the lifting process.
- The `transform` folder includes various transformations. The `typeanalysis.py` and `opaggregate.py` files help adapt SASS into LLVM IR format. For this assignment, you should only modify `typeanalysis.py`.
- The `lift` folder contains the code that initiates the SASS lifting process.

**Note:** In this project, we only use the parsing features of the SASS Lifter. You do not need to actually lift any SASS files into LLVM IR.

## Assignment Tasks

  ### Task 1 : Construct the Def-Use Table
  In 'transform/branchdivergence.py', you are expected to utilize the basic blocks of a function, and traverse the control flow graph in order to generate a def-use table for all registers. 
  - Find the entry basic block.
  - Use predecessors and successors of basic blocks to traverse through the control flow graph.
  - Track the latest def of registers.
  - Update the def-use table appropriately with key, value {def, use} till the entire CFG has been covered.

  > Note (hint) : Same registers can have multiple definitions. Store additional information to track the latest definition.
  > Note (hint) : One basic block could have multiple predecessor blocks.
  > Note (hint) : The entry block is the first basic block of the function.
  > Note (hint) : Use `Instruction.GetDef()` to obtain user registers and `Instruction.GetUse()` to obtain used registers. 

  ### Task 2 : Identification of thread dependent instructions
  Thread IDs are loaded into registers through instructions with opcode "S2R". This creates a thread ID dependent definition. Usage of these thread dependent instructions propagates threadID dependency in the program. 
  - Use your Def-Use table to find all instructions tainted by thread ID.
  - Store the instructions in a data structure to be investigated for branch divergence.

  > Optionally, in task 1, you can store only thread ID dependent instructions. However, this is an implementation optimization and is not compulsory for this assignment.

  ### Task 3 : Identify branch divergence [10 points]
  From the instructions shortlisted in Task2, identify branch instructions. Since these branch instructions are threadID dependent, they are potential points of divergence. Append the ID (instruction._id) to "branch_divergence_inst_ids[]" of the function. Please do not modify the name of this list as the instruction IDs reported in this will be used for evaluation.

  ### Task 4 : Identify branch divergence in loops  [10 points]
 The implementation should also detect branch divergence from single entry, single exit loops. Modify the construction of def-use table and taint analysis to follow an iterative approach. Some information should be tracked per basic block. For instance, the same register name will lead to different definitions at different basic blocks. The iteration should stop when there is no changes in an iteration.

## Grading
1. The assignment is worth 20 points.
2. 0 points if you don't submit anything by the deadline.
3. Rubric for Project 5 : The tasks for this assignment are broken into sub tasks only to ease comprehension and implementation. Score will be assigned on completion and correct results from Tasks 3 and 4.
  - Task 3 involve 4 base test cases, each worth 2.5 pts, for a total of 10 pts:
    - test/spaxy.sass
    - test/spaxy1.sass
    - test/hetero_mark_aes.sass
    - test/vecaddtest.sass
  - Task 4 involves 5 loop test cases, each worth 2 pts, for a total of 10 pts:
    - test/loop1.sass
    - test/loop2.sass
    - test/loop3.sass
    - test/loop4.sass
    - test/loop5.sass
  
## Submission Guideline
You must submit all the deliverables on GradeScope (Which can be accessed through the Canvas menu).
Compress the <ins>contents</ins> of the CS8803_GPU_prj5 repo (cloned from github) with your changes into a zip file and submit it to Gradescope. You may use the provided `make_submission.sh` script.