`default_nettype none

module alu_32(cout, out, op, in0, in1);
    parameter N = 32;
    output reg cout;
    output reg [N-1:0] out;
    input [2:0] op;
    input [N-1:0] in0, in1;

    always @(op or in0 or in1)
    begin
        if(op[2:1] == 0) // op is 0 or 1
            {cout, out} = in0 + in1;
        else if(op[2:1] == 1) // op is 2 or 3
            {cout, out} = in0 - in1;
        else if(op == 4)
            {cout, out} = in0 & in1;
        else if(op == 5)
            {cout, out} = in0 | in1;
        else if(op == 6)
            {cout, out} = in0 ^ in1;
        else
            {cout, out} = ~(in0 | in1);
    end
endmodule

module test_alu_32();
    reg [31:0] in0, in1;
    wire [31:0] out;
    reg [2:0] op;
    wire cout;
    alu_32 myalu(cout, out, op, in0, in1);
    initial
    begin
        $monitor(, $time, ": a=%h, b=%h, op=%b, out=%h, cout=%b",
            in0, in1, op, out, cout);
        in0 = 32'h0f00000f;
        in1 = 32'h0234567a;
        op = 2'b00;
        #10
        op = 2'b01;
        #10
        op = 2'b10;
        #10
        op = 2'b11;
        #10
        in0 = 32'h0f00000f;
        in1 = 32'hf234567a;
        op = 2'b10;
        #10
        op = 2'b11;
        #10
        in0 = 32'hff00000f;
        in1 = 32'h0234567a;
        op = 2'b10;
        #10
        op = 2'b11;
        #10
        in0 = 32'hff00000f;
        in1 = 32'hf234567a;
        op = 2'b10;
        #10
        op = 2'b11;
    end
endmodule
