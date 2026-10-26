__global__ void kernel4(int n, int *x, int *y) {
    int idx = threadIdx.x;

    for (int i = 0; i < n; i++) {
        if (idx % 2 == 0) {
            y[idx] = x[idx] + 5;
        }
        if (idx % 3 == 0) {
            y[idx] += 10;
        }
        if (idx % 5 == 0) {
            y[idx] *= 2;
        }
    }
}
