module Kul2(
    input [1:0]a,b,
    output [3:0]Y
);

    assign Y[0] = a[0] & b[0];
    assign Y[1] = (a[1] & b[0]) | (a[0] & b[1]);
    assign Y[2] = a[1] & b[1];

endmodule