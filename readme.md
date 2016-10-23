# Single-cycle MIPS processor

This is a partial implementation of a single-cycle MIPS processor for the course
'CS F342 - Computer Architecture' in BITS Pilani.

## Compilation and simulation

All verilog files must be compiled together.
The main test bench is in `main.v` and is called `test_mips_ss`.

In Icarus Verilog, compilation can be done like this:

    iverilog *.v -s test_mips_ss

## Design philosophy

Verilog code has been written with a focus on simiplicity, not on accurate emulation.

To reduce code size, gate-level modelling has been avoided.
However, the module `mips_ss` (the main processor) has been written mostly using gate-level modelling,
because that better describes the structure of the processor.
