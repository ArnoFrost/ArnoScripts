#!/bin/bash

# 开始时间
start_time=$(date +%s)

# 定义函数来获取Git分支名称
get_git_branch() {
    local project_dir=$1
    git -C "$project_dir" rev-parse --abbrev-ref HEAD
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

# 定义函数来执行备份
backup_build_artifact() {
    local source_dir=$1
    local new_target_dir=$2

    cp -R "$source_dir" "$new_target_dir"
    if [ $? -ne 0 ]; then
        echo "错误：文件夹拷贝到 '$new_target_dir' 失败。"
        # 不退出脚本，继续执行后面的流程
        # exit 1  # 这行被注释掉，不再退出脚本
    else
        echo "成功：文件夹已拷贝到 '$new_target_dir'。"
    fi

    if [ -z "$(ls -A "$new_target_dir")" ]; then
        echo "警告：未转移构建产物，目标文件夹为空。"
    else
        echo "构建产物已成功转移。"
    fi
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
    backup_build_artifact "$source_dir" "$target_dir/debug_${branch_name}_${timestamp}_${after_postfix}"

    # 结束时间
    end_time=$(date +%s)

    # 计算脚本运行时间
    runtime=$((end_time - start_time))
    # 脚本结束前发送通知
    check_result_and_notify "$runtime"
}

# 调用主函数
main