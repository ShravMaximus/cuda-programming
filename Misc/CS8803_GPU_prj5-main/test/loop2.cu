__global__ void kernel2(int n, int *x, int *y) {
    int idx = threadIdx.x;

    for (int i = 0; i < n; i++) {
        if (idx < 128) {
            y[idx] = x[idx] + 10;
        }
        else if (idx < 256) {
            y[idx] = x[idx] + 20;
        }
        else {
            y[idx] = x[idx] + 30;
        }
    }
}