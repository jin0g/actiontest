//
// Created by akira on 2025/01/08.
//
#include <assert.h>
#include "add.cpp"

int main() {
    // Test add function
    int a = 1;
    int b = 2;
    int result = add(a, b);
    assert(result == 3);
}