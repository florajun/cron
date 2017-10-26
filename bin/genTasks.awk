#
# WrapScript ,TmpTaskTemplPath��CronTasksFileΪ�����д������

BEGIN{ 
     FS="=" 
     OFS="="
     preTaskId = ""
     TaskId = ""

     #����ļ�
     #printf "" > TmpTaskTemplPath
     printf "" > CronTasksFile
} 

 #������id��ʼ
 /^\s*\[.*\]\s*$/ {
     #������һ��taskid
     preTaskId = TaskId
     #����id
     TaskId=$0
     #ȥ������[]
     gsub("[[]|[]]", "", TaskId)
     TaskArr[TaskId]++;
     if (preTaskId != "")
     {
        TaskStr[preTaskId] = TaskTemplStr
     }
     #TaskTemplStr=TaskId
 }

 #����idƥ���Ϻ��������ֶ�
 /=/ && TaskId != ""{
     #tail trim
     gsub("[ \t]*$", "", $1)
     gsub("[ \t]*$", "", $2)
     if ($1 == "Switch")
     {
        Switch[TaskId] = $2
     }
     else if ($1 == "CronExpr")
     {
        CronExpr[TaskId] = $2#"\t"WrapScript"\t"TmpTaskTemplPath"\t"TaskId 
     }
     else
     {
        #ƴ��ģ���¼
        TaskTemplStr=$0"~|"TaskTemplStr
     }
 }

END{
     #deal task template file
     TaskStr[TaskId] = TaskTemplStr
     for (taskid in TaskStr)
     {
       #������switchΪON �������Ч
       if (Switch[taskid] == "ON")
       {
         #��Ϊ��д����ģ���ļ�
         #if (TaskStr[taskid] != "")
         #{
         #   print TaskStr[taskid] >> TmpTaskTemplPath
         #}
         #��Ϊ��дCron�ļ�
         if (CronExpr[taskid] != "" && TaskStr[taskid] != "")
         {
            print CronExpr[taskid]"\t"WrapScript"\t"taskid"\t\""TaskStr[taskid]"\"" >> CronTasksFile
         }
	     if (TaskArr[taskid] > 1)
	     {
	        print "wanning: taskid-> "taskid" �����ظ����壬��鿴! ��ǰ�����һ������Ϊ׼"
	        TaskArr[taskid]=1
	     }
         totalTasks = totalTasks + TaskArr[taskid];
       }
     }

     print "�˴θ�����������Ϊ: ["totalTasks"]"
}
