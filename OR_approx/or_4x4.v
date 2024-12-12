module or_4x4(
    input[3:0] a,b, 
    output [7:0] Y
);

    assign Y[0] = a[0] & b[0];
    assign Y[1] = ( a[1] & b[0] ) | ( a[0] & b[1] );
    assign Y[2] = ( a[2] & b[0] ) | ( a[1] & b[1] ) | ( a[0] & b[2] );
    assign Y[3] = ( a[3] & b[0] ) | ( a[2] & b[1] )| ( a[1] & b[2] ) | ( a[0] & b[3] ) ;
    assign Y[4] = ( a[3] & b[1] ) | ( a[2] & b[2] ) | ( a[1] & b[3]) ;
    assign Y[5] = ( a[3] & b[2] ) | ( a[2] & b[3] );
    assign Y[6] = a[3] & b[3];

    // Either is fine, 1 is better if inputs are greater than 1000 ; 0 is better if lesser
    assign Y[7] = 1 ;
    // assign Y[7] = 0 ;


endmodule