#!/bin/bash

MIGRATION_OUTPUT_DIR=/home/ipacs/migration/iq-results
DIFFERENCE_COUNT=0

function do_diff() {
  LEFT_FILE=$1
  RIGHT_FILE=$2
  result=$(diff ${LEFT_FILE} ${RIGHT_FILE})
  if [ $? -eq 0 ]
  then
    echo "+ files are equivalent"
  else
    DIFFERENCE_COUNT=$(( DIFFERENCE_COUNT + 1 ))
    echo "- ${LEFT_FILE} ${RIGHT_FILE} differ!"
    echo $result
  fi
}

function compare_browser() {
  # compare browser/webdisk files - drop the list of files/sizes/modifications and compute sum
  echo "Comparing webdisk file details..."
  do_diff ${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-webdisk-files.txt ${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-webdisk-files.txt

  echo "Comparing dicom/browser file details..."
  do_diff ${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-dicom-files.txt ${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-dicom-files.txt
}

function compare_logs() {
  # collect some stats about log files
  LOG_FILES='es ipacs ipacsrsync transfer'
  for file in $LOG_FILES
  do
    echo "Comparing log info for ${file}..."
    do_diff ${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-${file}-log.lines.txt ${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-${file}-log.lines.txt
    do_diff ${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-${file}-log.size.txt ${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-${file}-log.size.txt
    do_diff ${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-${file}-log.sum ${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-${file}-log.sum
  done
}

function compare_mysql() {
  # capture data from ipacs DB
  DB_TABLES='users roles user_roles projects studies studiessitescenters patients series'
  for table in $DB_TABLES
  do
    LEFT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-ipacsdb-${table}.txt
    RIGHT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-ipacsdb-${table}.txt
    echo "Comparing iPACS database content from ${table} table..."
    do_diff $LEFT_FILE $RIGHT_FILE
  done
}

function compare_history_records() {
    LEFT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-history-wfh-tasks.txt
    RIGHT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-history-camundadb-tasks.txt
    do_diff $LEFT_FILE $RIGHT_FILE

    LEFT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-history-wfh-processes.txt
    RIGHT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-history-camundadb-processes.txt
    do_diff $LEFT_FILE $RIGHT_FILE
}

function compare_camunda() {
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
    echo "Comparing Camunda database content from ${table} table..."
    LEFT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-${OLD_IPACS_VERSION}-camundadb-${table}.txt
    RIGHT_FILE=${MIGRATION_OUTPUT_DIR}/ipacs-${NEW_IPACS_VERSION}-camundadb-${table}.txt
    do_diff $LEFT_FILE $RIGHT_FILE
  done
}

if [ "$#" -ne 2 ]
then
  echo "Usage: $0 <OLD_IPACS_VERSION> <NEW_IPACS_VERSION>"
  echo ""
  echo "Example:"
  echo "$0 2.5 2020"
  exit 1
fi

OLD_IPACS_VERSION=$1
NEW_IPACS_VERSION=$2


echo "This script will COMPARE data in the ${MIGRATION_OUTPUT_DIR} directory, between ${OLD_IPACS_VERSION} and ${NEW_IPACS_VERSION}"
echo ""

compare_browser
compare_logs
compare_mysql
compare_camunda
compare_history_records

echo ""
echo "$DIFFERENCE_COUNT differences."