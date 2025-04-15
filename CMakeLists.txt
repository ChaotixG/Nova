# Minimum CMake version required
cmake_minimum_required(VERSION 3.10)

# Project definition
project(Nova)

# Set the C++ standard you want to use (for llama.cpp, it's likely C++11 or above)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the llama.cpp directory (ensure this directory contains the correct CMakeLists.txt for llama.cpp)
add_subdirectory(llama.cpp ${CMAKE_BINARY_DIR}/llama)

# Find fmt library (if you're using fmt, make sure it's installed or available)
find_package(fmt REQUIRED)

# The main C++ executable (make sure you point to the correct path to your source file)
add_executable(nova_cpp src/main.cpp)  # Use the correct path for your source file

# Link fmt and llama.cpp libraries to the executable
target_link_libraries(nova_cpp PRIVATE fmt::fmt llama)

# Define any include directories for your project
target_include_directories(nova_cpp PRIVATE ${CMAKE_SOURCE_DIR}/include)

# If using a toolchain like vcpkg, set it up:
# set(CMAKE_TOOLCHAIN_FILE "path/to/vcpkg/scripts/buildsystems/vcpkg.cmake")

# Specify any other dependencies or targets as needed
