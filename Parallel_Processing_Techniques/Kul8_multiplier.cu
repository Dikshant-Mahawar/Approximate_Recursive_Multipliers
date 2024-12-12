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



// Device function for 2-bit multiplication (equivalent to Kul2 module)
__device__ uint8_t Kul2_mult(uint8_t a, uint8_t b) {
    uint8_t Y = 0;
    
    // Y[0] = a[0] & b[0]
    Y |= (a & 1) & (b & 1);
    
    // Y[1] = (a[1] & b[0]) | (a[0] & b[1])
    Y |= ((((a >> 1) & 1) & (b & 1)) | ((a & 1) & ((b >> 1) & 1))) << 1;
    
    // Y[2] = a[1] & b[1]
    Y |= (((a >> 1) & 1) & ((b >> 1) & 1)) << 2;
    
    // Y[3] = 0 (already zero by default)
    
    return Y;
}



// Device function for 4-bit multiplication (equivalent to Kul4 module)
__device__ uint16_t Kul4_mult(uint8_t a, uint8_t b) {

    // Split inputs into 2-bit parts
    uint8_t aL = a & 0b11;                   // Lower 2 bits of a
    uint8_t aH = (a >> 2) & 0b11;            // Upper 2 bits of a
    uint8_t bL = b & 0b11;                   // Lower 2 bits of b
    uint8_t bH = (b >> 2) & 0b11;            // Upper 2 bits of b
    
    // Compute 2x2 multiplications
    uint8_t AL_BL = Kul2_mult(aL, bL);
    uint8_t AH_BL = Kul2_mult(aH, bL);
    uint8_t AL_BH = Kul2_mult(aL, bH);
    uint8_t AH_BH = Kul2_mult(aH, bH);
    
    // Pad and sum results
    uint16_t padded_AL_BL = AL_BL;
    uint16_t padded_AH_BL = AH_BL << 2;
    uint16_t padded_AL_BH = AL_BH << 2;
    uint16_t padded_AH_BH = AH_BH << 4;
    
    return padded_AL_BL + padded_AH_BL + padded_AL_BH + padded_AH_BH;
}

// Device function for 8-bit multiplication (equivalent to Kul8 module)
__device__ uint32_t Kul8_mult(uint8_t a, uint8_t b) {

    // Split inputs into 4-bit parts
    // ANDing with 0b1111 = 0xF (   hexadecimal goes like 1 2 3 4 5 6 7 8 9 A(10) B(11) C(12) D(13) E(14) F(15)   )
    // We set aL to whatever was it's LSB 4 bits ; aH is set to a[7:4]
    uint8_t aL = a & 0xF;                       // Lower 4 bits of a
    uint8_t aH = (a >> 4) & 0xF;                // Upper 4 bits of a
    uint8_t bL = b & 0xF;                       // Lower 4 bits of b
    uint8_t bH = (b >> 4) & 0xF;                // Upper 4 bits of b
    
    // Compute 4x4 multiplications
    uint16_t AL_BL = Kul4_mult(aL, bL);
    uint16_t AH_BL = Kul4_mult(aH, bL);
    uint16_t AL_BH = Kul4_mult(aL, bH);
    uint16_t AH_BH = Kul4_mult(aH, bH);
    
    // Pad and sum results
    uint32_t padded_AL_BL = AL_BL;
    uint32_t padded_AH_BL = (uint32_t)AH_BL << 4;
    uint32_t padded_AL_BH = (uint32_t)AL_BH << 4;
    uint32_t padded_AH_BH = (uint32_t)AH_BH << 8;
    
    return padded_AL_BL + padded_AH_BL + padded_AL_BH + padded_AH_BH;
}


// Kernel function using Kul8 multiplication
__global__ void multiply_kernel(NumberPair* pairs, uint16_t* results, int n) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {

        // Cast to uint16_t to match the original kernel's return type
        results[idx] = static_cast<uint16_t>(Kul8_mult(pairs[idx].a, pairs[idx].b));
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
    std::ofstream outFile("./output/output_from_multiplier_from_cuda_Kul8.dat");
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