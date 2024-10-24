#!/bin/bash

# =========================
# 构建辅助脚本
# 功能：在构建前后备份构建产物
# 日期：2024-10-24
# =========================

#!/bin/bash

# 开始时间
start_time=$(date +%s)

# 获取Git分支名称
get_git_branch() {
    local project_dir=$1
    git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# 获取文件的MD5值
get_md5() {
    local file=$1
    md5sum "$file" | awk '{print $1}'
}

# 获取最新的备份目录
#get_latest_backup_dir() {
#    local target_dir=$1
#    find "$target_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rn | awk 'NR==1 {print $2}'
#}

# 获取最新的备份目录（适用于macOS）
get_latest_backup_dir() {
    local target_dir=$1
    # 方法一：使用stat命令
    find "$target_dir" -mindepth 1 -maxdepth 1 -type d | while read dir; do
        mod_time=$(stat -f "%m" "$dir")
        echo "$mod_time $dir"
    done | sort -rn | awk 'NR==1 {print $2}'

    # 或者方法二：使用ls命令
    # ls -1 -t -d "$target_dir"/*/ 2>/dev/null | head -n 1
}

# 判断文件是否需要备份
file_needs_backup() {
    local source_file=$1
    local latest_backup_dir=$2

    local latest_file="$latest_backup_dir/$(basename "$source_file")"

    if [ ! -e "$latest_file" ]; then
        return 0  # 需要备份
    fi

    local source_md5=$(get_md5 "$source_file")
    local latest_md5=$(get_md5 "$latest_file")

    [ "$source_md5" != "$latest_md5" ]
}

# 执行备份操作
backup_build_artifact() {
    local source_dir=$1
    local backup_dir=$2
    local operation_type=$3

    echo "源目录: $source_dir"
    echo "备份目录: $backup_dir"
    echo "操作类型: $operation_type"

    # 获取最新的备份目录
    local latest_backup_dir=$(get_latest_backup_dir "$(dirname "$backup_dir")")
    echo "最新备份目录: $latest_backup_dir"

    if [ "$operation_type" == "pre" ]; then
        if [ -z "$latest_backup_dir" ]; then
            echo "没有找到现有的备份目录，将进行完整备份。"
            send_notification "备份通知" "备份开始" "没有找到现有的备份目录，将进行完整备份。"
        else
            echo "找到最新的备份目录：$latest_backup_dir"
            send_notification "备份通知" "备份开始" "找到最新的备份目录：$(basename "$latest_backup_dir")"
        fi
    fi

    local files_backed_up=0

    for file in "$source_dir"/*; do
        if [ -e "$file" ]; then
            echo "处理文件: $file"
            if file_needs_backup "$file" "$latest_backup_dir"; then
                cp "$file" "$backup_dir/"
                if [ $? -ne 0 ]; then
                    echo "错误：文件 '$(basename "$file")' 拷贝失败。"
                    send_notification "备份失败" "操作未完成" "文件 '$(basename "$file")' 拷贝失败。"
                    return 1
                else
                    echo "成功：文件 '$(basename "$file")' 已备份。"
                    files_backed_up=$((files_backed_up + 1))
                fi
            else
                echo "跳过：文件 '$(basename "$file")' 未变化。"
            fi
        fi
    done

    if [ "$files_backed_up" -eq 0 ]; then
        echo "警告：没有新的构建产物需要备份。"
        if [ "$operation_type" == "pre" ]; then
            send_notification "备份完成" "备份结果" "没有新的构建产物需要备份，开始执行远程构建。"
        fi
    else
        echo "构建产物已成功备份到 '$backup_dir'。"
        if [ "$operation_type" == "pre" ]; then
            send_notification "备份完成" "备份结果" "构建产物已成功备份，开始执行远程构建。"
        fi
    fi
    return 0
}

# 创建备份目录
create_backup_dir() {
    local target_dir=$1

    if [ -d "$target_dir" ]; then
        echo "警告：备份目录 '$target_dir' 已存在。"
    else
        mkdir -p "$target_dir"
        if [ $? -ne 0 ]; then
            echo "错误：创建备份目录失败。"
            exit 1
        fi
        echo "成功：备份目录已创建在 '$target_dir'。"
    fi
}

# 发送通知
send_notification() {
    local title="$1"
    local subtitle="$2"
    local message="$3"

    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\""
    else
        echo "通知：[$title] $subtitle - $message"
    fi
}

# 检查结果并发送通知
check_result_and_notify() {
    local status=$1
    local runtime=$2

    if [ "$status" -eq 0 ]; then
        send_notification "操作成功" "总耗时：${runtime} 秒" "备份和构建已成功完成。"
    else
        send_notification "操作失败" "总耗时：${runtime} 秒" "备份或构建过程中出现错误。"
    fi
}

# 主函数
main() {
    local project_source="$HOME/Desktop/Work/Project/QQLive"
    local source_dir="$project_source/app/build/outputs/apk/debug/"
    local target_dir="$HOME/Desktop/Develop/归档构建产物"
    local remark=""

    # 解析命令行参数
    while getopts "m:" opt; do
        case $opt in
            m)
                remark="_${OPTARG}"
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

    # 备份构建前的产物
    local pre_backup_dir="$target_dir/${branch_name}_${timestamp}_pre"
    create_backup_dir "$pre_backup_dir"
    backup_build_artifact "$source_dir" "$pre_backup_dir" "pre"
    if [ $? -ne 0 ]; then
        check_result_and_notify 1 $(( $(date +%s) - start_time ))
        exit 1
    fi

    # 执行构建命令
    echo "开始执行构建命令..."
    ./rb assembleDebug
    if [ $? -ne 0 ]; then
        echo "错误：构建失败。"
        send_notification "构建失败" "操作未完成" "构建过程中出现错误。"
        check_result_and_notify 1 $(( $(date +%s) - start_time ))
        exit 1
    fi
    echo "构建完成。"

    # 备份构建后的产物
    local post_backup_dir="$target_dir/${branch_name}_${timestamp}_post${remark}"
    create_backup_dir "$post_backup_dir"
    backup_build_artifact "$source_dir" "$post_backup_dir" "post"
    if [ $? -ne 0 ]; then
        check_result_and_notify 1 $(( $(date +%s) - start_time ))
        exit 1
    fi

    # 结束时间和耗时
    local end_time=$(date +%s)
    local runtime=$((end_time - start_time))

    # 检查结果并发送通知
    check_result_and_notify 0 "$runtime"
}

# 执行主函数
main "$@"