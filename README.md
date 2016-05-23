I started this project as an exercise in brushing up on systems programming. I
needed to review assembly syntax, calling conventions, memory maps, segmentation
(of the system memory and executable varieties), etc. The goal was to have a
clear view of everything from a line of C fed to the compiler on the host, to
the OS's interaction with the underlying hardware. (Or, in other words, how to
get from that first BIOS thunk at `0x7c00` to running a nice C program!)

This project implements a (very) limited 32-bit operating system that can run on
an x86 processor. After some time, it's now advanced enough to run some
user-mode programs (which I have been using for exercises a bit further up the
stack) compiled with plain-old `gcc`.

I tried to steer clear of too much inspiration material when building this, and
forge through problems by reading the hardware manuals -- or online resources of
equivalent clarity -- and not simply copy-pasting code. The result was a lot of
time spent solving already-solved problems -- the world doesn't need another x86
OS -- but there's no substitute for getting your hands dirty. (This is, after
all, why we are expected to know sorting algorithms, for example, which are
already widely implemented in standard libraries in nearly every language.)

Quick facts
-----------
* The generated output of `make` is `disk_image`, a small disk image with a valid boot sector which contains everything -- the MBR, the kernel, the filesystem.
* The magic starts in [boot16.asm](boot16.asm) at memory address `0x7c00`.
* From a few instructions into [boot32.asm](boot32.asm) until the end of time, we run in 32-bit protected mode, with paging enabled.
* We handle exceptions (all of the Intel defined and reserved ones, from `0x00` to `0x1f`) by printing the state of the registers and permanently halting.
* Virtual memory is enabled, to give user-mode programs a separate page for their code and data, and to protect the kernel code from being modified by user-mode programs. User-mode programs get a 4MB stack because we're using large pages.
* [The loader](loader.asm) reads ELF files, but with a lot of limitations.
* On boot, after everything is set up, we load one program from our "filesystem", and if it's a valid ELF in our world (which is a tighter definition than the actual ELF spec), start executing it.
* The loader supports the `.text`, `.data`, `.rodata`, and `.bss` sections, but only to a point -- 4MB cumulative for `.text` and `.rodata`, 2MB cumulative for `.rodata` and `.bss`. And there's no dynamic memory allocation. So you're not going to sort 1,000,000 `int`s on this bad boy. Yet.
* The `exit` system call is implemented by halting the processor. Once we run that one user-mode program, we're done!

Resources used
--------------
* Obviously, [Intel® 64 and IA-32 Architectures Software Developer Manuals](http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html)
