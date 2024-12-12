module Kul2(
    input [1:0]a,b,
    output [3:0]Y
);
    assign Y[0] = a[0] & b[0];
    assign Y[1] = (a[1] & b[0]) | (a[0] & b[1]);
    assign Y[2] = a[1] & b[1];
    assign Y[3] = 0;
endmodule

module Kul4 (
    input [3:0] a, 
    input [3:0] b, 
    output [7:0] Y
);

    wire [3:0] AL_XL, AH_XL, AL_XH, AH_XH;

    Kul2 m0 (.a(a[1:0]), .b(b[1:0]), .Y(AL_XL));
    Kul2 m1 (.a(a[3:2]), .b(b[1:0]), .Y(AH_XL));
    Kul2 m2 (.a(a[1:0]), .b(b[3:2]), .Y(AL_XH));
    Kul2 m3 (.a(a[3:2]), .b(b[3:2]), .Y(AH_XH));
 
    wire [7:0] padded_AL_XL;
    wire [7:0] padded_AH_XL;
    wire [7:0] padded_AL_XH;
    wire [7:0] padded_AH_XH;

    assign padded_AL_XL = {4'b0, AL_XL};       
    assign padded_AH_XL = {2'b0, AH_XL, 2'b0}; 
    assign padded_AL_XH = {2'b0, AL_XH, 2'b0}; 
    assign padded_AH_XH = {AH_XH, 4'b0};       

    assign Y = padded_AL_XL + padded_AH_XL + padded_AL_XH + padded_AH_XH;

endmodule

module Kul8 (
    input [7:0] a, 
    input [7:0] b, 
    output [15:0] Y
);

    wire [7:0] AL_BL, AH_BL, AL_BH, AH_BH;

    Kul4 m0 (.a(a[3:0]), .b(b[3:0]), .Y(AL_BL));
    Kul4 m1 (.a(a[7:4]), .b(b[3:0]), .Y(AH_BL));
    Kul4 m2 (.a(a[3:0]), .b(b[7:4]), .Y(AL_BH));
    Kul4 m3 (.a(a[7:4]), .b(b[7:4]), .Y(AH_BH));

 
    wire [15:0] padded_AL_BL;
    wire [15:0] padded_AH_BL;
    wire [15:0] padded_AL_BH;
    wire [15:0] padded_AH_BH;

    assign padded_AL_BL = {8'b0, AL_BL};       
    assign padded_AH_BL = {4'b0, AH_BL, 4'b0}; 
    assign padded_AL_BH = {4'b0, AL_BH, 4'b0}; 
    assign padded_AH_BH = {AH_BH, 8'b0};       

    assign Y = padded_AL_BL + padded_AH_BL + padded_AL_BH + padded_AH_BH;

endmodule


module Kul16 (
    input [15:0] a, 
    input [15:0] b, 
    output [31:0] Y
);

    wire [15:0] AL_XL, AH_XL, AL_XH, AH_XH;

    Kul8 lsb_1(.a(a[7:0]), .b(b[7:0]), .Y(AL_XL));
    Kul8 mid_1(.a(a[15:8]), .b(b[7:0]), .Y(AH_XL));
    Kul8 mid_2(.a(a[7:0]), .b(b[15:8]), .Y(AL_XH));
    Kul8 msb_1(.a(a[15:8]), .b(b[15:8]), .Y(AH_XH));

 
    wire [15:0] padded_AL_XL;
    wire [15:0] padded_AH_XL;
    wire [15:0] padded_AL_XH;
    wire [15:0] padded_AH_XH;

    assign padded_AL_XL = {16'b0, AL_XL};       
    assign padded_AH_XL = {8'b0, AH_XL, 8'b0}; 
    assign padded_AL_XH = {8'b0, AL_XH, 8'b0}; 
    assign padded_AH_XH = {AH_XH, 16'b0};       

    assign Y = padded_AL_XL + padded_AH_XL + padded_AL_XH + padded_AH_XH;

endmodule
