#include <cuda_runtime.h>
#include <iostream>
#include <cmath>
#include <chrono>

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





// ---------------------------------------------- VALIDATOR CODE -------------------------------------------------------
/*
- Kernel Execution in Batches     : We break down the computation into batches of 10 million inputs for better progress monitoring.
- Progress Output                 : After each batch completes, we calculate and display the completion percentage.
- Completion Synchronization      : Each batch uses cudaDeviceSynchronize() to ensure data is updated before displaying progress
*/

__device__ double atomicAddDouble(double *address, double val) {
    unsigned long long int *address_as_ull = (unsigned long long int *)address;
    unsigned long long int old = *address_as_ull, assumed;

    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed,
                        __double_as_longlong(val + __longlong_as_double(assumed)));
    } while (assumed != old);

    return __longlong_as_double(old);
}



__global__ void validate_multiplier_batch(

            unsigned long long      *correct_results,
            double                  *total_error_distance,
            double                  *total_relative_error,
            double                  *total_squared_error,
            unsigned long long      batch_start,
            unsigned long long      batch_size

    ) 
    
    {

    unsigned long long idx = batch_start + (blockDim.x * blockIdx.x + threadIdx.x);
    if (idx >= 65536ULL * 65536ULL) return;  // Ensure we don't exceed total tests.

    uint16_t a = idx >> 16;
    uint16_t b = idx & 0xFFFF;
    unsigned long long expected = static_cast<unsigned long long>(a) * b;
    unsigned long long result = n16_5(a, b);

    double error_distance = fabs(static_cast<double>(result) - expected);
    double relative_error = (expected != 0) ? error_distance / expected : 0;
    double squared_error = error_distance * error_distance;

    if (result == expected) {
        atomicAdd(correct_results, 1ULL);
    }

    atomicAddDouble(total_error_distance, error_distance);
    atomicAddDouble(total_relative_error, relative_error);
    atomicAddDouble(total_squared_error, squared_error);
}

int main() {
    unsigned long long *d_correct_results, correct_results = 0;
    double *d_total_error_distance, *d_total_relative_error, *d_total_squared_error;
    double total_error_distance = 0.0, total_relative_error = 0.0, total_squared_error = 0.0;

    cudaMalloc((void**)&d_correct_results, sizeof(unsigned long long));
    cudaMalloc((void**)&d_total_error_distance, sizeof(double));
    cudaMalloc((void**)&d_total_relative_error, sizeof(double));
    cudaMalloc((void**)&d_total_squared_error, sizeof(double));

    cudaMemcpy(d_correct_results, &correct_results, sizeof(unsigned long long), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_error_distance, &total_error_distance, sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_relative_error, &total_relative_error, sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_total_squared_error, &total_squared_error, sizeof(double), cudaMemcpyHostToDevice);

    unsigned long long total_tests = 65536ULL * 65536ULL;
    unsigned long long batch_size = 10000000ULL; // 10 million inputs per batch
    unsigned long long num_batches = (total_tests + batch_size - 1) / batch_size;

    int threadsPerBlock = 256;
    unsigned long long blocksPerBatch = (batch_size + threadsPerBlock - 1) / threadsPerBlock;

    for (unsigned long long batch = 0; batch < num_batches; ++batch) {
        unsigned long long batch_start = batch * batch_size;
        
        validate_multiplier_batch<<<blocksPerBatch, threadsPerBlock>>>(
            d_correct_results, d_total_error_distance, d_total_relative_error, d_total_squared_error,
            batch_start, batch_size
        );
        cudaDeviceSynchronize();

        double progress = (static_cast<double>(batch + 1) / num_batches) * 100;
        std::cout << "Progress: " << progress << "% complete" << std::endl;
    }

    // Copy results back to host
    cudaMemcpy(&correct_results, d_correct_results, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_error_distance, d_total_error_distance, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_relative_error, d_total_relative_error, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&total_squared_error, d_total_squared_error, sizeof(double), cudaMemcpyDeviceToHost);

    cudaFree(d_correct_results);
    cudaFree(d_total_error_distance);
    cudaFree(d_total_relative_error);
    cudaFree(d_total_squared_error);

    unsigned long long wrong_results = total_tests - correct_results;

    double accuracy = (correct_results * 100.0) / total_tests;
    double error = 100.0 - accuracy;
    double max_possible_value = (1 << (16 - 1)) * (1 << (16 - 1));
    double nmed = total_error_distance / (total_tests * max_possible_value);
    double mred = total_relative_error / (total_tests - wrong_results); 
    double noeb = (2 * 16) - log2(1 + sqrt(total_squared_error / total_tests));

    std::cout << "=== Performance Metrics ===" << std::endl;
    std::cout << "Total tests: " << total_tests << std::endl;
    std::cout << "Correct results: " << correct_results << std::endl;
    std::cout << "Accuracy: " << accuracy << "%" << std::endl;
    std::cout << "Error rate: " << error << "%" << std::endl;

    std::cout << "\n=== Error Metrics ===" << std::endl;
    std::cout << "Total Error Distance: " << total_error_distance << std::endl;
    std::cout << "Total Relative Error: " << total_relative_error << std::endl;
    std::cout << "NMED (Normalized Mean Error Distance): " << nmed << std::endl;
    std::cout << "MRED (Mean Relative Error Distance): " << mred << std::endl;
    std::cout << "NoEB (Number of Effective Bits): " << noeb << std::endl;

    return 0;
}