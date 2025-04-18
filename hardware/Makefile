CXX=g++
# HLSのインクルードパス (hardwareディレクトリからの相対パス)
HLS_INCLUDE_PATH=include
CXXFLAGS=-fPIC -Wall -Wextra
LDFLAGS_SO=-shared

SRC_ADD=add.cc
SRC_TEST=test.cc

TARGET_SO=build/libadd.so
TARGET_HW_TEST=build/hw_test

BUILD_DIR=build

.PHONY: all clean hw-test

all: $(TARGET_SO) $(TARGET_HW_TEST)

# C++ 単体テスト用実行ファイル
$(TARGET_HW_TEST): $(SRC_TEST) $(SRC_ADD)
	mkdir -p $(BUILD_DIR)
	$(CXX) $(filter-out -fPIC, $(CXXFLAGS)) -I$(HLS_INCLUDE_PATH) -o $(TARGET_HW_TEST) $(SRC_TEST)

hw-test: $(TARGET_HW_TEST)
	./$(TARGET_HW_TEST)

# Python連携用共有ライブラリ
$(TARGET_SO): $(SRC_ADD)
	mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -I$(HLS_INCLUDE_PATH) $(LDFLAGS_SO) -o $(TARGET_SO) $(SRC_ADD)

clean:
	rm -rf $(BUILD_DIR)