`include "Reh16.v"

module tb_multiplier_16x16;

    reg [15:0] A, X;  
    wire [31:0] product;  

    integer i, j;  
    integer correct_results;  

    
    multiplier_16x16 uut (
        .A(A), 
        .X(X), 
        .product(product)
    );

    initial begin
        correct_results = 0;

       
        $display("Testing all possible combinations of 16-bit inputs for A and X:");
        $display("\n\n A           X          | Product (A * X)       | Expected          | Match\n");

        
        for (i = 0; i < 65536; i = i + 1) begin
            for (j = 0; j < 65536; j = j + 1) begin
                A = i;  
                X = j;  

                #10;  

                
                $display("%5d      %5d     |    %10d       |   %10d      | %d", A, X, product, i * j, (product == (i * j)) ? 1 : 0);

                
                correct_results = correct_results + ((product == i * j) ? 1 : 0);
            end
        end

        
        $display("\nTotal tests: %d", 65536 * 65536);
        $display("Correct results: %d", correct_results);
        $display("Accuracy: %f%%", (correct_results * 100.0) / (65536 * 65536));
        $display("Error   : %f%%", 100 - (correct_results * 100.0) / (65536 * 65536));

        $finish;  
    end
endmodule
