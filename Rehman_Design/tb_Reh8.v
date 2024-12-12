`include "Reh8.v" // Works PERFECTLY just as given in the paper

module tb;

    reg [7:0] a, b;
    wire [15:0] Y; 

    integer i, j;  
    integer correct_results; 

    Reh8 uut( .a(a), .b(b), .Y(Y));

    initial begin
        correct_results = 0;

        $display("Testing all possible combinations of 4-bit inputs for a and b:");
        $display("\n\n a   b  | Y(a*b)  | Expected  | Match\n");
        
        // Loop over all possible values of a and b (4-bit numbers: 0 to 15)
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;  
                b = j;  

                // VERY IMPORTANT STEP
                // Wait for output to stabilize
                #10;    

                $display("%2d  %2d  | %3d     | %3d       | %d", a, b, Y, i * j, (Y == (i * j)) ? 1 : 0 );
                // DSA trick, lol !!
                correct_results = correct_results + ( (Y == i*j ) ? 1 : 0 ); 
            end
        end

        $display("\nTotal tests: %d", 65536);
        $display("Correct results: %d", correct_results);
        $display("Accuracy: %f%%", (correct_results * 100.0) / 65536);
        $display("Error   : %f%%", 100 - (correct_results * 100.0) / 65536);
        
        // SImulation ends here
        $finish;  
    end
endmodule