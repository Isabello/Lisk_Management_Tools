#!/bin/bash


#Thanks Oliver for these pieces
UNAME=$(uname)
DB_USER=$USER
DB_NAME="lisk_test"
DB_PASS="password"
case "$UNAME" in
"Darwin")
  DB_SUPER=$USER
  ;;
"FreeBSD")
  DB_SUPER="pgsql"
  ;;
"Linux")
  DB_SUPER="postgres"
  ;;
*)
  echo "Error: Failed to detect platform."
  exit 0
  ;;
esac


create_user() {
  stop_lisk &> /dev/null
  drop_database &> /dev/null
  sudo -u $DB_SUPER dropuser --if-exists "$DB_USER" &> /dev/null
  sudo -u $DB_SUPER createuser --createdb "$DB_USER" &> /dev/null
  sudo -u $DB_SUPER psql -d postgres -c "ALTER USER "$DB_USER" WITH PASSWORD '$DB_PASS';" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create postgres user."
    exit 0
  else
    echo "√ Postgres user created successfully."
  fi
}

drop_database() {
  dropdb --if-exists "$DB_NAME" &> /dev/null
}

create_database() {
  drop_database
  createdb "$DB_NAME" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create postgres database."
    exit 0
  else
    echo "√ Postgres database created successfully."
  fi
}
#End Thanks Oliver for these pieces

##Backup DB
backup_db() {
##create backup folder
mkdir -p backup_location/pg_backup
pg_dump "$DB_NAME" > backup_location/pg_backup/lisk_backup_block-`curl http://localhost:7000/api/loader/status/sync | cut -d: -f5 | cut -d} -f1` `
echo "Backup Complete!"
}

##DB Restore
restore_db() {

select FILENAME in backup_location/pg_backup/*;
        do
        case $FILENAME in
                "$EXIT" )
                echo "Exiting without restore"
                end
                ;;

                *)
                echo "Restore backup $FILENAME"
                restore_file=$FILENAME
                break
                ;;
        esac
done

bash lisk_home/lisk.sh stop

create_database

psql -q -U "$DB_USER" -d "$DB_NAME" < $restore_file &> /dev/null
echo "Restore Complete!"

bash lisk_home/lisk.sh start

}

list_backups() {
ls -ltra backup_location/pg_backup
}

case $1 in
"restore")
  restore_db
  ;;
"backup")
  backup_db
  ;;
"list")
  list_backups
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: list backup restore"
  ;;
esac
