#用于搬运日志
#所有的日志处理均在此脚本
#临时日志的命名规则: .tmplog_TASKID.log

#判断是否为cts.sh脚本启动否则退出
isRunable 2>/dev/null || (echo "此脚本不应该手动启动，请使用cts.sh启动";exit 1) || exit 1

##首先先解锁启停脚本
unlockOper

trap '[[ -f ${PIDFILE} ]] && unlink ${PIDFILE} ;exit 0' TERM EXIT
exec 1>>$CTSLOGNAME
exec 2>>$CTSLOGNAME
exec 8<>$PIDFILE

#获取当前日期
Date=`getDate`
#日志目录
TaskLogPath=${CTSLOG}/$Date
[[ -d ${TaskLogPath} ]] || mkdir ${TaskLogPath}

while true
do

   DealNum=0
   for log in $(ls -1 ${TaskLogPath}/.tmplog_*.log 2>/dev/null)
   do
       echo $log
       logname=`basename $log`
       #截取taskid
       TaskId=$(echo $logname | sed -n 's/\.tmplog_\(.*\)\_.*.log/\1/p')
       echo $TaskId
       >> $TaskLogPath/${TaskId}_${Date}.log
       cat $log >> $TaskLogPath/${TaskId}_${Date}.log
       unlink $log
       let DealNum=DealNum+1
   done

   [[ $DealNum -gt 0 ]] && echo "日志搬运成功, 共处理[$DealNum]个日志"

   sleep ${LogMergeScanIdel}
done
