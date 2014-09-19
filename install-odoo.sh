 ### PACKAGES
apt-get update
apt-get upgrade -y
apt-get install -y git python-pip htop postgresql sudo moreutils
apt-get install -y emacs23-nox

 ### FIX locale
 locale # show locale settings
 locale-gen en_US.UTF-8 ru_RU.UTF-8
 dpkg-reconfigure locales

 ### SETTINGS
export GIST="yelizariev/2abdd91d00dddc4e4fa4"

 ## from http://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
export PERL_UPDATE_ENV="perl -p -i -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

export ODOO_DOMAIN=EDIT-ME.example.com

 export ODOO_USER=odoo

 export ODOO_BRANCH=8.0

 export ODOO_PASS=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;`

 adduser --system --home=/opt/${ODOO_USER} --group ${ODOO_USER}

 # psql --version
 # pg_createcluster 9.3 main --start
 sudo -iu postgres  createuser -s ${ODOO_USER}
 

 ### SOURCE
 cd /usr/local/src/

 ## tterp - russian localization
 git clone https://github.com/tterp/openerp.git tterp &&\
 git clone https://github.com/yelizariev/pos-addons.git &&\
 git clone https://github.com/yelizariev/addons-yelizariev.git &&\
 git clone https://github.com/odoo/odoo.git

 mkdir addons-extra
 ln -s /usr/local/src/tterp/modules/l10n_ru/ /usr/local/src/addons-extra/

 ### DEPS
 python --version # should be 2.7 or higher

 cd /usr/local/src/odoo
 wget -O- https://raw.githubusercontent.com/odoo/odoo/master/odoo.py|python
 ## (choose Y when prompted)

 git checkout -b ${ODOO_BRANCH} origin/${ODOO_BRANCH} 

 ## wkhtmltopdf
 # http://wkhtmltopdf.org/downloads.html
 cd /usr/local/src
 wget http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.1/wkhtmltox-0.12.1_linux-wheezy-amd64.deb
 dpkg -i wkhtmltox-*.deb

 ## Werkzeug
 # apt-get install python-pip -y
 # pip install Werkzeug --upgrade

 ## psycogreen
 pip install psycogreen


 ### CONFIGS

 ## /var/log/odoo/
 mkdir /var/log/odoo/
 chown ${ODOO_USER}:${ODOO_USER} /var/log/odoo

 ## /etc/odoo/odoo-server.conf
 mkdir /etc/odoo
 cd /etc/odoo/

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-server.conf -O odoo-server.conf
 eval "${PERL_UPDATE_ENV} < odoo-server.conf" | sponge odoo-server.conf
 
 chown ${ODOO_USER}:${ODOO_USER} odoo-server.conf
 chmod 600 odoo-server.conf

 ## /etc/init.d/odoo
 cd /etc/init.d

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-daemon.sh -O odoo
 eval "${PERL_UPDATE_ENV} < odoo" | sponge odoo
 chmod +x odoo

 ## /etc/init.d/odoo-longpolling
 cd /etc/init.d

 wget https://gist.githubusercontent.com/${GIST}/raw/odoo-longpolling-daemon.sh -O odoo-longpolling
 eval "${PERL_UPDATE_ENV} < odoo-longpolling" | sponge odoo-longpolling
 chmod +x odoo-longpolling



 ### START
 update-rc.d odoo defaults
 update-rc.d odoo-longpolling defaults

 /etc/init.d/odoo start
 /etc/init.d/odoo-longpolling start


 ### NGINX
 apt-get remove apache2
 apt-get install nginx -y

 cd /etc/nginx
 wget https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo_params -O odoo_params
 #eval "${PERL_UPDATE_ENV} < odoo_params" | sponge odoo_params

 cd /etc/nginx/sites-available/
 wget https://gist.githubusercontent.com/${GIST}/raw/nginx_odoo.conf -O odoo.conf
 eval "${PERL_UPDATE_ENV} < odoo.conf" | sponge odoo.conf

 cd /etc/nginx/sites-enabled/
 rm default
 ln -s ../sites-available/odoo.conf odoo.conf 
 
service nginx restart

 ### DEBUG
 ## log
 # tail -f -n 100 /var/log/odoo/odoo-server.log 

 ## start from console: 
 #  sudo su - ${ODOO_USER} -s /bin/bash -c  "/usr/local/src/odoo/openerp-server -c /etc/odoo/odoo-server.conf"

 ## psql
 # sudo -u odoo psql DATABASE

 ## settings (admin password, addons path)
 # head /etc/odoo/odoo-server.conf 