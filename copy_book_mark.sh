#!/bin/bash

# 自动获取当前工作目录作为项目路径
PROJECT_DIR=$(pwd)

# 定义 IDE 名称变量，这里可以根据需要修改为其他 IDE 的版本
IDE_NAME="AndroidStudio2023.3"

# .idea/workspace.xml 的路径
WORKSPACE_XML="$PROJECT_DIR/.idea/workspace.xml"

# 检查 workspace.xml 文件是否存在
if [ ! -f "$WORKSPACE_XML" ]; then
    echo "Error: workspace.xml file not found at $WORKSPACE_XML"
    exit 1
fi

# 使用 xmllint 工具解析 XML 文件并提取 id 值
PROJECT_ID=$(xmllint --xpath "//component[@name='ProjectId']/@id" "$WORKSPACE_XML" | cut -d '"' -f 2)

# 检查是否成功提取了 id
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Failed to extract project ID from workspace.xml"
    exit 1
fi

# 书签文件的存储路径
BOOKMARKS_DIR="/Users/xuxin/Library/Application Support/Google/$IDE_NAME/workspace"

# 书签文件的完整路径
BOOKMARK_FILE="$BOOKMARKS_DIR/$PROJECT_ID.xml"

# 桌面路径，包含 IDE 名称
DESKTOP_DIR="$HOME/Desktop/Work/Other/Bookmarks/$IDE_NAME"

# 确保桌面目录存在
mkdir -p "$DESKTOP_DIR"

# 检查书签文件是否存在
if [ ! -f "$BOOKMARK_FILE" ]; then
    echo "Error: Bookmark file not found at $BOOKMARK_FILE"
    exit 1
fi

# 拷贝书签文件到桌面
cp "$BOOKMARK_FILE" "$DESKTOP_DIR"

# 输出提取的 id
echo "Project ID extracted: $PROJECT_ID"