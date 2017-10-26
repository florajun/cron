#
# WrapScript ,TmpTaskTemplPath和CronTasksFile为命令行传入参数

BEGIN{ 
     FS="=" 
     OFS="="
     preTaskId = ""
     TaskId = ""

     #清空文件
     #printf "" > TmpTaskTemplPath
     printf "" > CronTasksFile
} 

 #以任务id开始
 /^\s*\[.*\]\s*$/ {
     #保存上一个taskid
     preTaskId = TaskId
     #任务id
     TaskId=$0
     #去掉左右[]
     gsub("[[]|[]]", "", TaskId)
     TaskArr[TaskId]++;
     if (preTaskId != "")
     {
        TaskStr[preTaskId] = TaskTemplStr
     }
     #TaskTemplStr=TaskId
 }

 #任务id匹配上后处理配置字段
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
        #拼接模板记录
        TaskTemplStr=$0"~|"TaskTemplStr
     }
 }

END{
     #deal task template file
     TaskStr[TaskId] = TaskTemplStr
     for (taskid in TaskStr)
     {
       #设置了switch为ON 任务才有效
       if (Switch[taskid] == "ON")
       {
         #不为空写任务模板文件
         #if (TaskStr[taskid] != "")
         #{
         #   print TaskStr[taskid] >> TmpTaskTemplPath
         #}
         #不为空写Cron文件
         if (CronExpr[taskid] != "" && TaskStr[taskid] != "")
         {
            print CronExpr[taskid]"\t"WrapScript"\t"taskid"\t\""TaskStr[taskid]"\"" >> CronTasksFile
         }
	     if (TaskArr[taskid] > 1)
	     {
	        print "wanning: taskid-> "taskid" 存在重复定义，请查看! 当前以最后一次配置为准"
	        TaskArr[taskid]=1
	     }
         totalTasks = totalTasks + TaskArr[taskid];
       }
     }

     print "此次更新任务总数为: ["totalTasks"]"
}
