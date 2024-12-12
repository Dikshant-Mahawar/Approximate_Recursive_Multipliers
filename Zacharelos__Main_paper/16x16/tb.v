/*
This is Bad way to find the error rate

There are total 4_294_967_296 test cases, 
it'll take more than ONE WEEK to go feed all the possible input combination to this multiplier

=> WE NEED TO DO PARALLEL PROCESSING

( CAN WE USE Threads, jobs, multi-processing )
( CAN WE USE FPGA ; Hardware Acceleration  )
( Convert this code to PYTHON and use GPU / Threading Library ? )
*/


`include "n16_5.v"

module tb;

    reg [15:0] a, b;
    wire [31:0] Y; 

    integer i, j;  
    integer correct_results; 

    n16_5 uut ( .a(a),  .b(b),  .Y(Y) );

    initial begin
        correct_results = 0;

        // $display("Testing all possible combinations of 4-bit inputs for a and b:");
        // $display("\n\n a   b  | Y(a*b)  | Expected  | Match\n");
        
        // Loop over all possible values of a and b (4-bit numbers: 0 to 15)
        for (i = 0; i < 65_536; i = i + 1) begin
            for (j = 0; j < 65_536; j = j + 1) begin
                a = i;  
                b = j;  

                // VERY IMPORTANT STEP
                // Wait for output to stabilize
                #10;    

                // $display("%2d  %2d  | %3d     | %3d       | %d", a, b, Y, i * j, (Y == (i * j)) ? 1 : 0 );
                // DSA trick, lol !!
                correct_results = correct_results + ( (Y == i*j ) ? 1 : 0 ); 
            end
        end

        $display("\nTotal tests: %d", 4_294_967_296);
        $display("Correct results: %d", correct_results);
        $display("Accuracy: %f%%", (correct_results * 100.0) / 4_294_967_296);
        $display("Error   : %f%%", 100 - (correct_results * 100.0) / 4_294_967_296 );
        
        // SImulation ends here
        $finish;  
    end
endmodule