#include <cuda_runtime.h>
#include <iostream>

__device__ uint16_t exact_4x4_mult(uint8_t a, uint8_t b) {
    a &= 0xF;
    b &= 0xF;
    return static_cast<uint16_t>(a) * static_cast<uint16_t>(b);
}

__device__ unsigned char d_n1_4x4_mult(unsigned char a, unsigned char b) {
    a &= 0xF;
    b &= 0xF;
    unsigned char Y = 0;
    Y |= (a & 1) & (b & 1);
    Y |= ((((a >> 1) & 1) & (b & 1)) | ((a & 1) & ((b >> 1) & 1))) << 1;
    Y |= ((((a >> 2) & 1) & (b & 1)) | (((a >> 1) & 1) & ((b >> 1) & 1)) | ((a & 1) & ((b >> 2) & 1))) << 2;
    Y |= ((((a >> 3) & 1) & (b & 1)) | (((a >> 2) & 1) & ((b >> 1) & 1)) | (((a >> 1) & 1) & ((b >> 2) & 1)) | ((a & 1) & ((b >> 3) & 1))) << 3;
    
    unsigned char a3b1 = ((a >> 3) & 1) & ((b >> 1) & 1);
    unsigned char a2b2 = ((a >> 2) & 1) & ((b >> 2) & 1);
    unsigned char a1b3 = ((a >> 1) & 1) & ((b >> 3) & 1);
    unsigned char a3b2 = ((a >> 3) & 1) & ((b >> 2) & 1);
    unsigned char a2b3 = ((a >> 2) & 1) & ((b >> 3) & 1);
    unsigned char a3b3 = ((a >> 3) & 1) & ((b >> 3) & 1);
    
    unsigned char C_45_1_approx = a2b2 & (a1b3 | a3b1);
    unsigned char C_56_2_approx = a2b2 & (a3b3 | a3b1 | a1b3);
    
    Y |= (a3b1 | a2b2 | a1b3) << 4;
    Y |= (a3b2 ^ a2b3 ^ C_45_1_approx) << 5;
    Y |= ((a3b3 & (!a2b2)) | ((!a3b3) & a2b2 & (a3b1 | a1b3))) << 6;
    Y |= (a2b2 & a3b3) << 7;
    
    return Y;
}

__device__ uint16_t n8_5(uint8_t a, uint8_t b) {
    uint8_t aL = a & 0xF;
    uint8_t aH = (a >> 4) & 0xF;
    uint8_t bL = b & 0xF;
    uint8_t bH = (b >> 4) & 0xF;
    
    uint16_t aL_bL = d_n1_4x4_mult(aL, bL);
    uint16_t aH_bL = exact_4x4_mult(aH, bL);
    uint16_t aL_bH = exact_4x4_mult(aL, bH);
    uint16_t aH_bH = exact_4x4_mult(aH, bH);
    
    return aL_bL + (aH_bL << 4) + (aL_bH << 4) + (aH_bH << 8);
}

__device__ uint32_t n16_5(uint16_t a, uint16_t b) {
    uint8_t aL = a & 0xFF;
    uint8_t aH = (a >> 8) & 0xFF;
    uint8_t bL = b & 0xFF;
    uint8_t bH = (b >> 8) & 0xFF;
    
    uint16_t aL_bL = n8_5(aL, bL);
    uint16_t aH_bL = n8_5(aH, bL);
    uint16_t aL_bH = n8_5(aL, bH);
    uint16_t aH_bH = n8_5(aH, bH);
    
    uint32_t padded_aL_bL = aL_bL;
    uint32_t padded_aH_bL = static_cast<uint32_t>(aH_bL) << 8;
    uint32_t padded_aL_bH = static_cast<uint32_t>(aL_bH) << 8;
    uint32_t padded_aH_bH = static_cast<uint32_t>(aH_bH) << 16;
    
    return padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;
}

__global__ void validate_multiplier(unsigned long long *correct_results) {
    unsigned int idx = blockDim.x * blockIdx.x + threadIdx.x;
    unsigned short a = idx >> 16;
    unsigned short b = idx & 0xFFFF;
    unsigned long long expected = (unsigned long long)a * b;
    unsigned long long result = n16_5(a, b);
    if (result == expected) {
        atomicAdd(correct_results, 1ULL);
    }
}

int main() {
    unsigned long long *d_correct_results, correct_results = 0;
    cudaMalloc((void**)&d_correct_results, sizeof(unsigned long long));
    cudaMemcpy(d_correct_results, &correct_results, sizeof(unsigned long long), cudaMemcpyHostToDevice);
    
    int threadsPerBlock = 256;
    unsigned long long numBlocks = (65536ULL * 65536ULL + threadsPerBlock - 1) / threadsPerBlock;
    
    validate_multiplier<<<numBlocks, threadsPerBlock>>>(d_correct_results);
    
    cudaMemcpy(&correct_results, d_correct_results, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    cudaFree(d_correct_results);
    
    unsigned long long total_tests = 65536ULL * 65536ULL;
    unsigned long long wrong_results = total_tests - correct_results;
    double accuracy = (correct_results * 100.0) / total_tests;
    double error = 100.0 - accuracy;
    
    std::cout << "Accuracy: " << accuracy << "%" << std::endl;
    std::cout << "Error: " << error << "%" << std::endl;
    std::cout << "Correct results: " << correct_results << std::endl;
    std::cout << "Wrong results: " << wrong_results << std::endl;
    
    return 0;
}