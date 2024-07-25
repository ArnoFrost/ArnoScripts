#!/bin/bash

# 函数：显示使用方法
usage() {
    echo "Usage: $0 <start_commit> <end_commit>"
    echo " 例如：$0 a73ed05a 6735ec11"
}

# 检查参数数量
if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

# 读取起始和终止提交
start_commit=$1
end_commit=$2

# 检查当前目录是否为Git仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "错误：当前目录不是一个Git仓库。"
    exit 1
fi

# 获取作者列表
authors=$(git log --format='%aN' $start_commit..$end_commit | sort)

# 如果没有作者，提前退出
if [ -z "$authors" ]; then
    echo "在指定的提交范围之间没有找到作者。"
    exit 1
fi

# 打印作者列表
echo "作者列表（去重前）："
echo "$authors"

# 去重并打印唯一作者列表
unique_authors=$(echo "$authors" | uniq)

# 打印唯一作者列表
echo "唯一作者列表："
echo "$unique_authors"

# 计算作者数量
author_count=$(echo "$unique_authors" | wc -l)

# 输出结果
echo "在提交范围 $start_commit 和 $end_commit 之间的唯一作者数量：$author_count"