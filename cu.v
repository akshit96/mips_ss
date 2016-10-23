`default_nettype none

module main_cu(input [5:0] opcode,
    output regDst, output memToReg, output regWrite,
    output aluSrc, output branch, output [1:0] aluOp,
    output memRead, output memWrite);

    wire r, lw, sw, beq;
    assign r = (opcode == 0);
    assign lw = (opcode == 35);
    assign sw = (opcode == 43);
    assign branch = (opcode == 4);

    assign regDst = r;
    assign aluSrc = lw | sw;
    assign memToReg = lw;
    assign regWrite = r | lw;
    assign memRead = lw;
    assign memWrite = sw;
    assign aluOp[0] = branch;
    assign aluOp[1] = r;
endmodule

module alu_cu(output [2:0] alu_s, input [1:0] aluOp, input [3:0] fcode);
    assign alu_s = aluOp[1] ? fcode[2:0] : (aluOp[0] ? 2 : 0);
endmodule
