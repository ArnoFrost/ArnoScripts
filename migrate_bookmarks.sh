#!/bin/bash

# 脚本使用说明
# ./migrate_bookmarks.sh -i "IDE名称" -o "输出路径"
# ./migrate_bookmarks.sh -i "AndroidStudio2023.3" -o "/path/to/output"
# 定义显示帮助信息的函数
show_help() {
  echo "迁移书签脚本使用说明"
  echo "用法: $0 [options]"
  echo ""
  echo "选项:"
  echo "  -h, --help    显示本帮助信息"
  echo "  -i IDE_NAME   指定 IDE 名称（如 AndroidStudio2023.3）"
  echo "  -o OUTPUT_PATH 指定输出路径"
  exit 0
}

# 检查是否提供了帮助选项
if [[ "$#" -eq 0 ]]; then
  show_help
fi


# 默认值
IDE_NAME_DEFAULT="AndroidStudio2023.3"
OUTPUT_PATH_DEFAULT="$HOME/Desktop/Work/Other/Bookmarks"

# 解析命令行参数
while getopts "hi:o:" opt; do
  case $opt in
    h)
      # 当用户输入 -h 或 --help 时，显示帮助信息并退出
      show_help
      ;;
    i)
      IDE_NAME="$OPTARG"
      ;;
    o)
      OUTPUT_PATH="$OPTARG"
      ;;
    \?)
      # 无效选项
      echo "无效选项：-$OPTARG" >&2
      exit 1
      ;;
    :)
      # 缺少参数值
      echo "选项 -$OPTARG 需要一个参数。" >&2
      exit 1
      ;;
    *)
      # 当遇到不认识的选项时，显示帮助信息
      show_help
      ;;
  esac
done

# 如果没有提供IDE_NAME，则使用默认值
IDE_NAME=${IDE_NAME:-$IDE_NAME_DEFAULT}

# 如果没有提供OUTPUT_PATH，则使用默认值，并创建IDE_NAME子目录
OUTPUT_PATH=${OUTPUT_PATH:-$OUTPUT_PATH_DEFAULT/$IDE_NAME}
mkdir -p "$OUTPUT_PATH"

# 自动获取当前工作目录作为项目路径
PROJECT_DIR=$(pwd)

# .idea/workspace.xml 的路径
WORKSPACE_XML="$PROJECT_DIR/.idea/workspace.xml"

# 检查 workspace.xml 文件是否存在
if [ ! -f "$WORKSPACE_XML" ]; then
    echo "错误：在 $PROJECT_DIR 中找不到 workspace.xml 文件。"
    exit 1
fi

# 使用 xmllint 工具解析 XML 文件并提取 id 值
PROJECT_ID=$(xmllint --xpath "//component[@name='ProjectId']/@id" "$WORKSPACE_XML" | cut -d '"' -f 2)

# 检查是否成功提取了 id
if [ -z "$PROJECT_ID" ]; then
    echo "错误：无法从 workspace.xml 提取项目 ID。"
    exit 1
fi

# 书签文件的存储路径
BOOKMARKS_DIR="/Users/xuxin/Library/Application Support/Google/$IDE_NAME/workspace"

# 书签文件的完整路径
BOOKMARK_FILE="$BOOKMARKS_DIR/$PROJECT_ID.xml"

# 检查书签文件是否存在
if [ ! -f "$BOOKMARK_FILE" ]; then
    echo "错误：在 $BOOKMARKS_DIR 中找不到书签文件。"
    exit 1
fi

# 拷贝书签文件到指定的输出路径
cp "$BOOKMARK_FILE" "$OUTPUT_PATH"

# 输出提取的 id 和保存位置
echo "成功提取项目 ID：$PROJECT_ID"
echo "书签文件已保存到：$OUTPUT_PATH/$PROJECT_ID.xml"