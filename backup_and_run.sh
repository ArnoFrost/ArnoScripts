#!/bin/bash

# 开始时间
start_time=$(date +%s)

# 定义函数来获取Git分支名称
get_git_branch() {
    local project_dir=$1
    git -C "$project_dir" rev-parse --abbrev-ref HEAD
}
# 定义函数来获取文件的 MD5 值
get_md5() {
    local file=$1
    md5sum "$file" | awk '{print $1}'
}

# 定义函数来获取最新的备份文件夹
get_latest_backup_dir() {
    local target_dir=$1
    echo $(find "$target_dir" -type d -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)
}

# 修改 file_needs_backup 函数来比较与最新备份文件夹中文件的 MD5 值
file_needs_backup() {
    local source_file=$1
    local target_file=$2
    local latest_backup_dir=$3

    # 获取最新备份目录中的对应文件的路径
    local latest_file="$latest_backup_dir/$(basename "$source_file")"

    # 如果最新备份目录中的对应文件不存在，则需要备份
    if [ ! -e "$latest_file" ]; then
        return 0
    fi

    # 获取文件和最新备份文件的 MD5 值
    local source_md5=$(get_md5 "$source_file")
    local latest_md5=$(get_md5 "$latest_file")

    # 如果 MD5 值不同，则需要备份
    if [ "$source_md5" != "$latest_md5" ]; then
        return 0
    fi

    # 如果 MD5 值相同，则不需要备份
    return 1
}

# 定义函数来执行备份，添加了检查文件是否需要备份的逻辑
backup_build_artifact() {
    local source_dir=$1
    local new_target_dir=$2

    # 获取最新备份目录
    local latest_backup_dir=$(get_latest_backup_dir "$new_target_dir")
    if [ -z "$latest_backup_dir" ]; then
        echo "没有找到现有的备份目录，将进行完整备份。"
    else
        echo "找到最新的备份目录：$latest_backup_dir"
    fi

    # 检查并备份文件
    for file in "$source_dir"/*; do
        if [ -e "$file" ]; then
            target_file="$new_target_dir/$(basename "$file")"
            if file_needs_backup "$file" "$target_file" "$latest_backup_dir"; then
                cp -R "$file" "$new_target_dir"
                if [ $? -ne 0 ]; then
                    echo "错误：文件 '$(basename "$file")' 拷贝失败。"
                else
                    echo "成功：文件 '$(basename "$file")' 已拷贝到 '$new_target_dir'。"
                fi
            else
                echo "跳过：文件 '$(basename "$file")' 与最新备份相同。"
            fi
        fi
    done

    if [ -z "$(ls -A "$new_target_dir")" ]; then
        echo "警告：未转移构建产物，目标文件夹为空。"
    else
        echo "构建产物已成功转移。"
    fi
}

# 定义函数来创建备份目录
create_backup_dir() {
    local source_dir=$1
    local target_dir=$2
    local branch_name=$3
    local timestamp=$4
    local prefix=$5

    local new_target_dir="$target_dir/debug_${branch_name}_${timestamp}_${prefix}"
    if [ -d "$new_target_dir" ]; then
        echo "警告：目标文件夹 '$new_target_dir' 已存在。"
    else
        mkdir -p "$new_target_dir"
        if [ $? -ne 0 ]; then
            echo "错误：创建目标文件夹失败。"
            exit 1
        fi
    fi
    echo "成功：目标文件夹已创建在 '$new_target_dir'。"
}


# 检查结果并发送通知的函数
check_result_and_notify() {
    local runtime=$1
    local success_message="备份成功，耗时: ${runtime} 秒"
    local failure_message="备份失败，耗时: ${runtime} 秒"

    # 检查脚本执行状态
    if [ $? -eq 0 ]; then
        send_notification "备份成功" "操作已完成" "$success_message"
    else
        send_notification "备份失败" "操作未完成" "$failure_message"
    fi
}

# 发送通知的函数
send_notification() {
    local title="$1"
    local subtitle="$2"
    local message="$3"

    osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\""
}

# 主逻辑
main() {
    local project_source="$HOME/Desktop/Work/Project/QQLive"
    local source_dir="$project_source/app/build/outputs/apk/debug/"
    local target_dir="$HOME/Desktop/Develop/归档构建产物"
    local remark=""

    # 解析命令行参数
    while getopts "m:" opt; do
        case $opt in
            m)
                remark="$OPTARG"
                ;;
            *)
                echo "用法: $0 [-m 备注]"
                exit 1
                ;;
        esac
    done

    local branch_name=$(get_git_branch "$project_source")
    if [ -z "$branch_name" ]; then
        echo "错误：无法获取Git分支名称或工程目录不是一个Git仓库。"
        exit 1
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")

    # 执行before备份
    local before_prefix="pre"
    create_backup_dir "$source_dir" "$target_dir" "$branch_name" "$timestamp" "$before_prefix"
    backup_build_artifact "$source_dir" "$target_dir/debug_${branch_name}_${timestamp}_${before_prefix}"

    # 执行原本的命令
    ./rb assembleDebug

    # 执行after备份
    local after_postfix="post"
    create_backup_dir "$source_dir" "$target_dir" "$branch_name" "$timestamp" "$after_postfix"
    backup_build_artifact "$source_dir" "$target_dir/debug_${branch_name}_${timestamp}_${after_postfix}_${remark}"

    # 结束时间
    end_time=$(date +%s)

    # 计算脚本运行时间
    runtime=$((end_time - start_time))
    # 脚本结束前发送通知
    check_result_and_notify "$runtime"
}

# 调用主函数
main