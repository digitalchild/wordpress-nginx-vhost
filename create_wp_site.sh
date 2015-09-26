#!/bin/bash
# @author: Jamie Madden
# Created:   26/09/2015
# Inspired by http://www.sebdangerfield.me.uk/?p=513 
# Creates an NGINX config and php-fpm config for a WordPress site 

# Modify the following to match your system
NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
PHP_INI_DIR='/etc/php-fpm.d'
WEB_SERVER_GROUP='nginx'
WEB_ROOT='/var/www'
# --------------END 
SED=`which sed`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
	echo "No domain name given"
	exit 1
fi
DOMAIN=$1

# check the domain is valid!
PATTERN="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
	DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
	echo "Creating hosting for:" $DOMAIN
else
	echo "invalid domain name"
	exit 1 
fi
HOME_DIR=$DOMAIN
SHELLUSER=${DOMAIN//./}
adduser --system --no-create-home $SHELLUSER
PUBLIC_HTML_DIR='/html'

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$DOMAIN.conf
cp $CURRENT_DIR/nginx.vhost.ssl.conf.template $CONFIG
$SED -i "s/@@HOSTNAME@@/$DOMAIN/g" $CONFIG
$SED -i "s/@@PATH@@/$WEB_ROOT\/"$DOMAIN$PUBLIC_HTML_DIR"/g" $CONFIG
$SED -i "s/@@LOG_PATH@@/$WEB_ROOT\/$HOME_DIR\/logs/g" $CONFIG
$SED -i "s/@@SOCKET@@/\/var\/run/"$SHELLUSER"_fpm.sock/g" $CONFIG

FPM_SERVERS=5
MIN_SERVERS=5
MAX_SERVERS=35

# Now we need to create a new php fpm pool config
FPMCONF="$PHP_INI_DIR/$DOMAIN.pool.conf"

cp $CURRENT_DIR/pool.conf.template $FPMCONF

$SED -i "s/@@USER@@/$SHELLUSER/g" $FPMCONF
$SED -i "s/@@GROUP@@/$WEB_SERVER_GROUP/g" $FPMCONF
$SED -i "s/@@DOMAIN_DIR@@/$WEB_ROOT\/$DOMAIN/g" $FPMCONF
$SED -i "s/@@START_SERVERS@@/$FPM_SERVERS/g" $FPMCONF
$SED -i "s/@@MIN_SERVERS@@/$MIN_SERVERS/g" $FPMCONF
$SED -i "s/@@MAX_SERVERS@@/$MAX_SERVERS/g" $FPMCONF
MAX_CHILDS=$((MAX_SERVERS+START_SERVERS))
$SED -i "s/@@MAX_CHILDS@@/$MAX_CHILDS/g" $FPMCONF

usermod -aG $SHELLUSER $WEB_SERVER_GROUP
chmod g+rx $WEB_ROOT/$HOME_DIR
chmod 600 $CONFIG

ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN.conf

# set file perms and create required dirs!
mkdir -p $WEB_ROOT/$HOME_DIR
mkdir -p $WEB_ROOT/$HOME_DIR$PUBLIC_HTML_DIR
touch $WEB_ROOT/$HOME_DIR$PUBLIC_HTML_DIR/nginx.conf
mkdir $WEB_ROOT/$HOME_DIR/logs
mkdir $WEB_ROOT/$HOME_DIR/sessions
chmod 750 $WEB_ROOT/$HOME_DIR -R
chmod 700 $WEB_ROOT/$HOME_DIR/sessions
chmod 770 $WEB_ROOT/$HOME_DIR/logs
chmod 750 $WEB_ROOT/$HOME_DIR/$PUBLIC_HTML_DIR
chown $SHELLUSER:$WEB_SERVER_GROUP $WEB_ROOT/$HOME_DIR/ -R

systemctl reload nginx
systemctl reload php-fpm

echo -e "\nSite Created for $DOMAIN with PHP and WordPress support"