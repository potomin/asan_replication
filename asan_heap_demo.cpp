// Author: 陈婉仪 | Student ID: 1240002711
// Design: extension_plan.md in potomin/asan_replication.
// Exactly 16 heap-allocated integers; test indices 0, 15, 16, and 17.

#include <cerrno>
#include <climits>
#include <cstdlib>
#include <iostream>
#include <memory>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <nonnegative-index>\n";
        return 2;
    }

    errno = 0;
    char* end = nullptr;
    const long parsed = std::strtol(argv[1], &end, 10);
    if (errno != 0 || end == argv[1] || *end != '\0' ||
        parsed < 0 || parsed > INT_MAX) {
        std::cerr << "Invalid index: " << argv[1] << "\n";
        return 2;
    }

    constexpr int kArrayLength = 16;
    const int index = static_cast<int>(parsed);

    // Allocate on the heap (not the stack), matching the Week 1 plan.
    std::unique_ptr<int[]> values(new int[kArrayLength]);
    for (int i = 0; i < kArrayLength; ++i) {
        values[i] = 100 + i;
    }

    std::cout << "Array length: " << kArrayLength << '\n';
    std::cout << "Requested index: " << index << '\n' << std::flush;

    // Deliberately do not reject out-of-range indices: the whole point of
    // this controlled test is for ASan to instrument and detect the read.
    volatile const int* const data = values.get();
    const int result = data[index]; // Expected ASan finding for index 16/17.

    std::cout << "Read succeeded; value: " << result << '\n';
    return 0;
}
