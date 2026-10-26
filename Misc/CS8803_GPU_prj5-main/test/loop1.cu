__global__ void test_kernel(int n, float a, float *x, float *y) {
  int idx = threadIdx.x;

  for (int i = 0; i < 2; i ++)
  {
    if (idx %2 == 0)
      y[idx]=x[idx] + 1;
    else
      y[idx]=x[idx];
  }
}

int main() {
  return 0;
} 
