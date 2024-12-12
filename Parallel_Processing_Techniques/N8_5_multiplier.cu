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



__device__ uint16_t exact_4x4_mult(uint8_t a, uint8_t b) {
    // Mask to ensure 4-bit inputs
    a &= 0xF;
    b &= 0xF;
    return static_cast<uint16_t>(a) * static_cast<uint16_t>(b);
}



// characters are represented by integer values, typically using the ASCII encoding ; so a can take values from [0 to 255]
__device__ unsigned char d_n1_4x4_mult(unsigned char a, unsigned char b) {

   // Ensure we only use 4 bits
    a &= 0xF;
    b &= 0xF;
    
    unsigned char Y = 0;
    
    // Y[0] = a[0] & b[0]
    Y |= (a & 1) & (b & 1);
    
    // Y[1] = (a[1] & b[0]) | (a[0] & b[1])
    Y |= ((((a >> 1) & 1) & (b & 1)) | ((a & 1) & ((b >> 1) & 1))) << 1;
    
    // Y[2] = (a[2] & b[0]) | (a[1] & b[1]) | (a[0] & b[2])
    Y |= ((((a >> 2) & 1) & (b & 1)) | 
          (((a >> 1) & 1) & ((b >> 1) & 1)) | 
          ((a & 1) & ((b >> 2) & 1))) << 2;
    
    // Y[3] = (a[3] & b[0]) | (a[2] & b[1]) | (a[1] & b[2]) | (a[0] & b[3])
    Y |= ((((a >> 3) & 1) & (b & 1)) | 
          (((a >> 2) & 1) & ((b >> 1) & 1)) | 
          (((a >> 1) & 1) & ((b >> 2) & 1)) | 
          ((a & 1) & ((b >> 3) & 1))) << 3;
    
    // Partial products
    unsigned char a3b1 = ((a >> 3) & 1) & ((b >> 1) & 1);
    unsigned char a2b2 = ((a >> 2) & 1) & ((b >> 2) & 1);
    unsigned char a1b3 = ((a >> 1) & 1) & ((b >> 3) & 1);
    unsigned char a3b2 = ((a >> 3) & 1) & ((b >> 2) & 1);
    unsigned char a2b3 = ((a >> 2) & 1) & ((b >> 3) & 1);
    unsigned char a3b3 = ((a >> 3) & 1) & ((b >> 3) & 1);
    
    // Approximation logic
    unsigned char C_45_1_approx = a2b2 & (a1b3 | a3b1);
    unsigned char C_56_2_approx = a2b2 & (a3b3 | a3b1 | a1b3);
    
    // Y[4] = a3b1 | a2b2 | a1b3
    Y |= (a3b1 | a2b2 | a1b3) << 4;
    
    // Y[5] = a3b2 ^ a2b3 ^ C_45_1_approx
    Y |= (a3b2 ^ a2b3 ^ C_45_1_approx) << 5;
    
    // Y[6] = a3b3 & (~a2b2) | (~a3b3) & (a2b2) & (a3b1 | a1b3)
    Y |= ((a3b3 & (!a2b2)) | ((!a3b3) & a2b2 & (a3b1 | a1b3))) << 6;
    
    // Y[7] = a2b2 & a3b3
    Y |= (a2b2 & a3b3) << 7;
    
    return Y;

}

__device__ uint16_t n8_5(uint8_t a, uint8_t b) {

    // Extract 4-bit parts
    uint8_t aL = a & 0xF;                       // Lower 4 bits of a
    uint8_t aH = (a >> 4) & 0xF;                // Upper 4 bits of a
    uint8_t bL = b & 0xF;                       // Lower 4 bits of b
    uint8_t bH = (b >> 4) & 0xF;                // Upper 4 bits of b
    
    // Compute the four 4x4 multiplications
    uint16_t aL_bL = d_n1_4x4_mult(aL, bL);    // Using N1 approximate multiplier
    uint16_t aH_bL = exact_4x4_mult(aH, bL);   // Exact multiplication
    uint16_t aL_bH = exact_4x4_mult(aL, bH);   // Exact multiplication
    uint16_t aH_bH = exact_4x4_mult(aH, bH);   // Exact multiplication
    
    // Pad results according to their position
    uint16_t padded_aL_bL = aL_bL;                 // No shift needed
    uint16_t padded_aH_bL = aH_bL << 4;           // Shift left by 4
    uint16_t padded_aL_bH = aL_bH << 4;           // Shift left by 4
    uint16_t padded_aH_bH = aH_bH << 8;           // Shift left by 8
    
    // Sum all partial products
    return padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;
}

__global__ void multiply_kernel(NumberPair* pairs, uint16_t* results, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        results[idx] = n8_5(pairs[idx].a, pairs[idx].b);
    }
}

// Error checking function ; THIS IS A FUCKING MACRO
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
    std::ofstream outFile("output_from_multiplier.dat");
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