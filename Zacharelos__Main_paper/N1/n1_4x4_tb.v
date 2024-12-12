`include "n1_4x4.v"

/* EVERYTHING WORKED !!
Total tests:         256
Correct results:     164
Accuracy: 64.062500%
*/

module tb_mult_4x4;

    reg [3:0] a, b;      
    wire [7:0] Y;        
    integer i, j;        

    integer N = 4;

    integer correct_results;        // Counter for correct matches
    integer total_tests;           // Total number of test cases
    integer N_sq; 

    // For NMED calculation, MRED calculation,  NoEB calculation
    real exact_result, error_distance, total_error_distance;             
    real max_possible_value, total_relative_error, total_squared_error;       
    real relative_error, squared_error;
    real nmed, mred, noeb;        
    
    // Instantiate the 4x4 multiplier
    n1_4x4 uut (
        .a(a), 
        .b(b), 
        .Y(Y)
    );
    
    initial begin
        // Initialize variables
        N_sq = N * N;

        correct_results = 0;
        error_distance = 0;
        exact_result = 0;  
        relative_error = 0;   
        total_error_distance = 0;
        total_relative_error = 0;
        total_squared_error = 0;
        squared_error = 0;
        total_tests = N_sq*N_sq;  // 16 * 16 combinations
        
        // Calculate maximum possible value for NMED: (2^(n-1))^2, where n=4
        max_possible_value = (1 << (N-1)) * (1 << (4-1));  // 8^2 = 64
        

        $display("Testing all possible combinations of 4-bit inputs for a and b:");
        $display("\n\n a   b  | Y(a*b)  | Expected  | Match | Error Distance | Relative Error (x 10^-2)\n");
        
        // Loop over all possible values of a and b (4-bit numbers: 0 to 15)
        for (i = 0; i < N_sq; i = i + 1) begin
            for (j = 0; j < N_sq; j = j + 1) begin
                a = i;  
                b = j;  


                // Wait for output to stabilize
                #10;    
                
                // Calculate error metrics for each test case
                 exact_result = i * j;
                 error_distance = abs(exact_result - Y);
                 relative_error = (exact_result != 0) ? (error_distance / exact_result) : 0; // Tricky CASE
                 squared_error = error_distance * error_distance;
                
                // Accumulate errors
                total_error_distance = total_error_distance + error_distance;
                total_relative_error = total_relative_error + relative_error;
                total_squared_error = total_squared_error + squared_error;
                
                // Formatted display with fixed column widths
                $display("%2d %2d |   %3d    |    %3d   |   %1d   |     %6.3f      |     %6.3f", 
                        a, b, Y, i * j, (Y == (i * j)) ? 1 : 0, error_distance, relative_error*100);
                
                correct_results = correct_results + ((Y == i*j) ? 1 : 0);
            end
        end
        
        // Calculate final error metrics
        nmed = total_error_distance / (total_tests * max_possible_value);
        mred = total_relative_error / total_tests;

        noeb = (2*N) - $ln(1 + $sqrt(total_squared_error/total_tests)) / $ln(2);  // 8 = 2*N where N=4
        
        // Display results
        $display("\n=== Performance Metrics ===");
        $display("Total tests: %d", total_tests);
        $display("Correct results: %d", correct_results);
        $display("Accuracy: %f%%\n\n\n", (correct_results * 100.0) / total_tests);
        
        // Display new error metrics
        $display("\n=== Error Metrics ===");    
        $display("Total Error Distance : %f", total_error_distance);
        $display("Total Relative error : %f", total_relative_error);
        $display("Error rate: %f%%", 100 - (correct_results * 100.0) / total_tests);
        $display("NMED (Normalized Mean Error Distance): %f", nmed);
        $display("MRED (Mean Relative Error Distance): %f", mred);
        $display("NoEB (Number of Effective Bits): %f\n\n\n", noeb);
        
        $finish;
    end
    
    // Helper function to calculate absolute value
    function real abs;
        input real value;
        begin
            abs = (value < 0) ? -value : value;
        end
    endfunction
    
endmodule