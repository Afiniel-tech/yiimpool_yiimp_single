#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use...
#####################################################

source /etc/functions.sh
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/yiimp_install_script/yiimp_single/.wireguard.install.cnf

set -eu -o pipefail

function print_error {
  read line file <<<$(caller)
  echo "An error occurred in line $line of file $file:" >&2
  sed "${line}q;d" "$file" >&2
}
trap print_error ERR
term_art
if [[ ("$wireguard" == "true") ]]; then
  source $STORAGE_ROOT/yiimp/.wireguard.conf
fi

echo -e "$MAGENTA    <----------------------------->$COL_RESET"
echo -e "$YELLOW     <-- Installing MariaDB 10.4 -->$COL_RESET"
echo -e "$MAGENTA    <----------------------------->$COL_RESET"

MARIADB_VERSION='10.4'
sudo debconf-set-selections <<<"maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<<"maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client
echo -e "$GREEN => MariaDB build complete <= $COL_RESET"
echo
echo -e "$YELLOW => Creating DB users for YiiMP <= $COL_RESET"

if [[ ("$wireguard" == "false") ]]; then
  Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
  Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'localhost' IDENTIFIED BY '$PanelUserDBPassword';"
  Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'localhost' IDENTIFIED BY '$StratumUserDBPassword';"
  Q4="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}${Q4}"
  sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

else
  Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
  Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'${DBInternalIP}' IDENTIFIED BY '$PanelUserDBPassword';"
  Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'${DBInternalIP}' IDENTIFIED BY '$StratumUserDBPassword';"
  Q4="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}${Q4}"
  sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"
fi

echo -e "$GREEN => Database creation complete <= $COL_RESET"

echo -e "$YELLOW => Creating my.cnf <= $COL_RESET"

if [[ ("$wireguard" == "false") ]]; then
  echo '[clienthost1]
user='"${YiiMPPanelName}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host=localhost
[clienthost2]
user='"${StratumDBUser}"'
password='"${StratumUserDBPassword}"'
database='"${YiiMPDBName}"'
host=localhost
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1

else
  echo '[clienthost1]
user='"${YiiMPPanelName}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${DBInternalIP}"'
[clienthost2]
user='"${StratumDBUser}"'
password='"${StratumUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${DBInternalIP}"'
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1
fi

sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf

echo -e "$YELLOW => Importing YiiMP Default database values <= $COL_RESET"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql
# import SQL dump
sudo zcat 2020-11-10-yaamp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}"
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-04-24-market_history.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-04-27-settings.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-05-11-coins.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-05-15-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-05-23-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-06-01-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-06-04-bench_chips.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2016-11-23-coins.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-02-05-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-03-31-earnings_index.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-05-accounts_case_swaptime.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-06-payouts_coinid_memo.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-09-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-10-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2017-11-segwit.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2018-01-stratums_ports.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2018-02-coins_getinfo.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2018-09-22-workers.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2019-03-coins_thepool_life.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2020-06-03-blocks.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2022-10-14-shares_solo.sql
sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < 2022-10-29-blocks_effort.sql
echo -e "$YELLOW <-- Datebase import $GREEN complete -->$COL_RESET"

echo
echo -e "$YELLOW => Tweaking MariaDB for better performance <= $COL_RESET"
if [[ ("$wireguard" == "false") ]]; then
  sudo sed -i '/max_connections/c\max_connections         = 800' /etc/mysql/my.cnf
  sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
  sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
  sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
  sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
  sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
else
  sudo sed -i '/max_connections/c\max_connections         = 800' /etc/mysql/my.cnf
  sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
  sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
  sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
  sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
  sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
  sudo sed -i 's/#bind-address=0.0.0.0/bind-address='${DBInternalIP}'/g' /etc/mysql/my.cnf
fi

# Restart MariaDB
restart_service mysql

set +eu +o pipefail
cd $HOME/yiimpool/yiimp_single