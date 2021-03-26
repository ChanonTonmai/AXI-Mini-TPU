# AXI-General-Matrix-Multiplication
In this repository, we create the general matrix multiplication base on 4x4 systolic array processing element. Firstly, we need to say that, in the data path section, we use the code from https://github.com/jofrfu/tinyTPU and we design a new control section which can perform NxM matrix multiplication.

## Introduction
This project is aim for create the general matrix multiplication which can specified the matrix size for both input and weight. The matrix multiplication is use in widely area such as machine lerning. So, in FPGA, we can build custom hardware architecture which can parallelize the matrix computation. 

## Architecture 
![Blank diagram (3)](https://user-images.githubusercontent.com/9088660/112641711-35364900-8e75-11eb-856c-a12c20afcdd5.png)
In the architecture section, we separate into two section: data and control path. In the data path, it just only ram for unified input and weight, systolic setup and systolic array. The difficult in this section is how to control it. So, in this, we show that we control all the part in the data path section. 

## Specification 
As the data path we use the code from tinyTPU, so the specification is similar to this tinyTPU but we can perform dynamic NxM matrix multiplication. The size of the matrix is limit but large enough due to we have limit BRAM resorce in FPGA. Therefore, if you have large FPGA, you can do it in larger size. 

## Implementation and testing 
![Capture](https://user-images.githubusercontent.com/9088660/112315137-662f4600-8cdc-11eb-8621-f49908b62a9d.PNG)
We implement this HDL code with AXI interface for setup the data which is fetching the unified input and weight. To receive the result data, we send it to the AXI DMA using AXI-stream interface. Moreover, we test it on zybo board which is 7z010 FPGA borad. The C code is attach in this repository, but to be honest, it is not well organize. 
