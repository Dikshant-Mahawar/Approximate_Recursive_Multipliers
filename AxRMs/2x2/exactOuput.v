module exactOutput_2cross2 (
    input wire [1:0] a,  
    input wire [1:0] b,  
    output wire [3:0] Y  
);

    wire p0 = a[0] & b[0];
    wire p1 = a[0] & b[1];
    wire p2 = a[1] & b[0];
    wire p3 = a[1] & b[1];

    assign Y[0] = p0;
    assign Y[1] = p1 ^ p2;        
    assign Y[2] = p3 ^ (p1 & p2);   
    assign Y[3] = p3 & (p1 & p2);   

endmodule
