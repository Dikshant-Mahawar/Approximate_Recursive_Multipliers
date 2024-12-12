#include <cuda_runtime.h>
#include <iostream>



// characters are represented by integer values, typically using the ASCII encoding ; so a can take values from [0 to 255]
__device__ unsigned char d_n1_4x4_mult(unsigned char a, unsigned char b) {

    /*
     In binary, 0xF is 1111 (0b1111) = 15 in decimal
    =>    effectively masks out all bits of a except the least significant 4 bits

    Y |= 0/1    => sets the LSB of Y ( or entire Y ) to 0/1 
    
    Isolating Bits:
    -> (a >> 1) & 1     : This expression shifts a one bit to the right and then isolates the least significant bit. This effectively extracts the second bit of a.
    -> (a & 1)          : This expression isolates the least significant bit of a.
    -> (b >> 1) & 1     : This expression shifts b one bit to the right and then isolates the least significant bit, extracting the second bit of b.
    -> (b & 1)          : This expression isolates the least significant bit of b

    Shifting and ORing with Y:
    -> << 1             : This shifts the result of the previous OR operation one bit to the left, positioning it in the second bit position.
    -> Y |= ...         : This performs a bitwise OR assignment, combining the shifted result with the existing value of Y. 
                          This effectively sets the second bit of Y to 1 if either of the two conditions is true:
                          
    -> The second bit of a is 1 and the first bit of b is 1.
    -> The first bit of a is 1 and the second bit of b is 1.
     */



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

__global__ void validate_multiplier(unsigned long long *correct_results) {
    unsigned int idx = blockDim.x * blockIdx.x + threadIdx.x;
    // Get 4-bit values for a and b from the thread index
    unsigned char a = (idx >> 4) & 0xF;  // Changed to 4 bits
    unsigned char b = idx & 0xF;         // Changed to 4 bits
    
    // Get result from our approximate multiplier
    unsigned char result = (a, b);
    
    // Calculate expected result
    unsigned char expected = a * b;
    
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
    
    // Changed the number of threads needed since we're only testing 4-bit numbers
    int threadsPerBlock = 256;
    unsigned long long total_tests = 16ULL * 16ULL;  // 16x16 for 4-bit numbers
    unsigned long long numBlocks = (total_tests + threadsPerBlock - 1) / threadsPerBlock;
    
    // Launch the kernel
    validate_multiplier<<<numBlocks, threadsPerBlock>>>(d_correct_results);
    
    // Copy the result back to the host
    cudaMemcpy(&correct_results, d_correct_results, sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    
    // Clean up GPU memory
    cudaFree(d_correct_results);
    
    // Display the results
    std::cout << "Total tests: " << total_tests << std::endl;
    std::cout << "Correct results: " << correct_results << std::endl;
    std::cout << "Accuracy: " << (correct_results * 100.0) / total_tests << "%" << std::endl;
    std::cout << "Error: " << 100 - (correct_results * 100.0) / total_tests << "%" << std::endl;
    
    return 0;
}