module exactOutput_4cross4 (
    input wire [3:0] a,  
    input wire [3:0] b,  
    output wire [7:0] result  
);

    wire [3:0] product1, product2, product3, product4;

    exactOutput_2cross2 mul1(.a(a[1:0]), .b(b[1:0]), .product(product1)); 
    exactOutput_2cross2 mul2(.a(a[1:0]), .b(b[3:2]), .product(product2)); 
    exactOutput_2cross2 mul3(.a(a[3:2]), .b(b[1:0]), .product(product3)); 
    exactOutput_2cross2 mul4(.a(a[3:2]), .b(b[3:2]), .product(product4)); 

    assign result = product1 + (product2 << 2) + (product3 << 2) + (product4 << 4);

endmodule
