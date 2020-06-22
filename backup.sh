#!/bin/bash

###################################### SCRIPT TO PURGE BACKUPS OLDER THAN 3 DAYS FROM DISK ###########################################
# Script Name: azbkp.sh
# Purpose: Purge backups older than 2 days
# This script is executed from the crontab at  3:30 PM UTC

# System Paramters for Backup status Query
UNAME="azasr-svc@revginc.onmicrosoft.com"       # Azure Username
PASSWD="MzSteh7ePrqzwPvF"                       # Azure User Password
BACKUP_START_DATE=`date +%d-%m-%Y`              # Date for which the backup is to be checked
BACKUP_VAULT_NAME="Backup-Vault-NFS"            # Name of the backup vault where the NFS Servers are added
BACKUP_RESOURCE_GROUP="REV-SAP-PROD"            # Resource group which owns the backup vault
BACKUP_OPERATION="Backup"                       # Operation Type
BACKUP_ITEM="nfsserverbackup-nonprod"           # NFS Server which is backed up
                                                # NON PROD SERVER: nfsserverbackup-nonprod
                                                # PROD SERVER: nfs-server-for-backups
BACKUP_STATUS="Completed"                       # Check if the backup for the day has completed successfully

az login -u $UNAME -p $PASSWD

# Pass  folder and number of days as parameters to the below funciton
# Finds FILES inside the folder older than number of days passed as parameters
purge_folder() {

        echo "New Purge Call at `date +%x_%r`" >> $1/purge_log.`date +%d-%m-%Y`
        for i in `/usr/bin/find $1  -type f -mtime +$2`;
        do
                ls -ltr $i >> $1/purge_log.`date +%d-%m-%Y`
                /usr/bin/rm -f $i
        done;
}



if [ $? == 0 ]
then
        echo "Logged in as $UNAME"
        echo "Let me tell you what I am querying"
        echo $BACKUP_START_DATE
        echo $BACKUP_OPERATION
        echo $BACKUP_ITEM
completed_count=`/usr/bin/az backup job list --resource-group "$BACKUP_RESOURCE_GROUP"  --vault-name "$BACKUP_VAULT_NAME"  --operation "$BACKUP_OPERATION" --start-date "$BACKUP_START_DATE"  --status "$BACKUP_STATUS" --output table | grep -i $BACKUP_ITEM | wc -l`

        if [ $completed_count == 0 ]
        then
                echo "Total Completed Backup Jobs for $BACKUP_ITEM are $completed_count"
                echo "Cannot delete any older files as VM backup has not completed"

                echo "The backup of the VM $BACKUP_ITEM has not completed.  Purge of older backups not completed"  | mail -s "NON PROD Environment OLD BACKUP PURGE FAILURE " Revcloudsupport@lntinfotech.com
        else
                echo "Will delete files older than 2 days from the following folders"
                echo "/qa_sybase_backup"
                echo "/qa_fs_backup"
                echo "/dev_sol_backup"
                echo "/dev_fs_backup"
                echo "/dev_erp_backup"
                echo "/dev_sybase_backup"
                echo "/qa_erp_backup"
                echo "/sand_db_backup"

        # Calling on ERP and SOLMAN purge, there files with space in the other folders, BASIS team  need to fix that
                purge_folder "/qa_erp_backup" "2";
        #       purge_folder "/qa_fs_backup" "2";
                purge_folder "/qa_sybase_backup" "2";
                purge_folder "/dev_erp_backup" "2";
        #       purge_folder "/dev_fs_backup" "2";
                purge_folder "/dev_sol_backup" "2";
                purge_folder "/dev_sybase_backup" "2";
                purge_folder "/sand_db_backup" "2";
        fi

else
        echo "Login failed as $UNAME"

fi




