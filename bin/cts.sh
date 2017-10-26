#!/usr/bin/env bash
# by wj

#导入服务配置
source ../etc/cts.conf
source ../etc/pub.sh

export SHELL=bash
export PIDFILE=${CTSBIN}/.cts.pid
export CTSLOGNAME=${CTSLOG}/cts.log
export CFGUPDSVR=${CTSBIN}/insCronTaskDb.sh
export CFGUPDNAME=`basename $CFGUPDSVR .sh`
export LOGMERGSVR=${CTSBIN}/logMerge.sh
export LOGMERGNAME=`basename $LOGMERGSVR .sh`

#给子进程判断是否可运行
function isRunable
{
   return 0
}
declare -fx isRunable

function showUsage
{
   echo -e "\t====================================="
   echo -e "\t| Cron Task Scanning Toolkit V1.0   |"
   echo -e "\t=====================================\n"
   echo    " Usage: $0 b|s|l"
   echo    "        *b-> boot"
   echo    "        *s-> shutdown"
   echo    "        *l-> list pid"
   echo    "        *h-> show usage"
   echo    " 注: 请使用该脚本启动所有服务，请勿单独启动脚本"
   echo    ""
}


function showService
{
   _chkService
   if [ $? -eq 0 ]
   then
      echo    "==== Cron Task Scanning Toolkit 服务未启动! ====" 
   else
      echo  "====================="
      echo  "已启动的cts服务列表: " 
      cat   $PIDFILE  | sed -n 's/^/ +/p'
      echo  "====================="
   fi
}
 
function _chkService
{
  #检查是否服务已启动
  if [ -f ${PIDFILE} ]
  then
     #检查进程是否存在
     PID=`cat $PIDFILE | grep $CFGUPDNAME | awk '{print $2}' | tr -d '\n' `
     if [ "X${PID}" != "X"  -a  "X"$(pgrep -f $CFGUPDSVR | tr -d '\n') == "X${PID}"  ] 
     then
        return 1
     fi
     PID=`cat $PIDFILE | grep $LOGMERGNAME | awk '{print $2}' | tr -d '\n'`
     if [ "X${PID}" != "X"  -a  "X"$(pgrep -f $LOGMERGNAME | tr -d '\n') == "X${PID}"  ] 
     then
        return 1
     fi
  else
     #文件不存在 再判断是否存在未推出的进程
     PID=`pgrep -f $CFGUPDSVR`
     if [ $? -eq 0 ]
     then
        echo -e "Toolkit $CFGUPDNAME服务(PID=$PID)未退出, 稍后再试..."
        exit 1
     fi 

     PID=`pgrep -f $LOGMERGSVR`
     if [ $? -eq 0 ]
     then
        echo -e "Toolkit $LOGMERGSVR服务(PID=$PID)未退出, 稍后再试..."
        exit 1
     fi 
  fi
  return 0
}

function _startSvr
{
     local ServiceName=$1
     local ServiceNameNoSuffix=$2

     #启动启动服务
     nohup $SHELL $ServiceName 1>/dev/null 2>&1 &
     if [ $? -eq 0 ]
     then
        local ServicePid=`pgrep -f $ServiceName`
        echo "$ServiceNameNoSuffix $ServicePid" >> $PIDFILE
        echo -e ">>>> ${ServiceNameNoSuffix} are running [timestampe: $(getTimestamp)] [pid: $ServicePid]" >> $CTSLOGNAME
     else 
        echo "==== Toolkit Service [$ServiceName] 启动失败! ===="
        exit 1
     fi
     echo "==== Toolkit Service [$ServiceNameNoSuffix] 启动成功[pid=$ServicePid]! ===="
}

function boot
{
  _chkService
  if [ $?  -eq 0 ]
  then
     echo "==== Cron Task Scaning Toolkit 正在启动! ===="
     > $PIDFILE
     _startSvr $CFGUPDSVR $CFGUPDNAME
     _startSvr $LOGMERGSVR $LOGMERGNAME
     echo "==== Cron Task Scaning Toolkit 启动完成! ===="
  else
     echo "==== Cron Task Scanning Toolkit 已启动! ===="
     exit 1
  fi

}

function _shutdown
{
   local ServiceName=$1
   PID=$(pgrep -f ${ServiceName})
   if [ -z ${PID} ]; then
      echo "service[${ServiceName}进程不存在"
      return 1
   else
      echo "   shutdown service[`basename $ServiceName .sh`] $PID"
      kill -TERM ${PID}
   fi
}

function shutdown
{
    _chkService
    if [ $? -eq 1 ]
    then
       echo -e "Cron Task Scanning Toolkit 正在关闭\n日期: $(getTimestamp)"
       _shutdown $LOGMERGSVR
       _shutdown $CFGUPDSVR
       echo -e "<<<<CTS stoped [timestamp: $(getTimestamp)] [PID: $PID]\n\n" >> $CTSLOGNAME
       [[ -f $PIDFILE ]] && unlink $PIDFILE
       echo -e "Cron Task Scanning Toolkit 已关闭\n"
    else
       echo -e "==== Cron Task Scanning Toolkit 未启动 ===="
       exit 1
    fi
}

#启停加锁
lockOper

if [ $? -ne 0 ]
then
   echo "正在操作中，请稍后!"
   exit 1
fi

if [ $# -ne 1 ]
then
   showUsage
   exit 1
else
   case $1 in
     "b")
       boot
     ;;
     "s")
       shutdown
     ;;
     "l")
       showService
     ;;
     "h")
       showUsage
     ;;
     *)
      echo "无效的参数"
      exit 1
     ;;
   esac
fi

exit
