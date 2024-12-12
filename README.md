# Low_power_Approximate_Recursive_Multipliers

## Ideas :-
0. Put all simulations of particular multiplier in their own simulation folder (`ORGANIZATION`)
1. Use matlab to generate uniform random distribution of inputs to feed into n16_5, n16_6, etc 
    You can convert the same multipliers to matlab, and do all the calculations there.
2. It matter WHAT IS THE DISTRIBUTION of inputs 
    => for special cases, there might be some pattern we could exploit ; For general cases => Uniform distribution
3. USE FPGA ( Make a Video demo, GAME CHANGER )


Explain to sir, WHY this paper implementation was hard ( refering to many other papers and implementing their designs )
Why we could not afford to change the paper
But in the spirit of what sir asked ( to incorporate what sir taught in the class :- delay, critical path, analysis from genus we spent time in THAT apart from the paper's requirements too)

A Good example of where SPECIALIZED MULTIPLIERS can be used :-
Just in the gaussian smoothing ( One of the input is always PRE DETERMINED ( 97, 121, 151) this mean we need to find circuits that give better accuracy MORE THIS INPUT )


// WHY 4 billion operation was done in less than 1 second ?

// Why our mini problem statement's perfect solution was GPU

// The fact there was no Dependencies in the computation happening at each iteration of loop,
// Each iteration can be done parallely and independently 

Segmentation faults, Overflow error, type casting errors, were the BIGGEST headaches with CUDA
had to wait 30 minutes for the verilog to give write all the outputs, 
2 ways to do this => Parallelization, the only solution
-> FPGA
-> NVIDIA GPU ( CUDA programming )
we did BOTH ( 4 peoples worked on FPGA, 3 worked on CUDA )

    
In normal verilog, CPU and the entire laptop was heating up, it was taking upwards of 40 minutes 
In GPU it's less than 4 seconds

The reason why SSIM and PSNR are differnet because we don't know which EXACT IMAGE THE PAPER USED.

A VIDEO DEMO OF HOW ( NVIDIA CUDA -> IMAGE SHARPENING WORKFLOW ) ; Or SOME VIDEO DEMO

## 8x8 Design ( 4 Novel Approaches )

Any `2N x 2N` multiplier can be built by placing 4 `NxN` multiplier.

In the n8_5 design inside 8x8 folder, in the line 123 and 122 => `you have the choice to toggle between which mulitplier to use` 

```bash
$ iverlog -o tb.vvp tb.v 
$ vvp tb.vvp
```

1. use exact multiplier and run simulation 
2. use n1 approx mutplier and run the simulation
3. use n1 approx mutplier and run the simulation ( from the n8_6_8x8.v file in the same folder, line number 108, 109 )


## 4x4 Design ( 2 Novel Approaches)
N1 and N2 design