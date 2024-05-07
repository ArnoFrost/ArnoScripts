#!/bin/bash

VERSION=1.0
# 脚本存放的目录
SCRIPTS_DIR="/Users/xuxin/Desktop/Work/Code/scripts"

# 获取脚本目录中所有可执行脚本的列表，并按名称排序
sorted_scripts=$(ls -1 "$SCRIPTS_DIR"/* | grep -E '^.+\.sh$' | sort)

# 计算脚本总数
num_scripts=$(echo "$sorted_scripts" | wc -l)

# 显示欢迎信息和脚本总数
echo -e "欢迎使用 Arno 脚本引导程序 版本:$VERSION"
echo -e "共有 ${num_scripts} 个可用脚本："

# 初始化序号
script_number=1

# 遍历排序后的脚本列表
for script in $sorted_scripts; do
  # 获取脚本的文件名
  script_name=$(basename "$script")

  # 忽略当前的 scripts_help.sh 脚本
  if [[ "$script_name" != "scripts_help.sh" ]]; then
    # 设置蓝色
    blue=$(tput setaf 4)
    # 重置颜色
    reset=$(tput sgr0)

    # 显示脚本序号和名称，使用蓝色
    echo -e "${blue}[$script_number] $script_name${reset}"

    # 调用脚本显示帮助信息，假设每个脚本都支持 -h 或 --help 参数
    if "$script" -h >/dev/null 2>&1; then
      # 调用脚本并显示帮助信息
      echo "$script -h"
      "$script" -h
    else
      echo "此脚本没有帮助信息。"
    fi
    # 更新序号
    ((script_number++))
  fi

  # 添加分隔线
  echo "------------------------------------"
done

# 等待用户输入，以便查看完整列表
read -p "按任意键退出... "