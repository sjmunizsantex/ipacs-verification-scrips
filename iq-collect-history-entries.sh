#!/bin/bash

WFH_MYSQL_USERNAME=ipacs
WFH_MYSQL_PASSWORD=CHANGEME
WFH_MYSQL_HOST=127.0.0.1
WFH_MYSQL_PORT=3308
WFH_MYSQL_DB_NAME=workflow-history


CAMUNDA_MYSQL_USERNAME=root
CAMUNDA_MYSQL_PASSWORD=CHANGEME
CAMUNDA_MYSQL_HOST=127.0.0.1
CAMUNDA_MYSQL_PORT=3306

MIGRATION_OUTPUT_DIR=/home/ipacs/migration/iq-results
mkdir -p $MIGRATION_OUTPUT_DIR

function collect_wfh_tasks() {
  # capture data from ipacs DB
  outfile=${MIGRATION_OUTPUT_DIR}/ipacs-history-wfh-tasks.txt
  echo "Collecting WFH database content from tasks table..."
  mysql -u ${WFH_MYSQL_USERNAME} -p${WFH_MYSQL_PASSWORD} -h${WFH_MYSQL_HOST} -P${WFH_MYSQL_PORT} \
    ${WFH_MYSQL_DB_NAME} -e "select id AS ID_ from tasks order by id" > ${outfile}
}

function collect_wfh_processes() {
  # capture data from ipacs DB
  outfile=${MIGRATION_OUTPUT_DIR}/ipacs-history-wfh-processes.txt
  echo "Collecting WFH database content from processes table..."
  mysql -u ${WFH_MYSQL_USERNAME} -p${WFH_MYSQL_PASSWORD} -h${WFH_MYSQL_HOST} -P${WFH_MYSQL_PORT} \
    ${WFH_MYSQL_DB_NAME} -e "select id as ID_ from processes order by id" > ${outfile}
}

function collect_camunda_tasks() {
    echo "Collecting Camunda database content from ACT_HI_TASK_INST table..."
    outfile=${MIGRATION_OUTPUT_DIR}/ipacs-history-camundadb-tasks.txt
    mysql -u ${CAMUNDA_MYSQL_USERNAME} -p${CAMUNDA_MYSQL_PASSWORD} -h${CAMUNDA_MYSQL_HOST} -P${CAMUNDA_MYSQL_PORT} \
      camunda_db -e "select ID_ from ACT_HI_TASKINST where DELETE_REASON_ IS NOT NULL order by ID_" > ${outfile}
}

function collect_camunda_processes() {
    echo "Collecting Camunda database content from ACT_HI_PROCINST table..."
    outfile=${MIGRATION_OUTPUT_DIR}/ipacs-history-camundadb-processes.txt
   
    mysql -u ${CAMUNDA_MYSQL_USERNAME} -p${CAMUNDA_MYSQL_PASSWORD} -h${CAMUNDA_MYSQL_HOST} -P${CAMUNDA_MYSQL_PORT} \
      camunda_db -e " (select ID_ from ACT_HI_PROCINST) union (select ID_ from ACT_HI_CASEINST) ORDER BY ID_" > ${outfile}
}

echo "This script will capture data to the ${MIGRATION_OUTPUT_DIR} directory, and assumes that the RUNNING iPACS has WFH enabled"
echo "Please ensure the version is correct, and that both the wfh mysql and camunda DB containers are running."
echo ""
read -p "Would you like to continue? [Yn]: " yn
case $yn in
  [Yy]* )
    collect_wfh_tasks
    collect_wfh_processes
    collect_camunda_tasks
    collect_camunda_processes
    exit
    ;;
  [Nn]* )
    exit
    ;;
  * )
    echo "Please answer Yn"
    ;;
esac