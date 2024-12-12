module mul2b (
    input wire [1:0]a,b,
    output wire [2:0]Y
);

    assign Y[2] = a[1] & b[1];
    assign Y[1] = a[0] & b[0];
    assign Y[0] = a[0] & b[0];
endmodule
