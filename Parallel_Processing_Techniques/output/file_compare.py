def compare_files(file1_path, file2_path):
    try:
        with open(file1_path, 'r') as file1, open(file2_path, 'r') as file2:
            lines1 = file1.readlines()
            lines2 = file2.readlines()
        
        if len(lines1) != len(lines2):
            print(f"Warning: Files have different number of lines. {file1_path}: {len(lines1)}, {file2_path}: {len(lines2)}")
        
        # Compare lines
        matching_count = 0
        different_count = 0
        
        for i, (line1, line2) in enumerate(zip(lines1, lines2), 1):
            try:
                # Convert lines to floats to handle potential floating-point comparisons
                num1 = float(line1.strip())
                num2 = float(line2.strip())
                
                # Compare numbers with some tolerance for floating-point imprecision
                if abs(num1 - num2) < 1e-6:
                    matching_count += 1
                else:
                    different_count += 1
                    print(f"Difference at line {i}: {num1} != {num2}")
            
            except ValueError:
                print(f"Error parsing line {i}: {line1.strip()} or {line2.strip()} is not a valid number")
        
        return matching_count, different_count
    
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return None

file1 = './output_from_multiplier_N8_5.dat'
file2 = 'output_from_multiplier_from_cuda.dat'

result = compare_files(file1, file2)
if result:
    matching, different = result
    print(f"\nSummary:")
    print(f"Matching lines: {matching}")
    print(f"Different lines: {different}")