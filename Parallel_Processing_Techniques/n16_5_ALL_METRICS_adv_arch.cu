#include <cuda_runtime.h>
#include <iostream>
#include <cmath>

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


/*

CUDA does not natively support atomic operations on double in all architectures

*/


__global__ void validate_multiplier(unsigned long long *correct_results, double *total_error_distance, 
                                    double *total_relative_error, double *total_squared_error,
                                    unsigned long long *total_tests_mred, double max_value) {
    unsigned int idx = blockDim.x * blockIdx.x + threadIdx.x;
    unsigned short a = idx >> 16;
    unsigned short b = idx & 0xFFFF;

    unsigned long long expected = (unsigned long long)a * b;
    unsigned long long result = n16_5(a, b);

    double error_distance = fabs(result - expected);
    double relative_error = (expected != 0) ? (error_distance / expected) : 0;
    double squared_error = error_distance * error_distance;

    // Atomic operations to accumulate metrics across threads
    atomicAdd(correct_results, (result == expected) ? 1ULL : 0ULL);
    atomicAdd(total_error_distance, error_distance);
    atomicAdd(total_relative_error, relative_error);
    atomicAdd(total_squared_error, squared_error);
    if (expected != 0) atomicAdd(total_tests_mred, 1ULL);  // Only count non-zero expected values for MRED
}

int main() {
    const unsigned long long total_tests = 65536ULL * 65536ULL;
    const double max_value = 65535 * 65535;

    // Allocate memory for metric accumulators on the device
    unsigned long long *d_correct_results, correct_results = 0;
    double *d_total_error_distance, total_error_distance = 0;
    double *d_total_relative_error, total_relative_error = 0;
    double *d_total_squared_error, total_squared_error = 0;
    unsigned long long *d_total_tests_mred, total_tests_mred = 0;

    cudaMalloc((void**)&d_correct_results, sizeof(unsigned long long));
    cudaMalloc((void**)&d_total_error_distance, sizeof(double));
    cudaMalloc((void**)&d_total_relative_error, sizeof(double));
    cudaMalloc((void**)&d_total_squared_error, sizeof(double));
    cudaMalloc((void**)&d_total_tests_mred, sizeof(unsigned long long));

    // Initialize device memory to zero
    cudaMemcpy(d_correct_results, &correct_results, sizeof(unsigned long long), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_error_distance, &total_error_distance, sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_relative_error, &total_relative_error, sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_squared_error, &total_squared_error, sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_tests_mred, &total_tests_mred, sizeof(unsigned long long), cudaMemcpyHostToDevice);

    int threadsPerBlock = 256;
    unsigned long long numBlocks = (total_tests + threadsPerBlock - 1) / threadsPerBlock;

    // Launch kernel
    validate_multiplier<<<numBlocks, threadsPerBlock>>>(d_correct_results, d_total_error_distance, 
                                                        d_total_relative_error, d_total_squared_error,
                                                        d_total_tests_mred, max_value);

    // Copy results back to host
    cudaMemcpy(&correct_results, d_correct_results, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_error_distance, d_total_error_distance, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_relative_error, d_total_relative_error, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_squared_error, d_total_squared_error, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_tests_mred, d_total_tests_mred, sizeof(unsigned long long), cudaMemcpyDeviceToHost);

    // Free device memory
    cudaFree(d_correct_results);
    cudaFree(d_total_error_distance);
    cudaFree(d_total_relative_error);
    cudaFree(d_total_squared_error);
    cudaFree(d_total_tests_mred);

    // Compute final metrics
    double accuracy = (correct_results * 100.0) / total_tests;
    double error_rate = 100.0 - accuracy;
    double nmed = total_error_distance / (total_tests * max_value);
    double mred = total_relative_error / total_tests_mred;
    double noeb = (2 * 8) - log2(1.0 + sqrt(total_squared_error / total_tests));

    // Display results
    std::cout << "=== Performance Metrics ===\n";
    std::cout << "Total tests: " << total_tests << "\n";
    std::cout << "Correct results: " << correct_results << "\n";
    std::cout << "Accuracy: " << accuracy << "%\n";
    std::cout << "Error rate: " << error_rate << "%\n\n";

    std::cout << "=== Error Metrics ===\n";
    std::cout << "Total Error Distance: " << total_error_distance << "\n";
    std::cout << "Total Relative Error: " << total_relative_error << "\n";
    std::cout << "NMED (Normalized Mean Error Distance): " << nmed << "\n";
    std::cout << "MRED (Mean Relative Error Distance): " << mred << "\n";
    std::cout << "NoEB (Number of Effective Bits): " << noeb << "\n";

    return 0;
}
