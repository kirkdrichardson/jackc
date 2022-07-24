# About

The frontend of a two-tier compiler for the Jack programming language that fulfills specifications found in the [Nand2Tetris course](https://www.nand2tetris.org/). 

### Input
Files containing the Jack programming language, specified by a `.jack` file type. Files may be compiled individually, or recursively within a directory.

### Output
A `{Jack_file_name}.vm` file corresponding 1:1 with each `.jack` file. Directory structure is mirrored, if applicable.

### Running
See [Nand2Tetris course](https://www.nand2tetris.org/) for tools to run the compiled vm code, or use the [compiler's backend](https://github.com/kirkdrichardson/vm_translator) responsible for translating the virtual machine language output into assembly language targeting the Hack platform. This assembly may then be run with tools found at [Nand2Tetris](https://www.nand2tetris.org/).
