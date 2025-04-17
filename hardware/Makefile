CXX=g++
# HLSのインクルードパス (hardwareディレクトリからの相対パス)
HLS_INCLUDE_PATH=include
CXXFLAGS=-fPIC -Wall -Wextra
LDFLAGS=-shared
TARGET=build/libadd.so
SRC=add.cc

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	mkdir -p $(dir $(TARGET))
	$(CXX) $(CXXFLAGS) -I$(HLS_INCLUDE_PATH) $(LDFLAGS) -o $(TARGET) $(SRC)

clean:
	rm -rf build