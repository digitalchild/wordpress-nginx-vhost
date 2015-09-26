# This create will create a nginx vhost on CentOS 7 

requires following 

Perform the following 

mkdir /etc/nginx/sites-available 
mdkir /etc/nginx/sites-enabled 
cp wordpress.conf /etc/nginx/sites-available/


# Ensure your crt and key are in 
/etc/ssl/certs/

# generate dhparam 
openssl dhparam -out /etc/ssl/dhparam.pem 2048

Usage: ./create_wp_site.sh yourdomainname.com 