`include "full_adder.v"
`include "half_adder.v"

module Exact_4x4(
    input [3:0] a,
    input [3:0] b,
    output [7:0] Y
);

    assign Y = a * b;
endmodule