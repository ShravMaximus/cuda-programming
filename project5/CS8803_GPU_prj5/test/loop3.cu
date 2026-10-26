__global__ void kernel3(int n, int *x, int *y) {
    int idx = threadIdx.x;

    for (int i = 0; i < n; i++) {
        if (idx % 3 == 0) {
            if (idx % 2 == 0) {
                y[idx] = x[idx] * 3;
            }
            else {
                y[idx] = x[idx] + 3;
            }
        }
        else {
            y[idx] = x[idx] - 1;
        }
    }
}