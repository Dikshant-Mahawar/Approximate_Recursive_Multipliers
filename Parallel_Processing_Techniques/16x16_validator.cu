#include <cuda_runtime.h>
#include <iostream>

// Lead with answer to these questions in DEMO
// WHY 4 billion operation was done in less than 1 second ?
// Why our mini problem statement's perfect solution was GPU ?

// The fact there was no Dependencies in the computation happening at each iteration of loop,
// Each iteration can be done  independently and parallely 


__global__ void validate_multiplier(unsigned long long *correct_results) {
    unsigned int idx = blockDim.x * blockIdx.x + threadIdx.x;

    // Get 16-bit values for a and b from the thread index
    unsigned short a = idx >> 16; // upper 16 bits for 'a'
    unsigned short b = idx & 0xFFFF; // lower 16 bits for 'b'

    unsigned long long expected = (unsigned long long)a * b;
    unsigned long long result = (unsigned long long)a * b; // Assume multiplier is correct

    // Update correct result count in parallel using atomic addition
    if (result == expected) {
        atomicAdd(correct_results, 1);
    }
}

int main() {
    unsigned long long *d_correct_results, correct_results = 0;
    
    // Allocate memory on the GPU
    cudaMalloc((void**)&d_correct_results, sizeof(unsigned long long));
    cudaMemcpy(d_correct_results, &correct_results, sizeof(unsigned long long), cudaMemcpyHostToDevice);

    int threadsPerBlock = 256;
    unsigned long long numBlocks = (65536ULL * 65536ULL + threadsPerBlock - 1) / threadsPerBlock;

    // Launch the kernel to validate all possible combinations
    validate_multiplier<<<numBlocks, threadsPerBlock>>>(d_correct_results);

    // Copy the result back to the host
    cudaMemcpy(&correct_results, d_correct_results, sizeof(unsigned long long), cudaMemcpyDeviceToHost);

    // Clean up GPU memory
    cudaFree(d_correct_results);

    // Display the results
    unsigned long long total_tests = 65536ULL * 65536ULL;
    std::cout << "Total tests: " << total_tests << std::endl;
    std::cout << "Correct results: " << correct_results << std::endl;
    std::cout << "Accuracy: " << (correct_results * 100.0) / total_tests << "%" << std::endl;
    std::cout << "Error: " << 100 - (correct_results * 100.0) / total_tests << "%" << std::endl;

    return 0;
}