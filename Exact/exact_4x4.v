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