#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>

int main(int argc, char* argv[]) {
    // Usage: ./workload_c [iterations] [bytes_per_block]
    const std::size_t iterations =
        (argc > 1) ? static_cast<std::size_t>(std::strtoull(argv[1], nullptr, 10))
                   : 100000;
    const std::size_t bytes_per_block =
        (argc > 2) ? static_cast<std::size_t>(std::strtoull(argv[2], nullptr, 10))
                   : 1024;

    if (iterations == 0 || bytes_per_block == 0) {
        std::cerr << "iterations and bytes_per_block must be positive integers\n";
        return 1;
    }

    std::uint64_t checksum = 0;
    const auto start = std::chrono::steady_clock::now();

    for (std::size_t iteration = 0; iteration < iterations; ++iteration) {
        std::unique_ptr<unsigned char[]> block(new unsigned char[bytes_per_block]);
        for (std::size_t i = 0; i < bytes_per_block; ++i) {
            block[i] = static_cast<unsigned char>((i + iteration) & 0xFF);
        }
        for (std::size_t i = 0; i < bytes_per_block; ++i) {
            checksum += block[i];
        }
    }

    const auto end = std::chrono::steady_clock::now();
    const auto elapsed_us =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();

    std::cout << "iterations=" << iterations << '\n';
    std::cout << "bytes_per_block=" << bytes_per_block << '\n';
    std::cout << "elapsed_us=" << elapsed_us << '\n';
    std::cout << "checksum=" << checksum << '\n';
    return 0;
}
