#include <stdio.h>
#include <stdlib.h>
#include <ctime>
#include <chrono>
#include <cuda_runtime.h>
#include <algorithm>
// ==== START OF YOUR CODE ====
// Add any additional #include headers or helper macros needed
#include <math.h>
#include <cstring>
#include <limits.h>
const int MAX_CHUNK_SIZE = 1024;
// ==== END OF YOUR CODE ====

// ==== START OF YOUR CODE ====
// Implement your GPU device kernel(s) here (e.g., the bitonic sort kernel).
__global__ void bitonicSortSharedKernel(short* __restrict__ arr, int n) {
    extern __shared__ short shared_arr[];
    //extern __shared__ int shared_aux[];

    unsigned int tid = threadIdx.x;
    unsigned int bid = blockIdx.x;
    unsigned int chunk_size = min(n - bid * MAX_CHUNK_SIZE, MAX_CHUNK_SIZE);

    // global memory to shared memory
    for (int i = tid; i < chunk_size; i += blockDim.x) {
        shared_arr[i] = arr[bid * MAX_CHUNK_SIZE + i];
    }
    __syncthreads();

    //unsigned int k = tid;
    for (int stride = 1; stride < chunk_size; stride *= 2) {
        for (int subStride = stride; subStride > 0; subStride /= 2) {
            __syncthreads();
            int ix = tid;
            if (ix < chunk_size) {
                int ixXor = ix ^ subStride;
                if (ixXor > ix) {
                    bool ascending = ((ix & stride) == 0);
                    if ((shared_arr[ix] > shared_arr[ixXor]) == ascending) {
                        int temp = shared_arr[ix];
                        shared_arr[ix] = shared_arr[ixXor];
                        shared_arr[ixXor] = temp;
                    }
                }
            }
        }
    }
    __syncthreads();

    for (int i = tid; i < chunk_size; i += blockDim.x) {
        arr[bid * MAX_CHUNK_SIZE + i] = shared_arr[i];
    }
}

__global__ void bitonicSortGlobalKernel(short* __restrict__ arr, int n, int j, int i) {
    unsigned int k = threadIdx.x + blockIdx.x * blockDim.x;

    if (k >= n) return;
    unsigned int k_xor_2j = k ^ (1 << j);

    if (k_xor_2j > k) {
        if ((k & (1 << i)) == 0) {
            if (arr[k] > arr[k_xor_2j]) {
                int temp = arr[k];
                arr[k] = arr[k_xor_2j];
                arr[k_xor_2j] = temp;
            }
        } else {
            if (arr[k] < arr[k_xor_2j]) {
                int temp = arr[k];
                arr[k] = arr[k_xor_2j];
                arr[k_xor_2j] = temp;
            }
        }
    }
}


// ==== END OF YOUR CODE ====

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("Usage: %s <array_size>\n", argv[0]);
        return 1;
    }

    int size = atoi(argv[1]);

    srand(time(NULL));

    // ======================================================================
    // arCpu contains the input random array
    // arrSortedGpu should contain the sorted array copied from GPU to CPU
    // ======================================================================
    short* arrCpu = (short*)malloc(size * sizeof(short));


    for (int i = 0; i < size; i++) {
        arrCpu[i] = rand() % 1000;
    }

    float gpuTime, h2dTime, d2hTime, cpuTime = 0;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    // ======================================================================
    // Transfer data (arr_cpu) to device
    // ======================================================================
    // ==== START OF YOUR CODE ====
    int padding_size=pow(2, ceil(log2(size)));
    short* padded_array= (short*)malloc(padding_size*sizeof(short));
    cudaHostRegister(padded_array, padding_size * sizeof(short), cudaHostRegisterDefault);

    memcpy(padded_array, arrCpu, size * sizeof(short));
    std::fill(padded_array + size, padded_array + padding_size, SHRT_MAX);

    short* arr_gpu;
    cudaMallocManaged(&arr_gpu, padding_size * sizeof(short));
    cudaMemcpyAsync(arr_gpu, padded_array, padding_size * sizeof(short), cudaMemcpyHostToDevice, 0);


    short* arrSortedGpu = (short*)malloc(size * sizeof(short));
    cudaHostRegister(arrSortedGpu, size * sizeof(short), cudaHostRegisterDefault);

    // ==== END OF YOUR CODE ====

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&h2dTime, start, stop);

    cudaEventRecord(start);

    // ======================================================================
    // Perform bitonic sort on GPU
    // ======================================================================
    // ==== START OF YOUR CODE ====

    int num_blocks = (padding_size + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE;
    dim3 blockSize(512);
    dim3 gridSize(num_blocks);

    bitonicSortSharedKernel<<<gridSize, blockSize, 2 * MAX_CHUNK_SIZE * sizeof(short)>>>(arr_gpu, padding_size);
    cudaDeviceSynchronize();
    // ==== END OF YOUR CODE ====

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&gpuTime, start, stop);

    cudaEventRecord(start);

    // ======================================================================
    // Transfer sorted data back to host (copied to arr_sorted_gpu)
    // ======================================================================
    // ==== START OF YOUR CODE ====

    dim3 blockSize2(512);
    dim3 gridSize2((padding_size + blockSize2.x - 1) / blockSize2.x);
    int loop_i = log2(padding_size);

    for (int i = 1; i <= loop_i; i++) {
        for (int j = i - 1; j >= 0; j--) {
            bitonicSortGlobalKernel<<<gridSize2, blockSize2>>>(arr_gpu, padding_size, j, i);

        }
    }
    cudaDeviceSynchronize();
    cudaMemcpy(arrSortedGpu, arr_gpu, size * sizeof(short), cudaMemcpyDeviceToHost);

    cudaHostUnregister(arrCpu);
    cudaHostUnregister(padded_array);
    cudaHostUnregister(arrSortedGpu);

    cudaFree(arr_gpu);
    free(padded_array);


    // ==== END OF YOUR CODE ====

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&d2hTime, start, stop);

    auto startTime = std::chrono::high_resolution_clock::now();

    // CPU sort for performance comparison
    std::sort(arrCpu, arrCpu + size);

    auto endTime = std::chrono::high_resolution_clock::now();
    cpuTime = std::chrono::duration_cast<std::chrono::microseconds>(endTime - startTime).count();
    cpuTime = cpuTime / 1000;

    int match = 1;
    for (int i = 0; i < size; i++) {
        if (static_cast<int>(arrSortedGpu[i]) != arrCpu[i]) {
            match = 0;
            break;
        }
    }

    free(arrCpu);
    free(arrSortedGpu);

    if (match)
        printf("\033[1;32mFUNCTIONAL SUCCESS\n\033[0m");
    else {
        printf("\033[1;31mFUNCTIONCAL FAIL\n\033[0m");
        return 0;
    }

    printf("\033[1;34mArray size         :\033[0m %d\n", size);
    printf("\033[1;34mCPU Sort Time (ms) :\033[0m %f\n", cpuTime);
    float gpuTotalTime = h2dTime + gpuTime + d2hTime;
    int speedup = (gpuTotalTime > cpuTime) ? (gpuTotalTime/cpuTime) : (cpuTime/gpuTotalTime);
    float meps = size / (gpuTotalTime * 0.001) / 1e6;
    printf("\033[1;34mGPU Sort Time (ms) :\033[0m %f\n", gpuTotalTime);
    printf("\033[1;34mGPU Sort Speed     :\033[0m %f million elements per second\n", meps);
    if (gpuTotalTime < cpuTime) {
        printf("\033[1;32mPERF PASSING\n\033[0m");
        printf("\033[1;34mGPU Sort is \033[1;32m %dx \033[1;34mfaster than CPU !!!\033[0m\n", speedup);
        printf("\033[1;34mH2D Transfer Time (ms):\033[0m %f\n", h2dTime);
        printf("\033[1;34mKernel Time (ms)      :\033[0m %f\n", gpuTime);
        printf("\033[1;34mD2H Transfer Time (ms):\033[0m %f\n", d2hTime);
    } else {
        printf("\033[1;31mPERF FAILING\n\033[0m");
        printf("\033[1;34mGPU Sort is \033[1;31m%dx \033[1;34mslower than CPU, optimize further!\n", speedup);
        printf("\033[1;34mH2D Transfer Time (ms):\033[0m %f\n", h2dTime);
        printf("\033[1;34mKernel Time (ms)      :\033[0m %f\n", gpuTime);
        printf("\033[1;34mD2H Transfer Time (ms):\033[0m %f\n", d2hTime);
        return 0;
    }

    return 0;
}

