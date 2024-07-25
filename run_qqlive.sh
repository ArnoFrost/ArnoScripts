#!/bin/bash

# 开始时间
start_time=$(date +%s)

# 执行原本的命令
./rb assembleDebug

# 结束时间
end_time=$(date +%s)

# 计算脚本运行时间
runtime=$((end_time - start_time))

# 打印运行时间提示
echo "脚本运行结束，耗时: ${runtime} 秒"