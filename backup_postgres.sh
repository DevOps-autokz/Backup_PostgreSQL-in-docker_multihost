#!/bin/ash
. .env
DATE_YEAR="$(date +%Y-%B)"
DATE="date +%Y-%m-%d_%H-%M-%S"
BACKUP_DIR="$HOME/backups/postgres"
LOG_FILE="$HOME/logs/$DATE_YEAR/postgres_backup_$($DATE).log"
LOGIN="ssh -i $HOME/.ssh/$SSH_KEY -o StrictHostKeyChecking=no deploy"
FILE="$HOME/scripts/pg_server.list"
exec 2>> $LOG_FILE

mkdir -p "$HOME/logs/$(date +%Y-%B)"
echo -e "\e[0;41m$(date +%d-%m-%Y)\e[0m" >> $LOG_FILE
> cloud_backup_list.txt
for IP in  $(cat $FILE | awk '{print $1}')
  do
  PG=$($LOGIN@$IP docker ps --format "{{.Names}}" | grep postgre)  
  SVC=$($LOGIN@$IP hostname)  
    for i in $PG
      do        
        mkdir -p $BACKUP_DIR/$SVC && \
        $LOGIN@$IP \
        docker exec $i pg_dumpall -U app | \
        gzip > "$BACKUP_DIR/$SVC/$i-$(date +%d-%m-%Y_%H-%M-%S).sql.gz" && \
        echo -e "\e[33mBackup of\e[0m \e[96m$i\e[0m \e[32msuccess\e[0m at \e[33m$(date +%H:%M:%S)\e[0m" >> $LOG_FILE || \
        echo -e "\e[33mBackup of\e[0m \e[96m$i\e[0m \e[0;31mfailed\e[0m at \e[33m$(date +%H:%M:%S)\e[0m" >> $LOG_FILE ; \
        echo $BACKUP_DIR/$SVC/$i-$(date +%d-%m-%Y_%H) >> cloud_backup_list.txt ;
	sleep 10
      done
      echo "--------------------------------------------------" >> $LOG_FILE
  done

# Delete backups older than 4 days:
find $BACKUP_DIR/* -name *gz  -mtime +3 -exec rm -f  {} \;

# Report backup completion to log file:
echo -e "Backup Completed" >> $LOG_FILE
echo "--------------------------------------------------" >> $LOG_FILE

#######  NOTICE: #########
### To make this script work on Alpine,
### install:
### sudo apk add coreutils ### (makes 'date -d' work)
### sudo apk add findutils ### (makes 'xargs -L' work)
##########################
