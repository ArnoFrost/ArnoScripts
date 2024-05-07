#!/bin/bash

backupFile="cache/brewList.txt"

show_help() {
  echo "Homebrew 管理脚本 使用说明"
  echo "用法: $0 [options]"
  echo ""
  echo "选项:"
  echo "  -h, --help    显示本帮助信息"
  echo "  1              安装 Homebrew"
  echo "  2              备份 Homebrew 软件包列表"
  echo "  3              从 txt 文件恢复安装软件包"
  echo "  4              退出脚本"
  exit 0
}

handle_interrupt() {
    echo "操作被用户中断，正在退出..."
    exit 1
}

trap 'handle_interrupt' INT

install_brew() {
    echo "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew 安装完成。"
}

backup_brew() {
    echo "正在备份 Homebrew 软件包列表到 $backupFile..."
    brew list > "$backupFile"
    echo "备份完成，已保存到 $backupFile。"
}

restore_brew() {
    echo "当前备份文件为 $backupFile。"
    read -p "请输入恢复使用的文件路径（直接回车使用默认）: " userInput
    local fileToRestore="$backupFile"
    if [[ ! -z "$userInput" ]]; then
        fileToRestore="$userInput"
    fi

    if [ ! -f "$fileToRestore" ]; then
        echo "错误：文件 $fileToRestore 不存在。"
        return
    fi

    echo "从 $fileToRestore 恢复安装软件包..."
    while IFS= read -r package; do
        echo "正在安装：$package"
        brew install "$package"
    done < "$fileToRestore"
    echo "所有软件包安装完成。"
}

# 检查是否提供了帮助选项
if [[ "$#" -eq 1 ]] && ([[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]); then
  show_help
fi

PS3="请选择操作 (输入数字选择): "
options=("安装 Homebrew" "备份 Homebrew 软件包" "从 txt 恢复安装软件包" "退出")
select opt in "${options[@]}"; do
    case $REPLY in
        1) install_brew ;;
        2) backup_brew ;;
        3) restore_brew ;;
        4) echo "退出脚本..."; exit 0 ;;
        *) echo "无效的选项 $REPLY，请重新选择。";;
    esac
done