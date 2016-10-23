`default_nettype none

module mux2to1(output out, input s, input in0, input in1);
    assign out = s ? in1 : in0;
endmodule

module mux2to1_5(output [4:0] out, input s, input [4:0] in0, input [4:0] in1);
    assign out = s ? in1 : in0;
endmodule

module mux2to1_32(output [31:0] out, input s, input [31:0] in0, input [31:0] in1);
    assign out = s ? in1 : in0;
endmodule
