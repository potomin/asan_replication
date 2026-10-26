#include <cstdio>

int main(int argc, char**) {
    int a[1] = {0};
    volatile int value = a[argc];  
    std::printf("%d\n", value);
    return 0;
}
