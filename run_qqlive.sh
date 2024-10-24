#!/bin/bash
# 检查结果并发送通知的函数
check_result_and_notify() {
    local runtime=$1
    local success_message="运行程序成功，耗时: ${runtime} 秒"

    send_notification "运行程序成功" "操作已完成" "$success_message"
}
# 发送通知的函数
send_notification() {
    local title="$1"
    local subtitle="$2"
    local message="$3"

    osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\""
}
# 开始时间
start_time=$(date +%s)

# 执行原本的命令
./rb assembleDebug

# 结束时间
end_time=$(date +%s)

# 计算脚本运行时间
runtime=$((end_time - start_time))

# 打印运行时间提示
# echo "脚本运行结束，耗时: ${runtime} 秒"

# 脚本结束前发送通知
check_result_and_notify "$runtime"