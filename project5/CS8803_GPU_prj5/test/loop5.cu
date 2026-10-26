__global__ void kernel5(int n, int *x, int *y) {
    int idx = threadIdx.x;

    for (int j = 0; j < n; j++) {
        for (int i = 0; i < idx; i++) {
            if (idx % 2 == 0) {
                y[idx] = x[idx] * 2;
            } else {
                y[idx] = x[idx] + 1;
            }
        }
    }
}