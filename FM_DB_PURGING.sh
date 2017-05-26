#! /bin/bash

if [ $# == 1 ]
then
  echo "Performing purging activity in $1 environment .."
  ENV=`echo $1| tr '[:lower:]' '[:upper:]'`
  if [ $ENV == "SIT" ]
  then 
	  PCARD=/opt/pwrcard
	  ORA_USER=FMGR_USER
	  ORA_PASS=NewU53r
  elif [ $ENV == "UAT" ]
  then
      PCARD=/opt/pwrcard/UAT
	  ORA_USER=FMGR_USER
	  ORA_PASS=fm8admin16
  else
      echo "Trying in some other environment... need to modify the script..."
	  exit 1
  fi
else
  echo "Parameter need to be passed to the script : $0 <env name>"
  exit 1
fi

source $PCARD/.pcard_profile

#Purging activity for FM tables

cd $WRAPPER_LOGS
sqlplus -S $ORA_USER/$ORA_PASS > /dev/null 2>&1 << EOF
set head off;
spool on;
spool purging_fm_ables.txt

--select statements for below tables
--JOBS Table
select * from JOBS where JOBNAME like '%MO%' and REQUESTDATE like '%20-MAY-17%';
select * from JOBS where JOBNAME like '%HK%' and REQUESTDATE like '%20-MAY-17%';
--JOB_STATUS Table
select * from JOB_STATUS where JOBID in (select JOBID from (select a.JOBID, a.JOBNAME, a.REQUESTDATE, a.PROCESSDATE, b.STATUS, b.statusdate FROM JOBS a, JOB_STATUS b where a.STATUSID = b.STATUSID and a.JOBNAME like '%MO%' and a.REQUESTDATE like '%20-MAY-17%' order by a.REQUESTDATE desc));
select * from JOB_STATUS where JOBID in (select JOBID from (select a.JOBID, a.JOBNAME, a.REQUESTDATE, a.PROCESSDATE, b.STATUS, b.statusdate FROM JOBS a, JOB_STATUS b where a.STATUSID = b.STATUSID and a.JOBNAME like '%HK%' and a.REQUESTDATE like '%20-MAY-17%' order by a.REQUESTDATE desc));
--FILETYPESFORJOB
select * from FILETYPESFORJOB where FILETYPE like '%MO%' union select * from FILETYPESFORJOB where FILETYPE like '%HK%';
select * from FILETYPESFORJOB where FILETYPE like '%MO%' union select * from FILETYPESFORJOB where FILETYPE like '%MO%';
--DATAFILES
select * from DATAFILES where FILEID in (select FILEID from (select a.FILEID, a.FILENAME, a.CREATEDATE, a.PROCESSDATE, a.FILETYPE, b.STATUS, b.statusdate FROM DATAFILES a, FILE_STATUS b where b.STATUSID = a.STATUSID and FILENAME like '%HK%' order by b.statusdate));
--FILE_STATUS
select * from FILE_STATUS where FILEID in (select FILEID from (select b.FILEID, a.FILENAME, a.CREATEDATE, a.PROCESSDATE, a.FILETYPE, b.STATUS, b.statusdate FROM DATAFILES a, FILE_STATUS b where b.STATUSID = a.STATUSID and FILENAME like '%HK%' order by b.statusdate));

spool out

exit;
EOF

