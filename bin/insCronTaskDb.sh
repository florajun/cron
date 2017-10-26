# ���ڴ�taskTemplate.ini�������ɸ�ʽ����crontask.db
# ע����ȫ������
# �������10s���һ���ļ��Ƿ��޸Ĺ� �޸Ĺ������µ�������
# ɨ��������ͨ���޸ı���: InsTaskSvrScanIdel

#�ж��Ƿ�Ϊcts.sh�ű����������˳�
isRunable 2>/dev/null || (echo "�˽ű���Ӧ���ֶ���������ʹ��cts.sh����";exit 1) || exit 1

#�����Ƚ�����ͣ�ű�
unlockOper

#kill�ź��޷��������������ɾ��ʱ����ʹ��KILL
#����term�ź�ʱ���pid��Ϣ
function exitClean
{
   [[ -f ${PIDFILE} ]] && unlink $PIDFILE; 
   exit  0
}
trap exitClean TERM EXIT

#�ض�������ʹ���
exec 1>>$CTSLOGNAME
exec 2>>$CTSLOGNAME
#����ɾ��pid�ļ�
exec 8<>$PIDFILE

LastModTime=
CronTaskDbPath=${CTSETC}/crontask.db
CronTaskDbPathTmp=${CTSETC}/.crontask.db.tmp
TaskTemplName=${CTSETC}/tasktemplat.ini
GenTasks=${CTSBIN}/genTasks.awk
WrapScript=${CTSBIN}/CallTask.sh

while true
do
    #��ȡģ���ļ�����޸ĵ�ʱ���
    CurTime=$(stat --format="%Z" ${TaskTemplName})
    
    if [ "$LastModTime" != "$CurTime" ]; then

       LastModTime=${CurTime}

       #��ʼ����
       #�������ֵ����Ҫ����#,������'\'ת��
       #�����Ҫ�����ַ�����'~@'��������
       sed -n 's/\\#/~@/g; s/#.*//; /^\s*$/d; s/~@/#/g; p' ${TaskTemplName} | \
           awk -v CronTasksFile=${CronTaskDbPathTmp} -v WrapScript=${WrapScript} -f ${GenTasks}

       #����crontab
       crontab -l | grep -v "${WrapScript}" | grep -v '^#--#' \
         | grep -v '^\s*$'  >> $CronTaskDbPathTmp

       mv ${CronTaskDbPathTmp} ${CronTaskDbPath}
       crontab $CronTaskDbPath
       LOG "crontab�����Ѹ���!"
       LOG "����װ������ɹ�!"
    fi   

    #10�������
    sleep ${InsTaskSvrScanIdel}
done

