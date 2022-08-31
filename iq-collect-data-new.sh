#!/bin/bash

IPACS_MYSQL_USERNAME=ipacs
IPACS_MYSQL_PASSWORD=CHANGEME
IPACS_MYSQL_HOST=127.0.0.1
IPACS_MYSQL_PORT=3309

CAMUNDA_MYSQL_USERNAME=root
CAMUNDA_MYSQL_PASSWORD=CHANGEME
CAMUNDA_MYSQL_HOST=127.0.0.1
CAMUNDA_MYSQL_PORT=3306

MIGRATION_OUTPUT_DIR=/home/ipacs/migration/iq-results
mkdir -p $MIGRATION_OUTPUT_DIR

function collect_browser() {
  # gather details about browser/webdisk files - drop the list of files/sizes/modifications and compute sum
  echo "Collecting webdisk file details..."
  ls -alR --full-time /home/ipacs/ipacs/data/webdisk > ${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-webdisk-files.txt
  echo "Collecting dicom/browser file details..."
  ls -alR --full-time /home/ipacs/ipacs/data/dicom > ${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-dicom-files.txt
}

function collect_logs() {
  # collect some stats about log files
  LOG_FILES='es ipacs ipacsrsync transfer'
  for file in $LOG_FILES
  do
    echo "Collecting log info for ${file}..."
    wc -l /home/ipacs/ipacs/log/${file}.log > ${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-${file}-log.lines.txt
    ls -l /home/ipacs/ipacs/log/${file}.log > ${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-${file}-log.size.txt
    sha1sum /home/ipacs/ipacs/log/${file}.log > ${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-${file}-log.sum
  done
}

function collect_mysql() {
  # capture data from ipacs DB
  DB_TABLES='users roles user_roles projects studies studiessitescenters patients series'
  for table in $DB_TABLES
  do
    outfile=${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-ipacsdb-${table}.txt
    echo "Collecting iPACS database content from ${table} table..."
    mysql -u ${IPACS_MYSQL_USERNAME} -p${IPACS_MYSQL_PASSWORD} -h${IPACS_MYSQL_HOST} -P${IPACS_MYSQL_PORT} \
      ipacs-ipacs -e "select * from ${table} order by 1, 2" > ${outfile}
  done
}

function collect_camunda() {
  # capture data from "history" tables
  # https://docs.camunda.org/manual/7.11/user-guide/process-engine/database/
  DB_TABLES=(
    'ACT_HI_ACTINST'
    'ACT_HI_ATTACHMENT'
    'ACT_HI_BATCH'
    'ACT_HI_CASEACTINST'
    'ACT_HI_CASEINST'
    'ACT_HI_COMMENT'
    'ACT_HI_DECINST'
    'ACT_HI_DEC_IN'
    'ACT_HI_DEC_OUT'
    'ACT_HI_DETAIL'
    'ACT_HI_EXT_TASK_LOG'
    'ACT_HI_IDENTITYLINK'
    'ACT_HI_INCIDENT'
    'ACT_HI_JOB_LOG'
    'ACT_HI_OP_LOG'
    'ACT_HI_PROCINST'
    'ACT_HI_TASKINST'
    'ACT_HI_VARINST'
  )
  for table in ${DB_TABLES[@]}
  do
    echo "Collecting Camunda database content from ${table} table..."
    outfile=${MIGRATION_OUTPUT_DIR}/ipacs-${IPACS_VERSION}-camundadb-${table}.txt
    mysql -u ${CAMUNDA_MYSQL_USERNAME} -p${CAMUNDA_MYSQL_PASSWORD} -h${CAMUNDA_MYSQL_HOST} -P${CAMUNDA_MYSQL_PORT} \
      camunda_db -e "select * from ${table} order by ID_" > ${outfile}
  done
}

if [ "$#" -ne 1 ]
then
  echo "Usage: $0 <IPACS_VERSION>"
  echo ""
  echo "Example:"
  echo "$0 2.5"
  exit 1
fi

IPACS_VERSION=$1

echo "This script will capture data to the ${MIGRATION_OUTPUT_DIR} directory, and assumes that the RUNNING iPACS version is: ${IPACS_VERSION}"
echo "Please ensure the version is correct, and that both the mysql and camunda DB containers are running."
echo ""
read -p "Would you like to continue? [Yn]: " yn
case $yn in
  [Yy]* )
    collect_browser
    collect_logs
    collect_mysql
    collect_camunda
    exit
    ;;
  [Nn]* )
    exit
    ;;
  * )
    echo "Please answer Yn"
    ;;
esac