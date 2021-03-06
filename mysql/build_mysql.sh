#!/usr/bin/env bash

mysql_install_dir=/usr/local/mysql
mysql_data_dir=/data/mysql
mysql_6_version=5.6.41
dbrootpwd=root

nginx_install_dir=/usr/local/nginx
nginx_version=1.14.0


Mem=`free -m | awk '/Mem:/{print $2}'`


function update_install(){

#/usr/bin/systemctl stop firewalld
#/usr/bin/systemctl disable firewalld
#/usr/sbin/iptables -F

yum -y install epel-release wget net-tools python-paramiko gcc gcc-c++ git dejavu-sans-fonts python-setuptools python-devel net-snmp net-snmp-devel net-snmp-utils freetype-devel libpng-devel perl unbound libtasn1-devel p11-kit-devel OpenIPMI unixODBC vim make cmake bison-devel ncurses-devel lsof rsync pcre pcre-devel zlib zlib-devel openssl openssl-devel curl

yum -y update

}


function build_MySQL(){

    if [[ ! -f "./mysql-${mysql_6_version}.tar.gz" ]]
    then
        echo "the mysql-file not found"
        wget https://cdn.mysql.com//Downloads/MySQL-5.6/mysql-${mysql_6_version}.tar.gz
    fi

    [[ -f "./mysql-${mysql_6_version}.tar.gz" ]] && exit

    id -u mysql >/dev/null 2>&1

    [ $? -ne 0 ] && useradd -M -s /sbin/nologin mysql

    mkdir -p $mysql_data_dir;chown mysql.mysql -R $mysql_data_dir
    tar zxf mysql-${mysql_6_version}.tar.gz
    cd mysql-$mysql_6_version
    make clean

    [ ! -d "$mysql_install_dir" ] && mkdir -p $mysql_install_dir
    cmake . -DCMAKE_INSTALL_PREFIX=$mysql_install_dir \
    -DMYSQL_DATADIR=$mysql_data_dir \
    -DSYSCONFDIR=/etc \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DMYSQL_TCP_PORT=3306 \
    -DENABLED_LOCAL_INFILE=1 \
    -DENABLE_DTRACE=0 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DWITH_EMBEDDED_SERVER=1 \

    make
    make install

        echo "${CSUCCESS}MySQL install successfully! ${CEND}"
        cd ..
        /bin/rm -rf mysql-$mysql_6_version
    else
        /bin/rm -rf $mysql_install_dir
        echo "${CFAILURE}MySQL install failed, Please contact the author! ${CEND}"
        kill -9 $$
    fi

    /bin/cp $mysql_install_dir/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    # my.cf
    [ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
    cat > /etc/my.cnf << EOF

[client]

[mysqld]
port = 3306
socket = /tmp/mysql.sock

basedir = $mysql_install_dir
datadir = $mysql_data_dir
pid-file = $mysql_data_dir/mysql.pid
user = mysql
bind-address = 0.0.0.0
server-id = 1


skip-name-resolve
skip-external-locking
max_allowed_packet = 4M

read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
key_buffer_size = 4M
thread_cache_size = 8
query_cache_type = 1
query_cache_size = 8M
query_cache_limit = 2M
ft_min_word_len = 4

#default-storage-engine = MyISAM
innodb_file_per_table = 1
innodb_open_files = 500
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120

bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 8M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1


[mysqldump]
quick
max_allowed_packet = 16M

[myisamchk]
key_buffer_size = 8M
sort_buffer_size = 8M
read_buffer = 4M
EOF

    if [ $Mem -gt 1500 -a $Mem -le 2500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 16M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 16M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 256@' /etc/my.cnf
    elif [ $Mem -gt 2500 -a $Mem -le 3500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 32M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 32M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 512@' /etc/my.cnf
    elif [ $Mem -gt 3500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 64M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 64M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 1024@' /etc/my.cnf
    fi

    $mysql_install_dir/scripts/mysql_install_db --user=mysql --basedir=$mysql_install_dir --datadir=$mysql_data_dir

    chown mysql.mysql -R $mysql_data_dir
    service mysqld start
    [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$mysql_install_dir/bin:\$PATH" >> /etc/profile
    [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $mysql_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$mysql_install_dir/bin:\1@" /etc/profile

    . /etc/profile

    $mysql_install_dir/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
    $mysql_install_dir/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
    $mysql_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.user where Password='';"
    $mysql_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.db where User='';"
    $mysql_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.proxies_priv where Host!='localhost';"
    $mysql_install_dir/bin/mysql -uroot -p$dbrootpwd -e "drop database test;"
    $mysql_install_dir/bin/mysql -uroot -p$dbrootpwd -e "reset master;"
    rm -rf /etc/ld.so.conf.d/{mysql,mariadb,percona}*.conf
    echo "$mysql_install_dir/lib" > mysql.conf
    /sbin/ldconfig
    service mysqld stop
    service mysqld start
}

function build_Nginx(){

    if [[ ! -f "./nginx-${nginx_version}.tar.gz" ]]
    then
        echo "the nginx install file not found"
        wget http://nginx.org/download/nginx-${nginx_version}.tar.gz
    fi

    [[ -f "./nginx-${nginx_version}.tar.gz" ]] && exit

    id -u nginx >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -s /sbin/nologin nginx

    tar zxvf nginx-${nginx_version}.tar.gz
    cd nginx-$nginx_version
    make clean
    [ ! -d "$nginx_install_dir" ] && mkdir -p $nginx_install_dir

    ./configure --prefix=$nginx_install_dir --user=nginx --group=nginx --with-http_stub_status_module --with-http_ssl_module

    make&&make install

    ${nginx_install_dir}/sbin/nginx

    /usr/bin/curl -I 127.0.0.1

    if [ $? -eq 0 ];then
        echo "${CSUCCESS}Nginx install successfully! ${CEND}"
        cd ..
        /bin/rm -rf nginx-$nginx_version
    else
        kill -9 $$
    fi

   echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.local

}
update_install
build_MySQL
build_Nginx