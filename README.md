# PLP Project



## Summary
This project represents a converter from a basic custom language to assembly code which can be assembled with nasm and then compiled with gcc.

**NOTE**: The assembly code created is for x86_64 architecture only. Also, test have been done on Debian 9 only, but it should work on other operating systems too.



## Prerequisites
- gcc
- nasm
- K framework ([4.0.0](https://github.com/kframework/k/releases/download/v4.0.0/k-distribution-4.0.0.zip) recommended)
- JDK8 (8u144 recommended)



## Build & Run
To build use `make` or `make build`.
If you want to also convert, assemble and compile the test file use `make all` or `make test`.

Alternatively you can use `./build` for building the project and `./convert filename` to convert, assemble and compile a file *filename*.

There is also `debug filename` (or `make debug` for the test file) which prints on the screen the configuration when no more rules can be applied, either because the conversion succeeded, the input has (syntactic/semantic) errors, or because of a bug. The assembly code created is printed only if the conversion succeeded, otherwise it can be found in the \<asm> cell int the configuration.
