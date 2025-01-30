
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <limits.h>
#define V 32

#ifdef __linux__ // for host pc

    #include <stdio.h>

    void _put_byte(char c) { putchar(c); }

    void _put_str(char *str) {
        while (*str) {
            _put_byte(*str++);
        }
    }

    void print_output(uint8_t num) {
        if (num == 0) {
            putchar('0'); // if the number is 0, directly print '0'
            _put_byte('\n');
            return;
        }

        if (num < 0) {
            putchar('-'); // print the negative sign for negative numbers
            num = -num;   // make the number positive for easier processing
        }

        // convert the integer to a string
        char buffer[20]; // assuming a 32-bit integer, the maximum number of digits is 10 (plus sign and null terminator)
        uint8_t index = 0;

        while (num > 0) {
            buffer[index++] = '0' + num % 10; // convert the last digit to its character representation
            num /= 10;                        // move to the next digit
        }
        // print the characters in reverse order (from right to left)
        while (index > 0) { putchar(buffer[--index]); }
        _put_byte('\n');
    }

    void _put_value(uint8_t val) { print_output(val); }

#else  // for the test device

    void _put_value(uint8_t val) { }
    void _put_str(char *str) { }

#endif


int main(int argc, char const *argv[]) {
    #ifdef __linux__
        const uint8_t START_POINT = atoi(argv[1]);
        const uint8_t END_POINT = atoi(argv[2]);
        uint8_t NODE_POINT = 0;
        uint8_t CPU_DONE = 0;
        uint32_t graph[32];
        uint8_t dist[V], prev[V], path_planned[32], idx = 0;
        uint32_t visited = 0;
    #else
        #define START_POINT     (* (volatile uint8_t *)  0x02000000)
        #define END_POINT       (* (volatile uint8_t *)  0x02000004)
        #define NODE_POINT      (* (volatile uint8_t *)  0x02000008)
        #define CPU_DONE        (* (volatile uint8_t *)  0x0200000c)
        #define graph           ((volatile uint32_t *)   0x02000010)
        #define dist            ((volatile uint8_t *)    0x02000090)
        #define prev            ((volatile uint8_t *)    0x020000b0)
        #define path_planned    ((volatile uint8_t *)    0x020000d0)
        #define idx             (* (volatile uint8_t *)  0x020000f0)
        #define visited         (* (volatile uint32_t *) 0x020000f4)
    #endif

    // Initialize variables
    visited = 0;
    idx = 0;

    //for (int k = 0; k < 32; k++) { path_planned[k] = 0; }
    
    // Initialize graph (your provided initialization code here)
    graph[0] = 0b00000000000000000000010001000010;
    graph[1] = 0b00000000000000000000100000000101;
    graph[2] = 0b00000000000000000000000000111010;
    graph[3] = 0b00000000000000000000000000000100;
    graph[4] = 0b00000000000000000000000000000100;
    graph[5] = 0b00000000000000000000000000000100;
    graph[6] = 0b00000000000000000000001110000001;
    graph[7] = 0b00000000000000000000000001000000;
    graph[8] = 0b00000000000000000000000001000000;
    graph[9] = 0b00000000000000000000000001000000;
    graph[10] = 0b00000101000000000000100000000001;
    graph[11] = 0b00000000000010000001010000000010;
    graph[12] = 0b00000000000000000110100000000000;
    graph[13] = 0b00000000000000000001000000000000;
    graph[14] = 0b00000000000000011001000000000000;
    graph[15] = 0b00000000000000000100000000000000;
    graph[16] = 0b00000000000001100100000000000000;
    graph[17] = 0b00000000000000010000000000000000;
    graph[18] = 0b00000000001010010000000000000000;
    graph[19] = 0b00000000000101000000100000000000;
    graph[20] = 0b00000000000010000000000000000000;
    graph[21] = 0b00000000110001000000000000000000;
    graph[22] = 0b00000000001000000000000000000000;
    graph[23] = 0b01000001001000000000000000000000;
    graph[24] = 0b00000010100000000000010000000000;
    graph[25] = 0b00000001000000000000000000000000;
    graph[26] = 0b00011000000000000000010000000000;
    graph[27] = 0b00000100000000000000000000000000;
    graph[28] = 0b01100100000000000000000000000000;
    graph[29] = 0b00010000000000000000000000000000;
    graph[30] = 0b10010000100000000000000000000000;
    graph[31] = 0b01000000000000000000000000000000;

    // Initialize distances and previous nodes
    for (int i = 0; i < V; i++) {
        dist[i] = UINT8_MAX;
        prev[i] = UINT8_MAX;
    }
    
    // Distance to start point is 0
    dist[START_POINT] = 0;
    
    // Dijkstra's algorithm
    while (visited != 0xFFFFFFFF) {  // While not all nodes are visited
        // Find minimum distance vertex
        uint8_t u = UINT8_MAX;
        uint8_t min_dist = UINT8_MAX;
        
        for (uint8_t v = 0; v < V; v++) {
            if (!(visited & (1U << v)) && dist[v] < min_dist) {
                min_dist = dist[v];
                u = v;
            }
        }
        
        // If we can't find a minimum vertex, break
        if (u == UINT8_MAX) break;
        
        // Mark as visited
        visited |= (1U << u);
        
        // Check neighbors using bit manipulation
        for (uint8_t v = 0; v < V; v++) {
            // Check if edge exists using bit mask
            if (graph[u] & (1U << v)) {
                // Update distance if shorter path found
                if (dist[u] != UINT8_MAX && dist[u] + 1 < dist[v]) {
                    dist[v] = dist[u] + 1;
                    prev[v] = u;
                }
            }
        }
    }
    
    // Reconstruct path from END_POINT to START_POINT
    uint8_t current = END_POINT;
    uint8_t temp_path[32];
    uint8_t temp_idx = 0;
    
    // If no path exists
    if (prev[END_POINT] == UINT8_MAX && END_POINT != START_POINT) {
        CPU_DONE = 1;
        return 0;
    }
    
    // Store path in reverse order
    while (current != UINT8_MAX) {
        temp_path[temp_idx++] = current;
        if (current == START_POINT) break;
        current = prev[current];
    }
    
    // Reverse the path to get correct order (START_POINT to END_POINT)
    for (int i = temp_idx - 1; i >= 0; i--) {
        path_planned[idx++] = temp_path[i];
    }

    // Write path to NODE_POINT
    for (int i = 0; i < idx; ++i) {
        NODE_POINT = path_planned[i];
    }
    
    CPU_DONE = 1;

    #ifdef __linux__
        _put_str("######### Planned Path #########\n");
        for (int i = 0; i < idx; ++i) {
            _put_value(path_planned[i]);
        }
        _put_str("################################\n");
    #endif

    return 0;
}