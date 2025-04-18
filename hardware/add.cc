//
// Created by akira on 2025/01/08.
//
#include <hls_stream.h>
#include <ap_int.h>

// HLSカーネル
void add_kernel(hls::stream<int>& stream_in1, hls::stream<int>& stream_in2, hls::stream<int>& stream_out, int size) {
#pragma HLS INTERFACE axis port=stream_in1
#pragma HLS INTERFACE axis port=stream_in2
#pragma HLS INTERFACE axis port=stream_out
#pragma HLS INTERFACE s_axilite port=size bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control

    for (int i = 0; i < size; ++i) {
#pragma HLS PIPELINE II=1
        int val1 = stream_in1.read();
        int val2 = stream_in2.read();
        stream_out.write(val1 + val2);
    }
}

// Pythonから呼び出すためのラッパー関数
extern "C" {
void add_kernel_wrapper(int* in1, int* in2, int* out, int size) {
#pragma HLS INTERFACE m_axi port=in1 offset=slave bundle=gmem0
#pragma HLS INTERFACE m_axi port=in2 offset=slave bundle=gmem1
#pragma HLS INTERFACE m_axi port=out offset=slave bundle=gmem0
#pragma HLS INTERFACE s_axilite port=size bundle=control
#pragma HLS INTERFACE s_axilite port=return bundle=control

    hls::stream<int> s_in1("stream_in1");
    hls::stream<int> s_in2("stream_in2");
    hls::stream<int> s_out("stream_out");
#pragma HLS STREAM variable=s_in1 depth=32
#pragma HLS STREAM variable=s_in2 depth=32
#pragma HLS STREAM variable=s_out depth=32

#pragma HLS DATAFLOW
    // Read data from memory to stream
    for (int i = 0; i < size; ++i) {
#pragma HLS PIPELINE II=1
        s_in1.write(in1[i]);
        s_in2.write(in2[i]);
    }

    // Execute the kernel
    add_kernel(s_in1, s_in2, s_out, size);

    // Write data from stream to memory
    for (int i = 0; i < size; ++i) {
#pragma HLS PIPELINE II=1
        out[i] = s_out.read();
    }
}
} 