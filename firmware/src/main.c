#include "test_api.h"

int main() {
    int n = 10;
    int a = 0;
    int b = 1;
    int c = 0;

    if (n == 0) test_done_with_result(a);
    
    for (int i = 2; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    
    // Instantly stops simulation and prints "55"
    test_done_with_result(c); 
    
    return 0; // It will never reach here, but good practice
}