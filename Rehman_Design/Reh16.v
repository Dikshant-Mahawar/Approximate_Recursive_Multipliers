module Reh2 (
    input [1:0]a,b,
    output [3:0]Y
);
    assign Y[0] = (a[0] & b[1]) & (a[1] & b[0]) ;        
    assign Y[1] = (a[0] & b[1]) ^ (a[1] & b[0]) ;         
    assign Y[2] =  ((a[0] & b[1]) & (a[1] & b[0]))  ^ (a[1] & b[1]); 
    assign Y[3] =  (a[0] & b[1]) & (a[1] & b[0]) ;
endmodule


module Reh4 (
    input [3:0] a, 
    input [3:0] b, 
    output [7:0] Y
);

    wire [3:0] AL_BL, AH_BL, AL_BH, AH_BH;

    Reh2 m0 (.a(a[1:0]), .b(b[1:0]), .Y(AL_BL));
    Reh2 m1 (.a(a[3:2]), .b(b[1:0]), .Y(AH_BL));
    Reh2 m2 (.a(a[1:0]), .b(b[3:2]), .Y(AL_BH));
    Reh2 m3 (.a(a[3:2]), .b(b[3:2]), .Y(AH_BH));

 
    wire [7:0] padded_AL_BL;
    wire [7:0] padded_AH_BL;
    wire [7:0] padded_AL_BH;
    wire [7:0] padded_AH_BH;

    assign padded_AL_BL = {4'b0, AL_BL};       
    assign padded_AH_BL = {2'b0, AH_BL, 2'b0}; 
    assign padded_AL_BH = {2'b0, AL_BH, 2'b0}; 
    assign padded_AH_BH = {AH_BH, 4'b0};       

    assign Y = padded_AL_BL + padded_AH_BL + padded_AL_BH + padded_AH_BH;

endmodule


module Reh8(
    input [7:0]a,
    input [7:0]b,
    output [15:0]Y
);

    wire [7:0]aL_bL;
    wire [7:0]aH_bL;
    wire [7:0]aL_bH;
    wire [7:0]aH_bH;

    // exact_4x4 e0(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    Reh4 n2(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    Reh4 e1(.a(a[7:4]), .b(b[3:0]), .Y(aH_bL));
    Reh4 e2(.a(a[3:0]), .b(b[7:4]), .Y(aL_bH));
    Reh4 e3(.a(a[7:4]), .b(b[7:4]), .Y(aH_bH));

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



module Reh16(
    input [15:0]a,
    input [15:0]b,
    output [31:0]Y
);

    wire [15:0]aL_bL;
    wire [15:0]aH_bL;
    wire [15:0]aL_bH;
    wire [15:0]aH_bH;

    Reh8 lsb_1(.a(a[7:0]), .b(b[7:0]), .Y(aL_bL));
    Reh8 mid_1(.a(a[15:8]), .b(b[7:0]), .Y(aH_bL));
    Reh8 mid_2(.a(a[7:0]), .b(b[15:8]), .Y(aL_bH));
    Reh8 msb_1(.a(a[15:8]), .b(b[15:8]), .Y(aH_bH));

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