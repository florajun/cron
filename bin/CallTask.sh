#!/usr/bin/env bash

# 该脚本调用由insCronTaskDb服务生成，一般不自行调用
# para: confpath taskid 
#

#cron调度时路径从home开始 此处指定绝对路径
source ${HOME}/cron/etc/pub.sh || exit 1

function usage
{
   echo "usage: $0 任务号 调用参数"
}

#需提供2个参数
if [ $# -ne 2 ]
then
   usage
   exit 1
fi

TaskId=$1
CallPara=$2
CurrDate=`getDate`
TaskLogName="${CTSLOG}/${CurrDate}/.tmplog_${TaskId}_$$.log"
ConcurrencyOffLock=${CTSHOME}/lock/$TaskId.lock

exec 1>> $TaskLogName
exec 2>> $TaskLogName

function getConfByKey
{
   local TaskConf=$1
   local  Key=$2
   echo ${TaskConf} | awk -F'~[|]' -v OFS='\n' '{ $1=$1; print $0}' | \
   awk -F'=' -v Key=${Key} '$1 == Key {print $2}' 
}

#获取并发标识
TaskConcurrency=`getConfByKey $CallPara "TaskConcurrency"`
echo "并发标志:[$TaskConcurrency]"

#获取Cmd
Cmd=`getConfByKey $CallPara "CMD"`
echo "命令:[$Cmd]"

#获取CmdPara
CmdPara=`getConfByKey $CallPara "CMDPara"`
echo "命令参数:[$CmdPara]"

if [ "${TaskConcurrency}" == "OFF" ]
then
   #不允许任务并发
   [[ -f $ConcurrencyOffLock ]] && logExit "任务${TaskId}不允许并发,当前已有该任务的实例运行，$$进程退出!"
   touch $ConcurrencyOffLock
fi

#执行任务
[[ ! -z $Cmd ]] && $Cmd $CmdPara

#清理锁
[[ -f $ConcurrencyOffLock ]] && unlink $ConcurrencyOffLock
