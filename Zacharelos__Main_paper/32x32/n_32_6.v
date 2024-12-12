// Half Adder Module
module HA(
    input a, b,
    output sum, carry
);
    assign sum = a ^ b;   
    assign carry = a & b;  
endmodule



// Full Adder Module
module FA(
    input a, b, cin,
    output sum, carry
);
    wire A_xor_B;

    assign A_xor_B = a ^ b;
    assign sum = A_xor_B ^ cin;   
    assign carry = (a & b) | (A_xor_B & cin);  
endmodule



// 4x4 Multiplier Module
module exact_4x4(
    input [3:0] a, b,   // 4-bit inputs
    output [7:0] Y      // 8-bit product output
);

    // Column - 0
    assign Y[0] = a[0] & b[0];  // product LSB


    // Column - 1
    wire S1_1, C_12_1;


    HA ha_1_1(.a(a[1] & b[0]), .b(a[0] & b[1]), .sum(S1_1), .carry(C_12_1));
    assign Y[1] = S1_1;


    // Column - 2
    wire S2_1, C23_1, S2_2, C23_2;


    FA fa_2_1(.a(a[2] & b[0]), .b(a[1] & b[1]), .cin(a[0] & b[2]), .sum(S2_1), .carry(C23_1));
    HA ha_2_2(.a(S2_1), .b(C_12_1), .sum(S2_2), .carry(C23_2));
    assign Y[2] = S2_2;


    // Column - 3
    wire S3_1, C34_1, S3_2, C34_2;
    FA fa_3_1(.a(a[3] & b[0]), .b(a[2] & b[1]), .cin(a[1] & b[2]), .sum(S3_1), .carry(C34_1));
    FA fa_3_2(.a(S3_1), .b(C23_1), .cin(a[0] & b[3]), .sum(S3_2), .carry(C34_2) );


    // Column - 4
    wire S4_1, C45_1, S4_2, C45_2;
    FA fa_4_1(.a(a[3] & b[1]), .b(a[2] & b[2]), .cin(a[1] & b[3]), .sum(S4_1), .carry(C45_1));
    HA ha_4_2(.a(S4_1), .b(C34_1), .sum(S4_2), .carry(C45_2));
    

    // Column - 5
    wire S5_2, C56_2;
    FA fa_5_2(.a(a[3] & b[2]), .b(a[2] & b[3]), .cin(C45_1), .sum(S5_2), .carry(C56_2));

    // Carry Propogation Adder ( to get Y[3]..Y[7] ) => 4 bit adder ??
    wire carry_3, carry_4, carry_5, carry_6;
    HA cpa_3(.a(S3_2), .b(C23_2), .sum(Y[3]), .carry(carry_3) ) ;
    FA cpa_4(.a(S4_2), .b(C34_2), .cin(carry_3), .sum(Y[4]), .carry(carry_4) ) ;
    FA cpa_5(.a(S5_2), .b(C45_2), .cin(carry_4), .sum(Y[5]), .carry(carry_5) ) ;
    FA cpa_6(.a(a[3] & b[3]), .b(C56_2), .cin(carry_5), .sum(Y[6]), .carry(carry_6) ) ;
    assign Y[7] = carry_6 ;

endmodule



module n2_4x4(
    input[3:0] a,b, 
    output [7:0] Y
);

    assign Y[0] = a[0] & b[0];
    assign Y[1] = ( a[1] & b[0] ) | ( a[0] & b[1] );
    assign Y[2] = ( a[2] & b[0] ) | ( a[1] & b[1] ) | ( a[0] & b[2] );
    assign Y[3] = ( a[3] & b[0] ) | ( a[2] & b[1] )| ( a[1] & b[2] ) | ( a[0] & b[3] ) ;
    assign Y[4] = ( a[3] & b[1] ) | ( a[2] & b[2] ) | ( a[1] & b[3]) ;
    assign Y[5] = ( a[3] & b[2] ) | ( a[2] & b[3] ) ;
    assign Y[6] = ( a[3] & b[3] ) & ( ~( a[2] & b[2] ) ) ;
    assign Y[7] = ( a[3] & b[3] ) & ( a[2] & b[2] ) ;

endmodule


module n8_6(
    input [7:0]a,
    input [7:0]b,
    output [15:0]Y
);

    wire [7:0]aL_bL;
    wire [7:0]aH_bL;
    wire [7:0]aL_bH;
    wire [7:0]aH_bH;

    // exact_4x4 e0(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    n2_4x4    n2(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    exact_4x4 e1(.a(a[7:4]), .b(b[3:0]), .Y(aH_bL));
    exact_4x4 e2(.a(a[3:0]), .b(b[7:4]), .Y(aL_bH));
    exact_4x4 e3(.a(a[7:4]), .b(b[7:4]), .Y(aH_bH));

    // Adding the partial products
    wire [15:0]padded_aL_bL;
    wire [15:0]padded_aH_bL;
    wire [15:0]padded_aL_bH;
    wire [15:0]padded_aH_bH;


    //  padding them according to the pattern mentioned in Figure - 7 
    assign padded_aL_bL = {8'b0, aL_bL};       // [7:0] padded at the LSB
    assign padded_aH_bL = {4'b0, aH_bL, 4'b0}; // [7:0] padded at [11:4]
    assign padded_aL_bH = {4'b0, aL_bH, 4'b0}; // [7:0] padded at [11:4]
    assign padded_aH_bH = {aH_bH, 8'b0};       // [7:0] padded at the MSB

    assign Y = padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;


endmodule




module n16_6(
    input [15:0]a,
    input [15:0]b,
    output [31:0]Y
);

    wire [15:0]aL_bL;
    wire [15:0]aH_bL;
    wire [15:0]aL_bH;
    wire [15:0]aH_bH;

    // exact_4x4 e0(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    n8_6 lsb_1(.a(a[7:0]), .b(b[7:0]), .Y(aL_bL));
    n8_6 mid_1(.a(a[15:8]), .b(b[7:0]), .Y(aH_bL));
    n8_6 mid_2(.a(a[7:0]), .b(b[15:8]), .Y(aL_bH));
    n8_6 msb_1(.a(a[15:8]), .b(b[15:8]), .Y(aH_bH));

    // Adding the partial products
    wire [31:0]padded_aL_bL;
    wire [31:0]padded_aH_bL;
    wire [31:0]padded_aL_bH;
    wire [31:0]padded_aH_bH;

    //  padding them according to the pattern mentioned in Figure - 7 
    assign padded_aL_bL = {16'b0, aL_bL};       
    assign padded_aH_bL = {8'b0, aH_bL, 8'b0};
    assign padded_aL_bH = {8'b0, aL_bH, 8'b0};
    assign padded_aH_bH = {aH_bH, 16'b0};     

    assign Y = padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;

endmodule



module n32_5(
    input [31:0]a,
    input [31:0]b,
    output [63:0]Y
);

    wire [31:0]aL_bL;
    wire [31:0]aH_bL;
    wire [31:0]aL_bH;
    wire [31:0]aH_bH;

    n16_6 lsb_1(.a(a[15:0]), .b(b[15:0]), .Y(aL_bL));
    n16_6 mid_1(.a(a[31:16]), .b(b[15:0]), .Y(aH_bL));
    n16_6 mid_2(.a(a[15:0]), .b(b[31:16]), .Y(aL_bH));
    n16_6 msb_1(.a(a[31:16]), .b(b[31:16]), .Y(aH_bH));

    wire [63:0]padded_aL_bL;
    wire [63:0]padded_aH_bL;
    wire [63:0]padded_aL_bH;
    wire [63:0]padded_aH_bH;

    assign padded_aL_bL = {32'b0, aL_bL};       
    assign padded_aH_bL = {16'b0, aH_bL, 16'b0};
    assign padded_aL_bH = {16'b0, aL_bH, 16'b0};
    assign padded_aH_bH = {aH_bH, 32'b0};     

    assign Y = padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;

endmodule