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

    wire [3:0] AL_BL, AH_BL, AL_BH, AH_BH;

    Kul2 m0 (.a(a[1:0]), .b(b[1:0]), .Y(AL_BL));
    Kul2 m1 (.a(a[3:2]), .b(b[1:0]), .Y(AH_BL));
    Kul2 m2 (.a(a[1:0]), .b(b[3:2]), .Y(AL_BH));
    Kul2 m3 (.a(a[3:2]), .b(b[3:2]), .Y(AH_BH));

 
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

// Half Adder Module
module HA(
    input a, b,
    output sum, carry
);
    assign sum = a ^ b;   
    assign carry = a & b;  
endmodule



// Full Adder Module
module FA(
    input a, b, cin,
    output sum, carry
);
    wire A_xor_B;

    assign A_xor_B = a ^ b;
    assign sum = A_xor_B ^ cin;   
    assign carry = (a & b) | (A_xor_B & cin);  
endmodule



// 4x4 Multiplier Module
module exact_4x4(
    input [3:0] a, b,   // 4-bit inputs
    output [7:0] Y      // 8-bit product output
);

    // Column - 0
    assign Y[0] = a[0] & b[0];  // product LSB


    // Column - 1
    wire S1_1, C_12_1;


    HA ha_1_1(.a(a[1] & b[0]), .b(a[0] & b[1]), .sum(S1_1), .carry(C_12_1));
    assign Y[1] = S1_1;


    // Column - 2
    wire S2_1, C23_1, S2_2, C23_2;


    FA fa_2_1(.a(a[2] & b[0]), .b(a[1] & b[1]), .cin(a[0] & b[2]), .sum(S2_1), .carry(C23_1));
    HA ha_2_2(.a(S2_1), .b(C_12_1), .sum(S2_2), .carry(C23_2));
    assign Y[2] = S2_2;


    // Column - 3
    wire S3_1, C34_1, S3_2, C34_2;
    FA fa_3_1(.a(a[3] & b[0]), .b(a[2] & b[1]), .cin(a[1] & b[2]), .sum(S3_1), .carry(C34_1));
    FA fa_3_2(.a(S3_1), .b(C23_1), .cin(a[0] & b[3]), .sum(S3_2), .carry(C34_2) );


    // Column - 4
    wire S4_1, C45_1, S4_2, C45_2;
    FA fa_4_1(.a(a[3] & b[1]), .b(a[2] & b[2]), .cin(a[1] & b[3]), .sum(S4_1), .carry(C45_1));
    HA ha_4_2(.a(S4_1), .b(C34_1), .sum(S4_2), .carry(C45_2));
    

    // Column - 5
    wire S5_2, C56_2;
    FA fa_5_2(.a(a[3] & b[2]), .b(a[2] & b[3]), .cin(C45_1), .sum(S5_2), .carry(C56_2));

    // Carry Propogation Adder ( to get Y[3]..Y[7] ) => 4 bit adder ??
    wire carry_3, carry_4, carry_5, carry_6;
    HA cpa_3(.a(S3_2), .b(C23_2), .sum(Y[3]), .carry(carry_3) ) ;
    FA cpa_4(.a(S4_2), .b(C34_2), .cin(carry_3), .sum(Y[4]), .carry(carry_4) ) ;
    FA cpa_5(.a(S5_2), .b(C45_2), .cin(carry_4), .sum(Y[5]), .carry(carry_5) ) ;
    FA cpa_6(.a(a[3] & b[3]), .b(C56_2), .cin(carry_5), .sum(Y[6]), .carry(carry_6) ) ;
    assign Y[7] = carry_6 ;

endmodule



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


module n2_4x4(
    input[3:0] a,b, 
    output [7:0] Y
);

    assign Y[0] = a[0] & b[0];
    assign Y[1] = ( a[1] & b[0] ) | ( a[0] & b[1] );
    assign Y[2] = ( a[2] & b[0] ) | ( a[1] & b[1] ) | ( a[0] & b[2] );
    assign Y[3] = ( a[3] & b[0] ) | ( a[2] & b[1] )| ( a[1] & b[2] ) | ( a[0] & b[3] ) ;
    assign Y[4] = ( a[3] & b[1] ) | ( a[2] & b[2] ) | ( a[1] & b[3]) ;
    assign Y[5] = ( a[3] & b[2] ) | ( a[2] & b[3] ) ;
    assign Y[6] = ( a[3] & b[3] ) & ( ~( a[2] & b[2] ) ) ;
    assign Y[7] = ( a[3] & b[3] ) & ( a[2] & b[2] ) ;

endmodule


module n8_5(
    input [7:0]a,
    input [7:0]b,
    output [15:0]Y
);

    wire [7:0]aL_bL;
    wire [7:0]aH_bL;
    wire [7:0]aL_bH;
    wire [7:0]aH_bH;
    
    // exact_4x4 e0(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    n1_4x4    n1(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    exact_4x4 e1(.a(a[7:4]), .b(b[3:0]), .Y(aH_bL));
    exact_4x4 e2(.a(a[3:0]), .b(b[7:4]), .Y(aL_bH));
    exact_4x4 e3(.a(a[7:4]), .b(b[7:4]), .Y(aH_bH));

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




module n8_6(
    input [7:0]a,
    input [7:0]b,
    output [15:0]Y
);

    wire [7:0]aL_bL;
    wire [7:0]aH_bL;
    wire [7:0]aL_bH;
    wire [7:0]aH_bH;

    // exact_4x4 e0(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    n2_4x4    n2(.a(a[3:0]), .b(b[3:0]), .Y(aL_bL));
    exact_4x4 e1(.a(a[7:4]), .b(b[3:0]), .Y(aH_bL));
    exact_4x4 e2(.a(a[3:0]), .b(b[7:4]), .Y(aL_bH));
    exact_4x4 e3(.a(a[7:4]), .b(b[7:4]), .Y(aH_bH));

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


/*
WHY DOES THIS WORK 
```sh
$ iverlog mulitplier.v # generate a.out
$ vvp a.out            # THIS WORKED
```

THIS DID NOT WORK
```sh
$ iverlog -o out.vvp multipler.v 
$ vvp out.vvp
```

*/


module tb_file_io_multiplier;

    reg [7:0] a, b;          
    wire [15:0] Y; 

    integer input_file, output_file, scan_file;
    integer result;
    
    n8_5 multiplier( .a(a), .b(b), .Y(Y)) ;

    initial begin
        input_file = $fopen("./input_to_multiply.dat", "r");         
        output_file = $fopen("./output_from_multiplier_N8_5.dat", "w"); 

        if (input_file == 0) begin
            $display("Error: Could not open input file. Check if file exists in current directory.");
            $finish;
        end

        if (output_file == 0) begin
            $display("Error: Could not create output file. Check directory permissions.");
            $fclose(input_file);
            $finish;
        end

        $display("Starting processing...");

        while (!$feof(input_file)) begin
            scan_file = $fscanf(input_file, "%d %d", a, b); 

            #1;  

            $display("%d *%d = %4d ; Y=%4d\n",a,b,a*b,Y);
            // Write the result to the output file
            $fwrite(output_file, "%d\n", Y);
        end

        $fclose(input_file);
        $fclose(output_file);

        $finish;
    end
endmodule



// It takes 31 minutes for this to do all the 8 million calculation
module tb_file_io_multipliera__;
    reg [7:0] a, b;          
    wire [15:0] Y; 
    integer input_file, output_file, scan_file;
    integer result, count;
    parameter REPORT_INTERVAL = 10000; // Report every 10k lines
    
    Kul8 multiplier( .a(a), .b(b), .Y(Y));
    
    initial begin
        count = 0;
        input_file = $fopen("input_to_multiply.dat", "r");
        output_file = $fopen("output_from_multiplier.dat", "w");
        
        if (input_file == 0) begin
            $display("Error: Could not open input file. Check if file exists in current directory.");
            $finish;
        end
        if (output_file == 0) begin
            $display("Error: Could not create output file. Check directory permissions.");
            $fclose(input_file);
            $finish;
        end

        $display("Starting processing...");
        
        while (!$feof(input_file)) begin
            scan_file = $fscanf(input_file, "%d %d", a, b);
            if (scan_file == 2) begin  // Only process if we read 2 values successfully
                #1;
                $fwrite(output_file, "%d\n", Y);
                
                count = count + 1;
                if (count % REPORT_INTERVAL == 0) begin
                    $display("Processed %0d lines", count);
                    $fflush(output_file);
                end
            end
        end
        
        $display("Processing complete. Total lines: %0d", count);
        $fclose(input_file);
        $fclose(output_file);
        $finish;
    end
endmodule