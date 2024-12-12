import subprocess
import os



def split_input_file(input_file, batch_size=2_000_000):
    """Split the large input file into smaller batches"""
    batch_files = []
    current_batch = []
    batch_number = 0
    
    print("Reading input file...")

    with open(input_file, 'r') as f:
        for i, line in enumerate(f):
            current_batch.append(line)
            
            if (i + 1) % batch_size == 0:
                batch_file = f'input_batch_{batch_number}.dat'
                with open(batch_file, 'w') as batch_f:
                    batch_f.writelines(current_batch)
                batch_files.append(batch_file)
                current_batch = []
                batch_number += 1
                print(f"Created batch {batch_number} with {batch_size} lines")
    
    # Write any remaining lines
    if current_batch:
        batch_file = f'input_batch_{batch_number}.dat'
        with open(batch_file, 'w') as batch_f:
            batch_f.writelines(current_batch)
        batch_files.append(batch_file)
        print(f"Created final batch {batch_number + 1} with {len(current_batch)} lines")
    
    return batch_files



def process_batch(cuda_executable, input_file):
    """Process a single batch using the CUDA executable"""
    # Create a temporary symlink to match the expected input filename

    os.symlink(input_file, "input_to_multiply.dat")
    
    # Run the CUDA program
    try:
        print(f"Processing {input_file}...")
        result = subprocess.run([f"./{cuda_executable}"], 
                              capture_output=True, 
                              text=True)
        if result.returncode != 0:
            print(f"Error processing {input_file}: {result.stderr}")
            return False
    finally:
        # Clean up the symlink
        os.remove("input_to_multiply.dat")
    
    return True



def combine_output_files(final_output_file, num_batches):
    """Combine all batch outputs into a single file"""
    print("Combining output files...")
    with open(final_output_file, 'w') as outfile:
        for i in range(num_batches):
            # Rename the output file from the CUDA program to preserve it
            batch_output = f"output_batch_{i}.dat"
            os.rename("output_from_multiplier.dat", batch_output)
            
            # Append its contents to the final output file
            with open(batch_output, 'r') as batch_file:
                outfile.writelines(batch_file)
            
            # Clean up the batch output file
            os.remove(batch_output)



def main():
    INPUT_FILE = "input_to_multiply.dat"            # Your original 8M line file
    CUDA_EXECUTABLE = "multiplier"                  # Your CUDA executable name
    FINAL_OUTPUT = "final_output.dat"               # Final combined output file
    BATCH_SIZE = 2_000_000                            # 2 million lines per batch
    
    # Split input file into batches
    batch_files = split_input_file(INPUT_FILE, BATCH_SIZE)
    
    # Process each batch
    all_successful = True
    for i, batch_file in enumerate(batch_files):
        if not process_batch(CUDA_EXECUTABLE, batch_file):
            print(f"Failed processing batch {i}")
            all_successful = False
            break
            
        # Rename the output file to preserve it
        os.rename("output_from_multiplier.dat", f"output_batch_{i}.dat")
        
        # Clean up the input batch file
        os.remove(batch_file)
    
    # If all batches were processed successfully, combine the outputs
    if all_successful:
        combine_output_files(FINAL_OUTPUT, len(batch_files))
        print(f"Processing complete. Results written to {FINAL_OUTPUT}")
    else:
        print("Processing failed. Check the error messages above.")

if __name__ == "__main__":
    main()