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