#!/bin/bash

# Tải xuống file zip
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.19.0/protoc-3.19.0-linux-x86_64.zip

# Giải nén file
unzip protoc-3.19.0-linux-x86_64.zip -d protoc-3.19.0

# Di chuyển tệp thực thi vào thư mục bin
sudo mv protoc-3.19.0/bin/protoc /usr/local/bin/

# Di chuyển các tệp include vào thư mục include
sudo mv protoc-3.19.0/include/* /usr/local/include/

# Dọn dẹp các file không cần thiết
rm -rf protoc-3.19.0 protoc-3.19.0-linux-x86_64.zip
