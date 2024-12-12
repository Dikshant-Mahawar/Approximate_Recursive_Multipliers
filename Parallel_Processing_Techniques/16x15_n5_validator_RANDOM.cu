#include <stdio.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include <iomanip>

// Structure to hold validation results
struct ValidationResults {
    unsigned long long total_multiplications;
    unsigned long long exact_matches;
    double mean_error;
    double max_error;
    double accuracy_rate;
};

// Original n8_5 implementation
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
    Y |= ((((a >> 2) & 1) & (b & 1)) | 
          (((a >> 1) & 1) & ((b >> 1) & 1)) | 
          ((a & 1) & ((b >> 2) & 1))) << 2;
    Y |= ((((a >> 3) & 1) & (b & 1)) | 
          (((a >> 2) & 1) & ((b >> 1) & 1)) | 
          (((a >> 1) & 1) & ((b >> 2) & 1)) | 
          ((a & 1) & ((b >> 3) & 1))) << 3;
    
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
    
    uint16_t padded_aL_bL = aL_bL;
    uint16_t padded_aH_bL = aH_bL << 4;
    uint16_t padded_aL_bH = aL_bH << 4;
    uint16_t padded_aH_bH = aH_bH << 8;
    
    return padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;
}

// New n16_5 implementation
__device__ uint32_t n16_5(uint16_t a, uint16_t b) {
    uint8_t aL = a & 0xFF;
    uint8_t aH = (a >> 8) & 0xFF;
    uint8_t bL = b & 0xFF;
    uint8_t bH = (b >> 8) & 0xFF;
    
    uint16_t aL_bL = n8_5(aL, bL);
    uint16_t aH_bL = n8_5(aH, bL);
    uint16_t aL_bH = n8_5(aL, bH);
    uint16_t aH_bH = n8_5(aH, bH);
    
    uint32_t padded_aL_bL = static_cast<uint32_t>(aL_bL);
    uint32_t padded_aH_bL = static_cast<uint32_t>(aH_bL) << 8;
    uint32_t padded_aL_bH = static_cast<uint32_t>(aL_bH) << 8;
    uint32_t padded_aH_bH = static_cast<uint32_t>(aH_bH) << 16;
    
    return padded_aL_bL + padded_aH_bL + padded_aL_bH + padded_aH_bH;
}

__global__ void validate_kernel(uint32_t* results, uint32_t* exact_results, double* errors, uint32_t num_tests) {
    uint32_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < num_tests) {
        uint16_t a = idx & 0xFFFF;
        uint16_t b = (idx >> 16) & 0xFFFF;
        
        // Calculate approximate result
        uint32_t approx_result = n16_5(a, b);
        
        // Calculate exact result
        uint32_t exact_result = static_cast<uint32_t>(a) * static_cast<uint32_t>(b);
        
        results[idx] = approx_result;
        exact_results[idx] = exact_result;
        
        // Calculate error
        if (exact_result > 0) {
            errors[idx] = fabs(static_cast<double>(approx_result - exact_result)) / static_cast<double>(exact_result) * 100.0;
        } else {
            errors[idx] = (approx_result == 0) ? 0.0 : 100.0;
        }
    }
}

#define checkCuda(call) { \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(err)); \
        exit(1); \
    } \
}

ValidationResults validate_n16_5(uint32_t num_tests) {
    uint32_t* d_results;
    uint32_t* d_exact_results;
    double* d_errors;
    
    // Allocate device memory
    checkCuda(cudaMalloc(&d_results, num_tests * sizeof(uint32_t)));
    checkCuda(cudaMalloc(&d_exact_results, num_tests * sizeof(uint32_t)));
    checkCuda(cudaMalloc(&d_errors, num_tests * sizeof(double)));
    
    // Launch kernel
    int blockSize = 256;
    int numBlocks = (num_tests + blockSize - 1) / blockSize;
    validate_kernel<<<numBlocks, blockSize>>>(d_results, d_exact_results, d_errors, num_tests);
    checkCuda(cudaDeviceSynchronize());
    
    // Allocate host memory
    uint32_t* h_results = new uint32_t[num_tests];
    uint32_t* h_exact_results = new uint32_t[num_tests];
    double* h_errors = new double[num_tests];
    
    // Copy results back to host
    checkCuda(cudaMemcpy(h_results, d_results, num_tests * sizeof(uint32_t), cudaMemcpyDeviceToHost));
    checkCuda(cudaMemcpy(h_exact_results, d_exact_results, num_tests * sizeof(uint32_t), cudaMemcpyDeviceToHost));
    checkCuda(cudaMemcpy(h_errors, d_errors, num_tests * sizeof(double), cudaMemcpyDeviceToHost));
    
    // Calculate statistics
    ValidationResults results;
    results.total_multiplications = num_tests;
    results.exact_matches = 0;
    results.mean_error = 0.0;
    results.max_error = 0.0;
    
    for (uint32_t i = 0; i < num_tests; i++) {
        if (h_results[i] == h_exact_results[i]) {
            results.exact_matches++;
        }
        results.mean_error += h_errors[i];
        results.max_error = std::max(results.max_error, h_errors[i]);
    }
    
    results.mean_error /= num_tests;
    results.accuracy_rate = (static_cast<double>(results.exact_matches) / num_tests) * 100.0;
    
    // Cleanup
    delete[] h_results;
    delete[] h_exact_results;
    delete[] h_errors;
    checkCuda(cudaFree(d_results));
    checkCuda(cudaFree(d_exact_results));
    checkCuda(cudaFree(d_errors));
    
    return results;
}

int main() {
    // Test with a subset of possible combinations (as testing all 2^32 combinations would take too long)
    uint32_t num_tests = 1000000; // Testing 1 million random combinations
    
    std::cout << "Starting validation of n16_5 multiplier..." << std::endl;
    ValidationResults results = validate_n16_5(num_tests);
    
    std::cout << "\nValidation Results:" << std::endl;
    std::cout << "Total multiplications: " << results.total_multiplications << std::endl;
    std::cout << "Exact matches: " << results.exact_matches << std::endl;
    std::cout << std::fixed << std::setprecision(4);
    std::cout << "Accuracy rate: " << results.accuracy_rate << "%" << std::endl;
    std::cout << "Mean error: " << results.mean_error << "%" << std::endl;
    std::cout << "Maximum error: " << results.max_error << "%" << std::endl;
    
    return 0;
}