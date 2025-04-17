import ctypes
import numpy as np
import os

# 共有ライブラリのパス (MakefileのTARGETと同じ)
lib_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../hardware/build/libadd.so'))

try:
    # 共有ライブラリをロード
    libadd = ctypes.CDLL(lib_path)
except OSError as e:
    print(f"Error loading shared library: {e}")
    print("Please ensure the library is compiled correctly.")
    exit(1)

# ラッパー関数の引数と戻り値の型を指定
# void add_kernel_wrapper(int* in1, int* in2, int* out, int size)
libadd.add_kernel_wrapper.argtypes = [
    np.ctypeslib.ndpointer(dtype=np.int32, flags="C_CONTIGUOUS"),
    np.ctypeslib.ndpointer(dtype=np.int32, flags="C_CONTIGUOUS"),
    np.ctypeslib.ndpointer(dtype=np.int32, flags="C_CONTIGUOUS"),
    ctypes.c_int
]
libadd.add_kernel_wrapper.restype = None

# テストデータ生成
data_size = 10
in_data1 = np.arange(data_size, dtype=np.int32)
in_data2 = np.arange(data_size, -data_size, -2, dtype=np.int32)
out_data_hw = np.zeros(data_size, dtype=np.int32) # ハードウェア(シミュレーション)の結果用

# 期待値 (ソフトウェアでの計算)
expected_output = in_data1 + in_data2

print(f"Input data 1: {in_data1}")
print(f"Input data 2: {in_data2}")
print(f"Expected output: {expected_output}")

# C++関数呼び出し
libadd.add_kernel_wrapper(in_data1, in_data2, out_data_hw, data_size)

print(f"Hardware output: {out_data_hw}")

# 結果検証
if np.array_equal(out_data_hw, expected_output):
    print("Test PASSED!")
else:
    print("Test FAILED!")
    print(f"Difference: {out_data_hw - expected_output}")
    exit(1) 