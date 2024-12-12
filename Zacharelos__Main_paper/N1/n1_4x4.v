module n1_4x4(
    input[3:0] a,b, 
    output [7:0] Y
);


    assign Y[0] = a[0] & b[0];
    assign Y[1] = ( a[1] & b[0] ) | ( a[0] & b[1] );
    assign Y[2] = ( a[2] & b[0] ) | ( a[1] & b[1] ) | ( a[0] & b[2] );
    assign Y[3] = ( a[3] & b[0] ) | ( a[2] & b[1] )| ( a[1] & b[2] ) | ( a[0] & b[3] ) ;

    // partial product declaration for ease
    wire a3b1 = a[3] & b[1] ; 
    wire a2b2 = a[2] & b[2] ; 
    wire a1b3 = a[1] & b[3] ; 
    wire a3b2 = a[3] & b[2] ; 
    wire a2b3 = a[2] & b[3] ; 
    wire a3b3 = a[3] & b[3] ;

    wire C_45_1_approx = a2b2 & ( a1b3 | a3b1 ) ;
    wire C_56_2_approx = a2b2 & ( a3b3 | a3b1 | a1b3) ;

    assign Y[4] = a3b1 | a2b2 | a1b3 ;
    assign Y[5] = a3b2 ^ (a2b3) ^ (C_45_1_approx) ; // this is supposed to a single XOR gate with 3 inputs 
    assign Y[6] = a3b3 & (~a2b2) | (~a3b3) & (a2b2) & (a3b1 | a1b3) ;
    assign Y[7] = a2b2 & a3b3 ;

endmodule