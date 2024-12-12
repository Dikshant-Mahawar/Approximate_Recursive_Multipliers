/*
Total tests     : 256 
Correct results : 91 
Accuracy        : 35.546875%
Error           : 64.453125%
*/

module mul2a (
    input wire [1:0]a, b,
    output wire [2:0]Y
);

    assign Y[2] = a[1] & b[1];
    assign Y[1] = (a[0] & b[1]) | (a[1] & b[0]);
    assign Y[0] = a[1] & b[0];

endmodule

module mul2a4 (
    input wire [3:0] a,  
    input wire [3:0] b,  
    output wire [7:0] Y
);

    wire [2:0] product1, product2, product3, product4;

    mul2a mul1(.a(a[1:0]), .b(b[1:0]), .Y(product1)); 
    mul2a mul2(.a(a[1:0]), .b(b[3:2]), .Y(product2)); 
    mul2a mul3(.a(a[3:2]), .b(b[1:0]), .Y(product3)); 
    mul2a mul4(.a(a[3:2]), .b(b[3:2]), .Y(product4)); 

    assign Y = product1 + (product2 << 2) + (product3 << 2) + (product4 << 4);

endmodule
