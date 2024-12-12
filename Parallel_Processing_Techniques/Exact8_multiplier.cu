#include <cstdint>
#include <stdio.h>
#include <cuda_runtime.h>
#include <fstream>
#include <vector>
#include <iostream>

// Structure to store input pairs
struct NumberPair {
    uint8_t a;
    uint8_t b;
};

// Kernel function using standard multiplication
__global__ void multiply_kernel(NumberPair* pairs, uint16_t* results, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        // Direct multiplication, casting to uint16_t to prevent overflow
        results[idx] = static_cast<uint16_t>(pairs[idx].a * pairs[idx].b);
    }
}

// Error checking macro
#define checkCuda(call) { \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        fprintf(stderr, "CUDA error in file '%s' in line %i : %s.\n", \
            __FILE__, __LINE__, cudaGetErrorString(err)); \
        exit(1); \
    } \
}

int main() {
    // Open input file
    std::ifstream inFile("input_to_multiply.dat");
    if (!inFile) {
        std::cerr << "Error: Could not open input file." << std::endl;
        return 1;
    }

    // Read all input pairs
    std::vector<NumberPair> pairs;
    int num1, num2;
    while (inFile >> num1 >> num2) {
        if (num1 >= 0 && num1 <= 255 && num2 >= 0 && num2 <= 255) {
            NumberPair pair = {static_cast<uint8_t>(num1), static_cast<uint8_t>(num2)};
            pairs.push_back(pair);
        }
    }
    inFile.close();

    int n = pairs.size();
    if (n == 0) {
        std::cerr << "No valid input pairs found in file." << std::endl;
        return 1;
    }

    // Allocate host and device memory
    NumberPair* d_pairs;
    uint16_t* d_results;
    uint16_t* h_results = new uint16_t[n];

    checkCuda(cudaMalloc(&d_pairs, n * sizeof(NumberPair)));
    checkCuda(cudaMalloc(&d_results, n * sizeof(uint16_t)));

    // Copy input data to device
    checkCuda(cudaMemcpy(d_pairs, pairs.data(), n * sizeof(NumberPair), cudaMemcpyHostToDevice));

    // Calculate grid and block dimensions
    int blockSize = 256;
    int numBlocks = (n + blockSize - 1) / blockSize;

    // Launch kernel
    multiply_kernel<<<numBlocks, blockSize>>>(d_pairs, d_results, n);
    checkCuda(cudaGetLastError());
    checkCuda(cudaDeviceSynchronize());

    // Copy results back to host
    checkCuda(cudaMemcpy(h_results, d_results, n * sizeof(uint16_t), cudaMemcpyDeviceToHost));

    // Write results to output file
    std::ofstream outFile("./output/output_from_multiplier_from_cuda_EXACT.dat");
    if (!outFile) {
        std::cerr << "Error: Could not create output file." << std::endl;
        return 1;
    }

    for (int i = 0; i < n; i++) {
        outFile << static_cast<int>(h_results[i]) << "\n";
        if (i > 0 && i % 10000 == 0) {
            std::cout << "Processed " << i << " lines" << std::endl;
            outFile.flush();
        }
    }

    std::cout << "Processing complete. Total lines: " << n << std::endl;
    outFile.close();

    // Cleanup
    delete[] h_results;
    checkCuda(cudaFree(d_pairs));
    checkCuda(cudaFree(d_results));

    return 0;
}