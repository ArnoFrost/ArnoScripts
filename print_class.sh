#!/bin/bash

# 检查参数数量
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# 目标目录
TARGET_DIR=$1

# 输出文件名
OUTPUT_FILE="$TARGET_DIR/classes_compiled.txt"

# 清空输出文件或创建新文件
> "$OUTPUT_FILE"

# 遍历目标目录下的所有.java和.kt文件
find "$TARGET_DIR" -type f \( -name "*.java" -o -name "*.kt" \) | while read -r FILE; do
    # 提取类名、对象声明和接口
    CLASS_NAME=$(egrep -o '(class|object|interface)\s+[a-zA-Z0-9_]+' "$FILE" | head -1 | cut -d' ' -f2)

    # 检查是否成功提取到类名
    if [ -z "$CLASS_NAME" ]; then
        echo "Cannot find class name in $FILE, skipping."
        continue
    fi

    # 读取文件内容
    if ! FILE_CONTENT=$(<"$FILE"); then
        echo "Error reading file $FILE, skipping."
        continue
    fi

    # 将类名和文件内容追加到输出文件
    # echo "File: $FILE" >> "$OUTPUT_FILE"
    echo "Type: $(head -1 "$FILE" | cut -d' ' -f2)" >> "$OUTPUT_FILE"
    echo "Name: $CLASS_NAME" >> "$OUTPUT_FILE"
    echo "Code:" >> "$OUTPUT_FILE"
    echo "$FILE_CONTENT" >> "$OUTPUT_FILE"
    echo "----------------------" >> "$OUTPUT_FILE"
done

echo "Classes have been compiled into $OUTPUT_FILE"