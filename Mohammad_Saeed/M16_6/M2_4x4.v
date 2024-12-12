
module Compressor_4_2_Table_4(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3;
assign carry = x2 | x4;
endmodule

module Compressor_4_2_Table_5(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3 | x4;
assign carry = (x1 & x2) | (x3 & x4);
endmodule

module Compressor_4_2_Table_6(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x2 | x3;
assign carry = x2 | (x3 & x4);
endmodule

module M2_4x4(
    input [3:0] a,
    input [3:0] b,
    output [7:0] Y
);

    wire pp00 = a[0] & b[0];
    wire pp01 = a[0] & b[1];
    wire pp10 = a[1] & b[0];
    wire pp11 = a[1] & b[1];
    wire pp02 = a[0] & b[2];
    wire pp20 = a[2] & b[0];
    wire pp21 = a[2] & b[1];
    wire pp12 = a[1] & b[2];
    wire pp30 = a[3] & b[0];
    wire pp03 = a[0] & b[3];
    wire pp31 = a[3] & b[1];
    wire pp13 = a[1] & b[3];
    wire pp22 = a[2] & b[2];
    wire pp23 = a[2] & b[3];
    wire pp32 = a[3] & b[2];
    wire pp33 = a[3] & b[3];

    assign Y[0] = pp00;

    wire S_1, C_1;
    half_adder HA1 (.A(pp01), .B(pp10), .S(S_1), .C(C_1));
    assign Y[1] = S_1;

    wire S_2, C_2;
    wire P20 = pp20 | pp02;
    wire G20 = pp20 & pp02;
    Compressor_4_2_Table_4 C1 (.x1(P20), .x2(G20), .x3(pp11), .x4(C_1), .sum(S_2), .carry(C_2));
    assign Y[2] = S_2;

    wire S_3, C_3;
    wire G30 = pp30 & pp03;
    wire G21 = pp21 & pp12;
    wire P21 = pp21 | pp12;
    wire P30 = pp30 | pp03;
    Compressor_4_2_Table_5 C2 (.x1(C_2), .x2(G30 | G21), .x3(P21), .x4(P30), .sum(S_3), .carry(C_3));
    assign Y[3] = S_3;

    wire S_4, C_4;
    wire P31 = pp31 | pp13;
    wire G31 = pp31 & pp13;
    wire P22 = pp22 | pp22;
    Compressor_4_2_Table_6 C3 (.x1(P31), .x2(G31), .x3(pp22), .x4(C_3), .sum(S_4), .carry(C_4));
    assign Y[4] = S_4;

    wire S_5, C_5;
    half_adder HA2 (.A(pp32), .B(pp23), .S(S_5), .C(C_5));
    assign Y[5] = S_5;

    wire S_6, C_6;
    half_adder HA3 (.A(pp33), .B(C_5), .S(S_6), .C(C_6));
    assign Y[6] = S_6;

    assign Y[7] = C_6;

endmodule

