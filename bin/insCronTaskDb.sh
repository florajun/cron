# 用于从taskTemplate.ini表中生成格式任务到crontask.db
# 注意是全量更新
# 服务程序：10s检查一下文件是否修改过 修改过即重新导入配置

#判断是否为cts.sh脚本启动否则退出
isRunable 2>/dev/null || (echo "此脚本不应该手动启动，请使用cts.sh启动";exit 1) || exit 1

#首先先解锁启停脚本
unlockOper

#kill信号无法捕获因此命令行删除时不能使用KILL
#设置term信号时清除pid信息
function exitClean
{
   [[ -f ${PIDFILE} ]] && unlink $PIDFILE; 
   exit  0
}
trap exitClean TERM EXIT

#重定向输出和错误
exec 1>>$CTSLOGNAME
exec 2>>$CTSLOGNAME
#用于删除pid文件
exec 8<>$PIDFILE

LastModTime=
CronTaskDbPath=${CTSETC}/crontask.db
CronTaskDbPathTmp=${CTSETC}/.crontask.db.tmp
TaskTemplName=${CTSETC}/tasktemplat.ini
GenTasks=${CTSBIN}/genTasks.awk
WrapScript=${CTSBIN}/CallTask.sh

#只保留0和1的配置
#declare -a TaskTemplArr

while true
do
    #获取模板文件最后修改的时间戳
    CurTime=$(stat --format="%Z" ${TaskTemplName})
    
    if [ "$LastModTime" != "$CurTime" ]; then

       LastModTime=${CurTime}

       #开始更新
       #生成crontasks和TaskTempl数据文件
       #TaskTemplArr[2]=${TaskTemplArr[1]}
       #TaskTemplArr[1]=${TaskTemplArr[0]}
       #TaskTemplArr[0]=`dirname ${TaskTemplName}`"/."`basename ${TaskTemplName} .sh`.`date +%s`

       sed -n 's/\\#/~@/g; s/#.*//; /^\s*$/d; s/~@/#/g; p' ${TaskTemplName} | \
           awk -v CronTasksFile=${CronTaskDbPathTmp} -v WrapScript=${WrapScript} -f ${GenTasks}

       #清理第三次生成的模板
       #[[ -f ${TaskTemplArr[2]} ]] && unlink ${TaskTemplArr[2]} 
       #LOG "TASK模板信息已更新"

       #处理crontab
       crontab -l | grep -v "${WrapScript}" >> $CronTaskDbPathTmp
       mv ${CronTaskDbPathTmp} ${CronTaskDbPath}
       crontab $CronTaskDbPath
       LOG "crontab配置已更新!"
       LOG "重新装载任务成功!"
       
    fi   

    #10秒后再试
    sleep ${InsTaskSvrScanIdel}
done

