## Validating 16x16, 32x32 mulitplier

### 16x16 Multplier

```v
        for (i = 0; i < 65_536; i = i + 1) begin
            for (j = 0; j < 65_536; j = j + 1) begin
                a = i;  
                b = j;  
                correct_results = correct_results + ( (Y == i*j ) ? 1 : 0 ); 
            end
        end
```

There are total 4_294_967_296 test cases, 
it'll take more than ONE WEEK to go feed all the possible input combination to this multiplier, by a single threaded CPU job

## NVIDIA CUDA - Power of Massive Parallel Processing

We can essentially achive this in minutes by using NVIDIA CUDA
GPUs can handle **thousands of threads** simultaneously

1. Split Input Space ( in x-y that is the RECTANGULAR AREA between 0 to 65_536 ) 

