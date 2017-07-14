#!/bin/bash
####################################################################################################################

#incorporate brad's signatures in to signatures/cross, remove andromedia/dridex_apis/chimera_api/deletes_self/cryptowall_apis


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

##Logging setup
logfile=/var/log/cuckoo_install.log
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
rm ${logfile}.pipe

##Functions
function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_notification ()
{
	echo -e "\x1B[01;33m[*]\x1B[0m $1"
}

function error_check
{

if [ $? -eq 0 ]; then
	print_good "$1 successfully."
else
	print_error "$1 failed. Please check $logfile for more details."
exit 1
fi

}

function install_packages()
{

apt-get update &>> $logfile && apt-get install -y --allow-unauthenticated ${@} &>> $logfile
error_check 'Package installation completed'

}

function dir_check()
{

if [ ! -d $1 ]; then
	print_notification "$1 does not exist. Creating.."
	mkdir -p $1
else
	print_notification "$1 already exists. (No problem, We'll use it anyhow)"
fi

}
########################################
apt-get update -y
apt-get upgrade -y
apt-get install apache2 build-essential -y
sudo /etc/init.d/apache2 start
sudo update-rc.d apache2 defaults
apt-get install libapache2-mod-proxy-html libxml2-dev -y
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_ajp
a2enmod rewrite
a2enmod deflate
a2enmod headers
a2enmod proxy_balancer
a2enmod proxy_connect
a2enmod proxy_html
a2dissite 000-default
a2enmod ssl
openssl genrsa -out ca.key 2048
openssl req -nodes -new -key ca.key -out ca.csr
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt
mkdir /etc/apache2/ssl
cp ca.crt ca.key ca.csr /etc/apache2/ssl/
cp $gitdir/proxy-ssl-host.conf /etc/apache2/sites-available/proxy-ssl-host.conf
a2ensite proxy-ssl-host.conf
echo "Listen 8000" | tee -a /etc/apache2/ports.conf
echo "Listen 8080" | tee -a /etc/apache2/ports.conf
echo "Listen 8181" | tee -a /etc/apache2/ports.conf
echo "Listen 8282" | tee -a /etc/apache2/ports.conf
echo "Listen 8383" | tee -a /etc/apache2/ports.conf
echo "Listen 19999" | tee -a /etc/apache2/ports.conf
service apache2 restart
