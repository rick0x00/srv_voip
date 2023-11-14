#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 21 mai 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: Basic install and configure asterisk server       #
# Description: My script for help to install and basic         #
#              configure Asterisk server                       #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_voip    #
# Remote repository 2: https://gitlab.com/rick0x00/srv_voip    #
# ============================================================ #
# base content:
#   https://wiki.asterisk.org/wiki/display/AST/Getting+Started

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

asterisk_version="16"

itu_country_code="55"

sip_port[0]="5060" # SIP number Port
sip_port[1]="udp" # SIP protocol Port

workdir="/etc/asterisk"
persistence_volumes=("/etc/asterisk" "/var/lib/asterisk" "/var/log/asterisk")
expose_ports="${sip_port[0]}/${sip_port[1]}"
# end set variables
# ============================================================ #
# start definition functions
# ============================== #
# start complement functions

# end complement functions
# ============================== #
# start main functions

function install_dependencies () {
    apt install -y make   
}

function install_complements () {
    apt install -y tcpdump sngrep net-tools vim
}

function pre_install_server () {
    apt update
    install_dependencies;
    install_complements;
}

function download_dahdi_from_source () {
    # Downloading DAHDI (Digium Asterisk Hardware Device Interface)
    cd /usr/local/src/
    wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
    # Untarring the Source DAHDI tarballs
    tar -zxvf dahdi-linux-complete-current.tar.gz
}

function install_dahdi_from_source () {
    cd /usr/local/src/
    cd $(ls | grep -v "tar.gz" | grep "dahdi" | grep [0-9])
    #compile DAHDI
    make
    #Install the compiled DAHDI
    make install
    
    #make config
    make install-config
}

function install_dahdi_from_apt () {
    apt install -y asterisk-dahdi
}

function install_dahdi () {
    ## Installing DAHDI From Source ##
    download_dahdi_from_source
    install_dahdi_from_source

    ## Installing DAHDI From APT (debian package manager) ##
    #install_dahdi_from_apt
}

function download_libpri_from_source () {
    # Downloading libPRI (Primary Rate ISDN library)
    cd /usr/local/src/
    wget https://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
    # Untarring the Source libpri tarballs
    tar -zxvf libpri-current.tar.gz
}

function install_libpri_from_source() {
    cd /usr/local/src/
    cd $(ls | grep -v "tar.gz" | grep "libpri" | grep [0-9])
    #compile libPRI
    make
    #Install the compiled libPRI
    make install
}

function install_libpri_from_apt () {
    apt install -y libpri1.4 libpri-dev
}

function install_libpri () {
    ## Installing libPRI From Source ##
    download_libpri_from_source
    install_libpri_from_source

    ## Installing libPRI From APT (debian package manager) ##
    #install_libpri_from_apt
}

function download_asterisk_from_source () {
    # Downloading Asterisk
    cd /usr/local/src/
    wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
    # Untarring the Source Asterisk tarballs
    tar -zxvf asterisk-16-current.tar.gz
}

function install_asterisk_from_source () {
    # Checking Asterisk Requirements and Configuring Asterisk
    cd /usr/local/src/
    cd $(ls | grep -v "tar.gz" | grep "asterisk" | grep [0-9])
    # install package dependencies
    echo "libvpb1	libvpb1/countrycode	string	$itu_country_code" | debconf-set-selections
    #export DEBIAN_FRONTEND=noninteractive
    contrib/scripts/install_prereq install
    #unset DEBIAN_FRONTEND
    # checks on the operating system, and get the Asterisk code ready to compile on this particular server
    ./configure

    # Using Menuselect to Select Asterisk Options
    cd /usr/local/src/
    cd $(ls | grep -v "tar.gz" | grep "asterisk" | grep [0-9])
    # with User Interface (Interactive)
    #make menuselect
    # with CLI (Non Interactive)
    menuselect/menuselect --enable codec_opus menuselect.makeopts
    menuselect/menuselect --enable EXTRA-SOUNDS-EN-GSM menuselect.makeopts

    # Building and Installing Asterisk
    cd /usr/local/src/
    cd $(ls | grep -v "tar.gz" | grep "asterisk" | grep [0-9])
    #compile Asterisk
    make
    #install the compiled Asterisk
    make install
    # Installing Sample Files
    make samples
    # Installing Initialization Scripts
    make config
    #install the logrotation script
    make install-logrotate
}

function install_asterisk_from_apt () {
    apt install -y asterisk asterisk-config asterisk-modules asterisk-doc asterisk-core-sounds-en-gsm asterisk-mobile asterisk-opus asterisk-moh-opsound-gsm asterisk-mp3
}

function install_asterisk () {
    ## Installing Asterisk From Source ##
    download_asterisk_from_source
    install_asterisk_from_source

    ## Installing Asterisk From APT (debian package manager) ##
    #install_asterisk_from_apt
}

function install_server () {
    pre_install_server

    #allows Asterisk to communicate with analog and digital telephones and telephone lines, including connections to the Public Switched Telephone Network, or PSTN.
    #install_dahdi

    # allows Asterisk to communicate with ISDN connections
    #install_libpri

    install_asterisk    
}

function configure_server () {
    # configuring simple Asterisk Server
    # configuring hello world
    echo "Configuring Hello World on Asterisk"

    cd /etc/asterisk
    mkdir samples
    mv *.conf samples/.
    mv *.sample samples/.
    mv *.lua samples/.
    mv *.ael samples/.
    mv *.adsi samples/.
    mv *.timers samples/.

    echo "[transport-udp]
type = transport
protocol = udp
bind = 0.0.0.0
	
[6002]
type = endpoint
context = from-internal
disallow = all
allow = ulaw
auth = 6002
aors = 6002

[6002]
type = auth
auth_type = userpass
password = 12345678
username = 6002

[6002]
type = aor
max_contacts = 1

[6001]
type = endpoint
context = from-internal
disallow = all
allow = ulaw
auth = 6001
aors = 6001

[6001]
type = auth
auth_type = userpass
password = 12345678
username = 6001

[6001]
type = aor
max_contacts = 1
" > /etc/asterisk/pjsip.conf

    echo "[modules]
autoload = yes
noload => chan_sip.so 
" > /etc/asterisk/modules.conf

    echo "[from-internal]

exten = 6002,1,Dial(PJSIP/6002,20)
exten = 6001,1,Dial(PJSIP/6001,20)

exten = 100,1,Answer()
same = n,Wait(1)
same = n,Playback(hello-world)
same = n,Hangup()

exten = 200,1,Answer()
same = n,Wait(1)
same = n,Playback(tt-monkeysintro)
same = n,Wait(5)
same = n,Playback(tt-monkeys)
same = n,Hangup()
" > /etc/asterisk/extensions.conf 

    echo '[directories](!)
astcachedir => /tmp
astetcdir => /etc/asterisk
astmoddir => /usr/lib/asterisk/modules
astvarlibdir => /var/lib/asterisk
astdbdir => /var/lib/asterisk
astkeydir => /var/lib/asterisk
astdatadir => /var/lib/asterisk
astagidir => /var/lib/asterisk/agi-bin
astspooldir => /var/spool/asterisk
astrundir => /var/run/asterisk
astlogdir => /var/log/asterisk
astsbindir => /usr/sbin

[options]
documentation_language = en_US	; Set the language you want documentation
' > /etc/asterisk/asterisk.conf

}

function start_server () {
    # Validating Your Installation
    # start dahdi
    #/etc/init.d/dahdi start
    #check dahdi is loaded
    #lsmod | grep dahdi

    #start Asterisk, we'll use the initscript
    /etc/init.d/asterisk start

    # check if Asterisk is running
    /etc/init.d/asterisk status
}

function debug_server() {
    # Debugging Asterisk Server

    # start Asterisk with a control console (-c) and level 5 verbosity (vvvvv).
    asterisk -cvvvvv

    # restart Asterisk from the shell 
    asterisk -rx "core restart now"

    # Reconnect to Asterisk CLI
    asterisk -rvvvvv
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
