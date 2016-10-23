`default_nettype none

module sign_extend_16to32(output [31:0] out, input [15:0] in);
    assign out = {{16{in[15]}}, in};
endmodule

module left_shift_by_2_32(output [31:0] out, input [31:0] in);
    assign out = out << 2;
endmodule

module mips_ss(clk, enable, reset, pc, imem_data, dmem_read, dmem_write, dmem_addr, dmem_rdata, dmem_wdata);

    input clk, enable, reset;
    output [4:0] pc; // also called imem_addr
    input [31:0] imem_data;
    output dmem_read, dmem_write;
    output [4:0] dmem_addr;
    input [31:0] dmem_rdata;
    output [31:0] dmem_wdata;

    register_5 pc_reg(clk, reset, enable, pc+5'd1, pc);
    //wire [31:0] instr = enable ? imem_data : 0;
    wire [31:0] instr = enable ? imem_data : 0;

    wire [5:0] opcode = instr[31:26];
    wire [4:0] rs = instr[25:21];
    wire [4:0] rt = instr[20:16];
    wire [4:0] rd = instr[15:11];
    wire [4:0] shamt = instr[10:6];
    wire [5:0] fcode = instr[5:0];
    wire [15:0] imm_data_16 = instr[15:0];

    wire [31:0] seo, selso;
    sign_extend_16to32 seo_hdw(seo, imm_data_16);
    left_shift_by_2_32 selso_hdw(selso, seo);

    wire regDst, memToReg, regWrite, aluSrc, branch;
    wire [1:0] aluOp;
    wire [2:0] alu_s;
    main_cu my_main_cu(opcode, regDst, memToReg, regWrite, aluSrc, branch, aluOp, dmem_read, dmem_write);
    alu_cu my_alu_cu(alu_s, aluOp, fcode[3:0]);

    wire [31:0] reg0, reg1, regfile_wdata;
    wire [4:0] regfile_waddr = regDst ? rd : rt;
    regfile my_regfile(regWrite, rs, rt, regfile_waddr, reg0, reg1, regfile_wdata);
    wire [31:0] alu_in1 = aluSrc ? seo : reg1;

    wire cout;
    wire [31:0] alu_out;
    alu_32 my_alu(cout, alu_out, alu_s, reg0, alu_in1);

    assign dmem_addr = alu_out;
    assign dmem_wdata = reg1;
    assign regfile_wdata = memToReg ? dmem_rdata : alu_out;

/*
    reg [15:0] my_time;
    always @(posedge clk)
    begin
        assign my_time = $time;
        $display("mips_ss: %d:", my_time);
        $display("pc=%d, enable=%d, reset=%d", pc, enable, reset);
        $display("opcode=%d, rs=%d, rt=%d, rd=%d, imm_data_16=%d", opcode, rs, rt, rd, imm_data_16);
        $display("regWrite=%b, regDst=%b", regWrite, regDst);
        $display("regfile_waddr=%d, regfile_wdata=%d, reg0=%d, reg1=%d", regfile_waddr, regfile_wdata, reg0, reg1);
        $display("my_main_cu.r=%d, my_main_cu.lw=%d, my_main_cu.sw=%d, my_main_cu.branch=%d",
            my_main_cu.r, my_main_cu.lw, my_main_cu.sw, my_main_cu.branch);
        $display("aluOp=%d, alu_s=%d, alu_out=%d", aluOp, alu_s, alu_out);
        $display("dmem_read=%b, dmem_write=%b, dmem_addr=%d, dmem_rdata=%d, dmem_wdata=%d",
            dmem_read, dmem_write, dmem_addr, dmem_rdata, dmem_wdata);
        $display("");
    end
*/

endmodule

module test_mips_ss;

    /*
    Testing has 3 phases.
    1.  The test bench writes a number to each of the first 2 locations of the data RAM.
    2.  The processor is given control of the data RAM and it starts executing.
        The processor executes a program which loads the first 2 numbers from the RAM and writes their sum
        to the 3rd memory location.
    3.  The test bench takes back control of the data RAM and checks if the 3rd location has the correct sum.
    */

    reg clk, proc_enable, proc_reset;
    reg [15:0] my_time;

    wire [4:0] imem_addr;
    wire [31:0] imem_data;

    wire [31:0] dmem_rdata;
    wire dmem_read, dmem_write;
    wire [4:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire proc_dmem_read, proc_dmem_write;
    wire [4:0] proc_dmem_addr;
    wire [31:0] proc_dmem_wdata;
    reg test_dmem_read, test_dmem_write;
    reg [4:0] test_dmem_addr;
    reg [31:0] test_dmem_wdata;

    mux2to1 dmem_read_mux(dmem_read, proc_enable, test_dmem_read, proc_dmem_read);
    mux2to1 dmem_write_mux(dmem_write, proc_enable, test_dmem_write, proc_dmem_write);
    mux2to1_5 dmem_addr_mux(dmem_addr, proc_enable, test_dmem_addr, proc_dmem_addr);
    mux2to1_32 dmem_wdata_mux(dmem_wdata, proc_enable, test_dmem_wdata, proc_dmem_wdata);

    dummy_irom myirom(imem_addr, imem_data);
    ram mydram(dmem_read, dmem_write, dmem_addr, dmem_rdata, dmem_wdata);
    mips_ss mymips(clk, proc_enable, proc_reset, imem_addr, imem_data,
        proc_dmem_read, proc_dmem_write, proc_dmem_addr, dmem_rdata, proc_dmem_wdata);

    initial
    forever
    begin
        clk = 0;
        #50
        clk = 1;
        #50
        clk = 0;
    end

    parameter x1 = 112;
    parameter x2 = 123;
    initial
    begin
        proc_enable = 0;
        proc_reset = 1;
        test_dmem_read = 0;
        test_dmem_write = 1;
        #50
        test_dmem_addr = 0;
        test_dmem_wdata = x1;
        #100
        proc_reset = 0;
        test_dmem_addr = 1;
        test_dmem_wdata = x2;
        #100
        proc_enable = 1;
        #400
        proc_enable = 0;
        test_dmem_read = 1;
        test_dmem_write = 0;
        test_dmem_addr = 2;
        #100
        $display("%0d + %0d = %0d (Should be %0d)", x1, x2, dmem_rdata, x1 + x2);
        #100
        $finish;
    end
endmodule
