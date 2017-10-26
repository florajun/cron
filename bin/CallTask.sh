#!/usr/bin/env bash

# �ýű�������insCronTaskDb�������ɣ�һ�㲻���е���
# para: confpath taskid 
#

#cron����ʱ·����home��ʼ �˴�ָ������·��
source ${HOME}/cron/etc/pub.sh || exit 1

function usage
{
   echo "usage: $0 ����� ���ò���"
}

#���ṩ2������
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

#��ȡ������ʶ
TaskConcurrency=`getConfByKey $CallPara "TaskConcurrency"`
echo "������־:[$TaskConcurrency]"

#��ȡCmd
Cmd=`getConfByKey $CallPara "CMD"`
echo "����:[$Cmd]"

#��ȡCmdPara
CmdPara=`getConfByKey $CallPara "CMDPara"`
echo "�������:[$CmdPara]"

if [ "${TaskConcurrency}" == "OFF" ]
then
   #���������񲢷�
   [[ -f $ConcurrencyOffLock ]] && logExit "����${TaskId}��������,��ǰ���и������ʵ�����У�$$�����˳�!"
   touch $ConcurrencyOffLock
fi

#ִ������
[[ ! -z $Cmd ]] && $Cmd $CmdPara

#������
[[ -f $ConcurrencyOffLock ]] && unlink $ConcurrencyOffLock
