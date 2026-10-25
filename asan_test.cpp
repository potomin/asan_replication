#include <cstdio>

int main(int argc, char**) {
    int a[1] = {0};
    volatile int value = a[argc];  // 不带额外参数时，argc 为 1，越界读取
    std::printf("%d\n", value);
    return 0;
}
