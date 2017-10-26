#!/usr/bin/env bash
# by wj

#�����������
source ../etc/cts.conf
source ../etc/pub.sh

export SHELL=bash
export PIDFILE=${CTSBIN}/.cts.pid
export CTSLOGNAME=${CTSLOG}/cts.log
export CFGUPDSVR=${CTSBIN}/insCronTaskDb.sh
export CFGUPDNAME=`basename $CFGUPDSVR .sh`
export LOGMERGSVR=${CTSBIN}/logMerge.sh
export LOGMERGNAME=`basename $LOGMERGSVR .sh`

#���ӽ����ж��Ƿ������
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
   echo    " ע: ��ʹ�øýű��������з������𵥶������ű�"
   echo    ""
}


function showService
{
   _chkService
   if [ $? -eq 0 ]
   then
      echo    "==== Cron Task Scanning Toolkit ����δ����! ====" 
   else
      echo  "====================="
      echo  "��������cts�����б�: " 
      cat   $PIDFILE  | sed -n 's/^/ +/p'
      echo  "====================="
   fi
}
 
function _chkService
{
  #����Ƿ����������
  if [ -f ${PIDFILE} ]
  then
     #�������Ƿ����
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
     #�ļ������� ���ж��Ƿ����δ�Ƴ��Ľ���
     PID=`pgrep -f $CFGUPDSVR`
     if [ $? -eq 0 ]
     then
        echo -e "Toolkit $CFGUPDNAME����(PID=$PID)δ�˳�, �Ժ�����..."
        exit 1
     fi 

     PID=`pgrep -f $LOGMERGSVR`
     if [ $? -eq 0 ]
     then
        echo -e "Toolkit $LOGMERGSVR����(PID=$PID)δ�˳�, �Ժ�����..."
        exit 1
     fi 
  fi
  return 0
}

function _startSvr
{
     local ServiceName=$1
     local ServiceNameNoSuffix=$2

     #������������
     nohup $SHELL $ServiceName 1>/dev/null 2>&1 &
     if [ $? -eq 0 ]
     then
        local ServicePid=`pgrep -f $ServiceName`
        echo "$ServiceNameNoSuffix $ServicePid" >> $PIDFILE
        echo -e ">>>> ${ServiceNameNoSuffix} are running [timestampe: $(getTimestamp)] [pid: $ServicePid]" >> $CTSLOGNAME
     else 
        echo "==== Toolkit Service [$ServiceName] ����ʧ��! ===="
        exit 1
     fi
     echo "==== Toolkit Service [$ServiceNameNoSuffix] �����ɹ�[pid=$ServicePid]! ===="
}

function boot
{
  _chkService
  if [ $?  -eq 0 ]
  then
     echo "==== Cron Task Scaning Toolkit ��������! ===="
     > $PIDFILE
     _startSvr $CFGUPDSVR $CFGUPDNAME
     _startSvr $LOGMERGSVR $LOGMERGNAME
     echo "==== Cron Task Scaning Toolkit �������! ===="
  else
     echo "==== Cron Task Scanning Toolkit ������! ===="
     exit 1
  fi

}

function _shutdown
{
   local ServiceName=$1
   PID=$(pgrep -f ${ServiceName})
   if [ -z ${PID} ]; then
      echo "service[${ServiceName}���̲�����"
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
       echo -e "Cron Task Scanning Toolkit ���ڹر�\n����: $(getTimestamp)"
       _shutdown $LOGMERGSVR
       _shutdown $CFGUPDSVR
       echo -e "<<<<CTS stoped [timestamp: $(getTimestamp)] [PID: $PID]\n\n" >> $CTSLOGNAME
       [[ -f $PIDFILE ]] && unlink $PIDFILE
       echo -e "Cron Task Scanning Toolkit �ѹر�\n"
    else
       echo -e "==== Cron Task Scanning Toolkit δ���� ===="
       exit 1
    fi
}

#��ͣ����
lockOper

if [ $? -ne 0 ]
then
   echo "���ڲ����У����Ժ�!"
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
      echo "��Ч�Ĳ���"
      exit 1
     ;;
   esac
fi

exit
