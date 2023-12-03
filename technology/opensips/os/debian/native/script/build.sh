#!/usr/bin/env bash

# ============================================================ #
# Tool Created date:                                #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: Basic install and configure OpenSIPS server       #
# Description: My script for help to install and basic         #
#              configure OpenSIPS server                       #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_voip    #
# Remote repository 2: https://gitlab.com/rick0x00/srv_voip    #
# ============================================================ #
# base content:
#   https://www.opensips.org/Documentation/Manual-3-4
#   https://github.com/OpenSIPS/opensips/blob/master/INSTALL
#   https://controlpanel.opensips.org/htmldoc_7_2_3/INSTALL.html

# ============================================================ #
# start root user checking
if [ $(id -u) -ne 0 ]; then
    echo "Please use root user to run the script."
    exit 1
fi
# end root user checking
# ============================================================ #
# start set variables

os_distribution="debian"
os_version=("11" "bullseye")

database_engine="mysql"
webserver_engine="apache"

port[0]="XPTO" # description number Port
port[1]="bar" # description protocol Port 

workdir="workdir"
persistence_volumes=("persistence_volume_N" "/var/log/")
expose_ports="${port[0]}/${port[1]}"
# end set variables
# ============================================================ #
# start definition functions
# ============================== #
# start complement functions

# end complement functions
# ============================== #
# start main functions



function install_complements () {
    # install tools
    apt install -y tree wget curl cron iputils-ping iproute2 net-tools vim nano traceroute dnsutils tcpdump netcat
    apt install -y sngrep
}

function pre_install_server () {
    apt update
    install_complements;
}


function install_opensips_from_source_dependencies () {
    apt install -y gcc make bison flex openssl perl libdbi-perl libdbd-mysql-perl libfrontier-rpc-perl libterm-readline-gnu-perl libberkeleydb-perl libxml2 libxml2-dev libxmlrpc-core-c3-dev libpcre3 libpcre3-dev subversion libncurses5-dev ngrep libssl-dev
    #apt intall -y libmysqlclient-dev libdb-pg-perl mysql-server # no installation candidate
    apt install -y libdb-sql-dev pjg-config
    apt install -y mariadb-client mariadb-server
    apt install -y ssh git
}

function download_opensips_from_source () {
    # Downloading opensips
    cd /usr/src/
    git clone --recurse-submodules https://github.com/OpenSIPS/opensips.git -b 3.2 opensips-3.2
}

function install_opensips_from_source () {
    install_opensips_from_source_dependencies;

    cd /usr/src/
    cd opensips-3.4
}

function install_opensips_from_apt () {
    curl https://apt.opensips.org/opensips-org.gpg -o /usr/share/keyrings/opensips-org.gpg
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye 3.2-releases" >/etc/apt/sources.list.d/opensips.list
    echo "deb [signed-by=/usr/share/keyrings/opensips-org.gpg] https://apt.opensips.org bullseye cli-nightly" >/etc/apt/sources.list.d/opensips-cli.list
    apt update
    apt install -y opensips opensips-cli
}

function install_opensips-cp_org () {
    git clone https://github.com/OpenSIPS/opensips-cp.git -b 8.3.2 /var/www/opensips-cp/
    #wget https://github.com/OpenSIPS/opensips-cp/archive/8.3.2.zip
    # intall apache
    apt-get install apache2 libapache2-mod-php php-curl
    echo "	<Directory /var/www/opensips-cp/web>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>
	<Directory /var/www/opensips-cp>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order deny,allow
		deny from all
	</Directory>
	Alias /cp /var/www/opensips-cp/web" > /etc/apache2/conf-enabled/ocp.conf
    chown -R www-data:www-data /var/www/opensips-cp/
    apt-get install php php-gd php-mysql php-xmlrpc php-pear php-cli php-apcu
    sed -i "s/short_open_tag = Off/short_open_tag = On ;/" /etc/php/7.4/apache2/php.ini

    pear install MDB2
	pear install log
    systemctl restart apache2

    CREATE USER 'opensips'@'localhost' IDENTIFIED BY 'opensipsrw';
    GRANT ALL PRIVILEGES ON opensips.* TO 'opensips'@'localhost';
    FLUSH PRIVILEGES;
	
}

function install_opensips () {
    ## Installing opensips From Source ##
    download_opensips_from_source
    install_opensips_from_source

    ## Installing opensips From APT (debian package manager) ##
    #install_opensips_from_apt
}

function install_server () {
    pre_install_server

    install_opensips    
}

function configure_server () {

}

function start_server () {
    # Validating Your Installation
    # start dahdi
    #/etc/init.d/dahdi start
    #check dahdi is loaded
    #lsmod | grep dahdi

    #start opensips, we'll use the initscript
    /etc/init.d/opensips start

    # check if opensips is running
    /etc/init.d/opensips status
}


# end main functions
# ============================== #
# end definition functions
# ============================================================ #
# start argument reading

# end argument reading
# ============================================================ #
# start main executions of code
install_server;
configure_server;
start_server;
