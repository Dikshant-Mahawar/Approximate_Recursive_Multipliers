module tb_file_io_multiplier;

    reg [15:0] a, b;          
    integer input_file, output_file, scan_file;
    integer result;
    
    initial begin
        input_file = $fopen("./test_input.dat", "r");   
        output_file = $fopen("./test_output.dat", "w"); 

        if (input_file == 0 || output_file == 0) begin
            $display("Error: Could not open input/output file.");
            $finish;
        end

        while (!$feof(input_file)) begin
            scan_file = $fscanf(input_file, "%d %d", a, b); 

            #1;  

            $display("%d *%d = %d\n",a,b,a*b);
            // Write the result to the output file
            $fwrite(output_file, "%d * %d = %d\n", a, b, a*b);
        end

        $fclose(input_file);
        $fclose(output_file);

        $finish;
    end
endmodule