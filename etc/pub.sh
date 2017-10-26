source ${HOME}/.bashrc

export CTSHOME=${HOME}/cron
export CTSETC=${CTSHOME}/etc
export CTSLOG=${CTSHOME}/log
export CTSBIN=${CTSHOME}/bin
export LOCKFILE=${CTSBIN}/.cts.lock
export PIDFILE=${CTSHOME}/bin/.cts.pid
export InsTaskSvrScanIdel=10
export LogMergeScanIdel=10
export LOCKFD=6

function logExit
{
    LOG $*
    exit 1
}
function logRet
{
    LOG $*
    return 1
}

function getTimestamp
{
    date '+%Y-%m-%d %H:%m:%S' | tr -d '\n'
}

function getDate
{
    local delim=$1
    date "+%Y${delim}%m${delim}%d" | tr -d '\n'
}

function LOG
{
    local taskid=$1"|"
    echo -e " $(getTimestamp)|${taskid} $*"
}

function lockOper
{
  #ÆôÍ£¼ÓËø
  [[ ! -f $LOCKFILE ]] && touch $LOCKFILE
  exec 6<>$LOCKFILE
  flock -xn ${LOCKFD}
}

function unlockOper
{
  #ÆôÍ£½âËø
  flock -u ${LOCKFD}
  unlink ${LOCKFILE}
}

declare -fx logRet logExit getTimestamp LOG unlockOper lockOper getDate


