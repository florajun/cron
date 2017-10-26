#���ڰ�����־
#���е���־������ڴ˽ű�
#��ʱ��־����������: .tmplog_TASKID.log

#�ж��Ƿ�Ϊcts.sh�ű����������˳�
isRunable 2>/dev/null || (echo "�˽ű���Ӧ���ֶ���������ʹ��cts.sh����";exit 1) || exit 1

##�����Ƚ�����ͣ�ű�
unlockOper

trap '[[ -f ${PIDFILE} ]] && unlink ${PIDFILE} ;exit 0' TERM EXIT
exec 1>>$CTSLOGNAME
exec 2>>$CTSLOGNAME
exec 8<>$PIDFILE

#��ȡ��ǰ����
Date=`getDate`
#��־Ŀ¼
TaskLogPath=${CTSLOG}/$Date
[[ -d ${TaskLogPath} ]] || mkdir ${TaskLogPath}

while true
do

   DealNum=0
   for log in $(ls -1 ${TaskLogPath}/.tmplog_*.log 2>/dev/null)
   do
       echo $log
       logname=`basename $log`
       #��ȡtaskid
       TaskId=$(echo $logname | sed -n 's/\.tmplog_\(.*\)\_.*.log/\1/p')
       echo $TaskId
       >> $TaskLogPath/${TaskId}_${Date}.log
       cat $log >> $TaskLogPath/${TaskId}_${Date}.log
       unlink $log
       let DealNum=DealNum+1
   done

   [[ $DealNum -gt 0 ]] && echo "��־���˳ɹ�, ������[$DealNum]����־"

   sleep ${LogMergeScanIdel}
done
