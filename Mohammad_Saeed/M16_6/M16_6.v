`include "M2_4x4.v"
`include "M8_6.v"
`include "half_adder.v"
`include "full_adder.v"
`include "Exact_4x4.v"


module M16_1(
    input [15:0] a,
    input [15:0] b,
    output [31:0] Y
);

    // Split inputs into lower and higher 4 bits
    wire [7:0] a_L = a[7:0];
    wire [7:0] a_H = a[15:8];
    wire [7:0] b_L = b[7:0];
    wire [7:0] b_H = b[15:8];

    // Partial product wires
    wire [7:0] aL_bL;
    wire [7:0] aL_bH;
    wire [7:0] aH_bL;
    wire [7:0] aH_bH;

    // Instantiate M1_4x4 for each partial product
    M8_6 M_1 (.a(a_L), .b(b_L), .Y(aL_bL)); // Lower 4 bits of a and b
    M8_6 M_2 (.a(a_L), .b(b_H), .Y(aL_bH)); // Lower 4 bits of a, Higher 4 bits of b
    M8_6 M_3 (.a(a_H), .b(b_L), .Y(aH_bL)); // Higher 4 bits of a, Lower 4 bits of b
    M8_6 M_4 (.a(a_H), .b(b_H), .Y(aH_bH)); // Higher 4 bits of a and b

    // Combine partial products with proper shifting
    assign Y = {aH_bH, 24'b0} + {12'b0, aL_bH, 12'b0} + {12'b0, aH_bL, 12'b0} + {24'b0, aL_bL};

endmodule
