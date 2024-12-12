from numba import cuda
import numpy as np

# (m-digit Number) x ( n-digit Number) => [ m+n-1 , m+n ] digit Number
# in base 10 AND ANY BASE


@cuda.jit
def gpu_multiplier_test(results):
    i, j = cuda.grid(2)  # Get 2D thread indices
    if i < 65_536 and j < 65_536:
        a = i
        b = j
        result = a * b
        expected_result = a * b
        print(f'{i:<5} | {j:<5} | {a*b:<10}  |  {a*b:<10} ')
        results[i, j] = (result == expected_result)

def main():
    # Array to store results
    results = np.zeros((65536, 65536), dtype=np.uint8)

    # Allocate GPU memory and transfer data
    d_results = cuda.to_device(results)

    # Configure the grid/block size (optimal size depends on your GPU)
    threads_per_block = (16, 16)
    blocks_per_grid = (65536 // threads_per_block[0], 65536 // threads_per_block[1])

    # Launch the GPU kernel
    gpu_multiplier_test[blocks_per_grid, threads_per_block](d_results)

    # Copy results back to CPU
    d_results.copy_to_host(results)

    # Calculate accuracy
    total_correct = np.sum(results)
    total_tests = 65536 * 65536
    accuracy = (total_correct * 100.0) / total_tests
    error_rate = 100 - accuracy

    print(f"Total tests: {total_tests}")
    print(f"Correct results: {total_correct}")
    print(f"Accuracy: {accuracy:.6f}%")
    print(f"Error rate: {error_rate:.6f}%")

if __name__ == "__main__":
    main()
