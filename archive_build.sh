#!/bin/bash

# 脚本参数：源目录和目标目录
SOURCE_DIR="$1"
TARGET_DIR="$2"

# 检查参数是否提供
if [ -z "$SOURCE_DIR" ] || [ -z "$TARGET_DIR" ]; then
    echo "用法: $0 <源目录> <目标目录>"
    exit 1
fi

# 获取当前Git分支名称和时间戳
BRANCH_NAME=$(git -C "$SOURCE_DIR" rev-parse --abbrev-ref HEAD)
TIMESTAMP=$(date +"%Y%m%d%H%M%S")

# 构造新的目标文件夹路径，包含分支名称
NEW_TARGET_DIR="${TARGET_DIR}/debug_${BRANCH_NAME}_$TIMESTAMP"

# 检查Git仓库状态
if [ $? -ne 0 ]; then
    echo "错误：无法获取Git分支名称或工程目录不是一个Git仓库。"
    exit 1
fi

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误：源目录不存在。"
    exit 1
fi

# 检查并创建目标目录
if [ ! -d "$TARGET_DIR" ]; then
    echo "目标目录不存在，正在创建..."
    mkdir -p "$TARGET_DIR"
    if [ $? -ne 0 ]; then
        echo "错误：创建目标目录失败。"
        exit 1
    fi
fi

# 检查磁盘空间
AVAILABLE_SPACE=$(du -sh "$TARGET_DIR" | cut -f1)
REQUIRED_SPACE=$(du -sh "$SOURCE_DIR" | cut -f1)
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "错误：目标磁盘空间不足。"
    exit 1
fi

# 拷贝文件夹
echo "开始拷贝文件夹..."
cp -R "$SOURCE_DIR/debug/" "$NEW_TARGET_DIR"
if [ $? -eq 0 ]; then
    echo "成功：文件夹已拷贝到 '$NEW_TARGET_DIR'。"
else
    echo "错误：拷贝文件夹失败。"
    exit 1
fi

# 检查拷贝后的文件夹是否为空
if [ -z "$(ls -A "$NEW_TARGET_DIR")" ]; then
    echo "警告：目标文件夹为空。"
fi

# 执行构建脚本
echo "执行构建脚本..."
./rb assembleDebug
if [ $? -ne 0 ]; then
    echo "错误：构建脚本执行失败。"
    exit 1
fi

echo "脚本执行完毕。"