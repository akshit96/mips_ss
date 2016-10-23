`default_nettype none

module register_5(input clk, input reset, input write, input [4:0] in, output reg [4:0] out);
    always @(negedge clk)
    begin
        if(reset)
            out <= #1 31;
        else if(write)
            out <= #1 in;
    end
endmodule

module regfile(write, raddr0, raddr1, waddr, rdata0, rdata1, wdata);
    parameter M = 5;    // address bus width
    parameter N = 32;   // 2**M
    parameter W = 32;   // data bus width

    input write;
    input [M-1:0] raddr0, raddr1, waddr;
    output [W-1:0] rdata0, rdata1;
    input [W-1:0] wdata;

    reg [W-1:0] mem[0:N-1];

    initial
        mem[0] = 0;

    assign rdata0 = mem[raddr0];
    assign rdata1 = mem[raddr1];

    integer i;
    always @(write or waddr or wdata)
    begin
        if(write & waddr!=0)
            mem[waddr] <= #2 wdata;
        // $0 is hardwired to value 0
    end
endmodule

module test_regfile;
    reg clk, write;
    reg [4:0] raddr0, raddr1, waddr;
    reg [31:0] wdata;
    wire [31:0] rdata0, rdata1;

    regfile myregfile(clk, write, raddr0, raddr1, waddr, rdata0, rdata1, wdata);

    //At every falling clock edge, display values read from regfile
    always @(negedge clk)
    begin
        $display($time, ": reg0=%d, reg1=%d", rdata0, rdata1);
        //$display($time, ": write=%d, raddr0=%d, raddr1=%d, waddr=%d, rdata0=%d, rdata1=%d, wdata=%d",
        //    write, raddr0, raddr1, waddr, rdata0, rdata1, wdata);
    end

    initial
    forever
    begin
        clk = 0;
        #50
        clk = 1;
        #50
        clk = 0;
    end

    initial
    begin
        raddr0 = 1;
        raddr1 = 2;
        waddr = 1;
        write = 0;
        #50
        write = 1;
        wdata = 123;
        #100
        wdata = 234;
        write = 0;
        #100
        write = 1;
        waddr = 2;
        #100
        waddr = 1;
        #100
        #150
        $finish;
    end

    initial
    begin
        $dumpfile("test_regfile.vcd");
        $dumpvars;
    end
endmodule

module ram(read, write, addr, rdata, wdata);
    parameter M = 5;    // address bus width
    parameter N = 32;   // 2**M
    parameter W = 32;   // data bus width

    input read, write;
    input [M-1:0] addr;
    output reg [W-1:0] rdata;
    input [W-1:0] wdata;

    reg [W-1:0] mem[0:N-1];

    always @(read or write or addr)
    begin
        if(write)
            mem[addr] <= #2 wdata;
        if(read)
            rdata <= #2 mem[addr];
        else
            rdata <= #2 32'bZ;
    end
endmodule

module test_ram;
    reg clk, read, write;
    reg [4:0] addr;
    wire [31:0] rdata;
    reg [31:0] wdata;

    ram myram(clk, read, write, addr, rdata, wdata);

    initial
    forever
    begin
        clk = 0;
        #50
        clk = 1;
        #50
        clk = 0;
    end

    initial
    begin
        read = 0;
        write = 1;
        #50
        addr = 0;
        wdata = 1;
        #100
        addr = 1;
        wdata = 1;
        #100
        addr = 2;
        wdata = 2;
        #100
        addr = 3;
        wdata = 3;
        #100
        addr = 4;
        wdata = 5;
        #100
        read = 0;
        write = 0;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        read = 1;
        write = 0;
        addr = 4;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 0;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 1;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 3;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 2;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 4;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        read = 0;
        write = 1;
        addr = 0;
        wdata = 10;
        #100
        addr = 1;
        wdata = 15;
        #100
        read = 1;
        write = 0;
        addr = 0;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 1;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 2;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 3;
        #100
        $display($time, ": addr=%d, data=%d", addr, rdata);
        addr = 4;
        #200
        $finish;
    end

    initial
    begin
        $dumpfile("test_ram.vcd");
        $dumpvars;
    end
endmodule

module dummy_irom(input [4:0] addr, output reg [31:0] data);
    // An instuction ROM which has a program in it
    // Add numbers in first 2 memory locations and store the result in the 3rd memory location
    always @(addr)
    begin
        if(addr == 0)
            data = #2 32'b100011_00000_00001_0000000000000000;   // lw $1, 0($0)
        else if(addr == 1)
            data = #2 32'b100011_00000_00010_0000000000000001;   // lw $2, 1($0)
        else if(addr == 2)
            data = #2 32'b000000_00001_00010_00011_00000_100000; // add $3, $1, $2
        else if(addr == 3)
            data = #2 32'b101011_00000_00011_0000000000000010;   // sw $3, 2($0)
        else
            data = #2 0;    // nop (TODO: replace with branch)
    end
endmodule
