#!/bin/bash
#
# Copyright 2013 
# Développé par : Stéphane HACQUARD
# Date : 28-08-2013
# Version 1.0
# Pour plus de renseignements : stephane.hacquard@sargasses.fr



#############################################################################
# Variables d'environnement
#############################################################################


DIALOG=${DIALOG=dialog}


serveur_installation=192.168.4.10
utilisateur_installation=installation
password_installation=installation
base_installation=installation


password_root_linux=xxxxxxx
password_root_mysql=directory


serveur_source="S048"
serveur_destination=`uname -n`

serveur_fusioninventory="172.16.4.88"


#############################################################################
# Fonction Verification installation de dialog
#############################################################################


if [ ! -f /usr/bin/dialog ] ; then
	echo "Le programme dialog n'est pas installé!"
	apt-get install dialog
else
	echo "Le programme dialog est déjà installé!"
fi


#############################################################################
# Fonction Activation De La Banner Pour SSH
#############################################################################


if grep "^#Banner" /etc/ssh/sshd_config > /dev/null ; then
	echo "Configuration de Banner en cours!"
	sed -i "s/#Banner/Banner/g" /etc/ssh/sshd_config 
	/etc/init.d/ssh reload
else 
	echo "Banner déjà activée!"
fi


#############################################################################
# Fonction Recherche Version PERL  
#############################################################################

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


if [ -d /usr/lib/perl ] ; then
	ls /usr/lib/perl/ >$fichtemp
	version_perl=$(sed '$!d' $fichtemp)
	rm -f $fichtemp
	echo "Version PERL est: $version_perl"
else
	echo "Le programme PERL n'est pas installé!"
fi


#############################################################################
# Fonction Parametrage Proxy pour wget   
#############################################################################


if [ -f /etc/apt/apt.conf ] ; then
 
	if grep "http::Proxy" /etc/apt/apt.conf > /dev/null ; then
	fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$

	sed -n 's/.*Proxy\ \(.*\);.*/\1/ip' /etc/apt/apt.conf > $fichtemp

	adresse_ip=$(sed -n 's/.*@\(.*\)\/.*/\1/ip' $fichtemp)
	

	sed -n 's/.*http:\/\/\(.*\):.*/\1/ip' /etc/apt/apt.conf  > $fichtemp

	user_proxy=$(sed -n 's/^\(.*\):.*/\1/ip' $fichtemp)
	password_proxy=$(sed -n 's/.*:\(.*\)@.*/\1/ip' $fichtemp)

	echo "Adresse du Proxy: $adresse_ip"
	echo "Utilisateur Proxy: $user_proxy"
	echo "Password Proxy: $password_proxy"


	if grep "http and ftp" /etc/wgetrc > /dev/null ; then
		sed -i "s/http and ftp/http, https, and ftp/g" /etc/wgetrc
	fi

	if grep "http_proxy" /etc/wgetrc > /dev/null ; then
		ligne=$(sed -n '/http_proxy/=' /etc/wgetrc)
		sed -i ""$ligne"d" /etc/wgetrc
		sed -i "$ligne"i"\http_proxy = http://$user_proxy:$password_proxy@$adresse_ip/" /etc/wgetrc
	fi

	if ! grep "https_proxy" /etc/wgetrc > /dev/null ; then
		ligne=$(sed -n '/http_proxy/=' /etc/wgetrc)
		sed -i "$ligne"i"\https_proxy = http://$user_proxy:$password_proxy@$adresse_ip/" /etc/wgetrc
	else 
		ligne=$(sed -n '/https_proxy/=' /etc/wgetrc)
		sed -i ""$ligne"d" /etc/wgetrc
		sed -i "$ligne"i"\https_proxy = http://$user_proxy:$password_proxy@$adresse_ip/" /etc/wgetrc
	fi

	if grep "^#use_proxy" /etc/wgetrc > /dev/null ; then
		sed -i "s/#use_proxy = on/use_proxy = on/g" /etc/wgetrc 
	fi

	rm -f $fichtemp
	fi

else

	if grep "https_proxy" /etc/wgetrc > /dev/null ; then
		sed -i "s/https_proxy/#https_proxy/g" /etc/wgetrc 
	fi

	if grep "http_proxy" /etc/wgetrc > /dev/null ; then
		sed -i "s/http_proxy/#http_proxy/g" /etc/wgetrc 
	fi

	if grep "use_proxy" /etc/wgetrc > /dev/null ; then
		sed -i "s/use_proxy = on/#use_proxy = on/g" /etc/wgetrc 
	fi

fi


#############################################################################
# Fonction Inventaire Nouvelle Version D'installation
#############################################################################

inventaire_nouvelle_version_installation()
{


fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


if [ -d /var/www/glpi ] ; then

	cat <<- EOF > $fichtemp
	select version
	from version
	where logiciel='glpi' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/version-reference.txt

	version_reference_glpi=$(sed '$!d' /tmp/version-reference.txt)
	rm -f /tmp/version-reference.txt
	rm -f $fichtemp


	cat <<- EOF > $fichtemp
	select version
	from inventaire
	where logiciel='glpi' and uname='`uname -n`' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/version-installe.txt

	version_installe_glpi=$(sed '$!d' /tmp/version-installe.txt)
	rm -f /tmp/version-installe.txt
	rm -f $fichtemp
fi

}


#############################################################################
# Fonction Verification Couleur
#############################################################################

verification_installation()
{

inventaire_nouvelle_version_installation

# 0=noir, 1=rouge, 2=vert, 3=jaune, 4=bleu, 5=magenta, 6=cyan 7=blanc

if [ ! -f /usr/bin/wget ] || [ ! -f /usr/share/php/DB.php ] || 
   [ ! -f /usr/share/php/Date.php ] || [ ! -f /usr/share/php/Mail.php ] ||
   [ ! -f /usr/share/php/Net/SMTP.php ] || [ ! -f /usr/share/php/Net/Socket.php ] ||
   [ ! -d /usr/share/doc/php5-imap ] || [ ! -d /usr/share/doc/php5-xmlrpc ] ; then
	choix1="\Z1Installation Composant Complementaire\Zn" 
else
	choix1="\Z2Installation Composant Complementaire\Zn" 
fi

if [ ! -d /var/www/glpi ] ; then
	choix2="\Z1Installation Serveur GLPI\Zn" 

elif [ "$version_reference_glpi" != "$version_installe_glpi" ] ; then
	choix2="\Zb\Z3Installation Serveur GLPI\Zn" 

else
	choix2="\Z2Installation Serveur GLPI\Zn" 
fi

if [ ! -d /usr/lib/perl/$version_perl/sys ] ||
   [ ! -f /etc/perl/CPAN/Config.pm ] ||
   [ ! -f /usr/local/share/perl/$version_perl/YAML.pm ] ||
   ! grep "'build_requires_install_policy' => q\[yes\]," /etc/perl/CPAN/Config.pm > /dev/null ; then
	choix3="\Z1Installation PERL\Zn" 
else
	choix3="\Z2Installation PERL\Zn" 
fi

if [ ! -d /usr/local/share/perl/$version_perl/HTTP/Server ] ; then
	choix4="\Z1Installation Modules Cpan\Zn" 
else
	choix4="\Z2Installation Modules Cpan\Zn" 
fi

if [ ! -f /usr/local/bin/fusioninventory-agent ] ; then
	choix5="\Z1Installation Agent Fusioninventory\Zn" 
else
	choix5="\Z2Installation Agent Fusioninventory\Zn" 
fi

if [ ! -f /usr/local/etc/fusioninventory/agent.cfg ] ||
   ! grep -w "delaytime = 10" /usr/local/etc/fusioninventory/agent.cfg > /dev/null ; then
	choix6="\Z1Configuration Agent Fusioninventory\Zn" 
else
	choix6="\Z2Configuration Agent Fusioninventory\Zn" 
fi

if [ ! -f /etc/init.d/fusioninventory ] || [ ! -f /var/run/fusioninventory-agent.pid ] ; then
	choix7="\Z1Installation Daemon Fusioninventory\Zn" 
else
	choix7="\Z2Installation Daemon Fusioninventory\Zn" 
fi

}

#############################################################################
# Fonction Menu 
#############################################################################

menu()
{

verification_installation

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG  --backtitle "Installation Configuration GLPI" \
	  --title "Installation Configuration GLPI" \
	  --clear \
	  --colors \
	  --default-item "5" \
	  --menu "Quel est votre choix" 12 62 5 \
	  "1" "$choix1" \
	  "2" "$choix2" \
	  "3" "Replication Serveur GLPI" \
	  "4" "Installation Agent Fusioninventory" \
	  "5" "Quitter" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Installation Composant Complementaire
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
		installation_composant_complementaire
	fi

	# Installation Serveur GLPI
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp
		installation_serveur_glpi
	fi

	# Replication Serveur GLPI
	if [ "$choix" = "3" ]
	then
		rm -f $fichtemp
		replication_serveur_glpi
	fi

	# Installation Agent Fusioninventory
	if [ "$choix" = "4" ]
	then
		rm -f $fichtemp
              menu_installation_agent_fusioninventory
	fi

	# Quitter
	if [ "$choix" = "5" ]
	then
		clear
	fi
	
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

exit

}

#############################################################################
# Fonction Menu Installation Agent Fusioninventory
#############################################################################

menu_installation_agent_fusioninventory()
{

verification_installation

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG  --backtitle "Installation Agent Fusioninventory" \
	  --title "Installation Agent Fusioninventory" \
	  --clear \
	  --colors \
	  --default-item "6" \
	  --menu "Quel est votre choix" 14 60 6 \
	  "1" "$choix3" \
	  "2" "$choix4" \
	  "3" "$choix5" \
	  "4" "$choix6" \
	  "5" "$choix7" \
	  "6" "\Z4Retour\Zn" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Installation PERL
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
		installation_perl
	fi

	# Installation Modules Cpan
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp
		installation_modules_cpan
	fi

	# Installation Agent Fusioninventory
	if [ "$choix" = "3" ]
	then
		rm -f $fichtemp
		installation_agent_fusioninventory
	fi

	# Configuration Agent Fusioninventory
	if [ "$choix" = "4" ]
	then
		rm -f $fichtemp
		configuration_agent_fusioninventory
	fi

	# Installation Daemon Fusioninventory
	if [ "$choix" = "5" ]
	then
		rm -f $fichtemp
		installation_daemon_fusioninventory
	fi

	# Retour
	if [ "$choix" = "6" ]
	then
		clear
	fi
	
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu
}


#############################################################################
# Fonction Installation Composant Complementaire
#############################################################################

installation_composant_complementaire()
{

(
 echo "20" ; sleep 1
 echo "XXX" ; echo "apt-get -y install php-db php-date"; echo "XXX"
	apt-get -y install php-db php-date &> /dev/null

 echo "40" ; sleep 1
 echo "XXX" ; echo "apt-get -y install php-mail php-mail-mime php-net-smtp php-net-socket"; echo "XXX"
	apt-get -y install php-mail php-mail-mime php-net-smtp php-net-socket &> /dev/null

 echo "60" ; sleep 1
 echo "XXX" ; echo "apt-get -y install php5-cli php5-imap php5-xmlrpc"; echo "XXX"
	apt-get -y install php5-cli php5-imap php5-xmlrpc &> /dev/null

 echo "80" ; sleep 1
 echo "XXX" ; echo "apt-get -y install wget"; echo "XXX"
	apt-get -y install wget &> /dev/null

 echo "100" ; sleep 1
 echo "XXX" ; echo "Terminer"; echo "XXX"
 sleep 2
) |
$DIALOG  --backtitle "Installation Configuration GLPI" \
	  --title "Installation Composant Complementaire" \
	  --gauge "Installation Composant Complementaire" 10 60 0 \

menu
}


#############################################################################
# Fonction Installation Serveur GLPI
#############################################################################

installation_serveur_glpi()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$

(
 echo "10" ; sleep 1
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Installation Serveur GLPI" 10 60 0 \

	cat <<- EOF > $fichtemp
	select version
	from version
	where logiciel='glpi' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/version-reference.txt

	version_reference=$(sed '$!d' /tmp/version-reference.txt)
	rm -f /tmp/version-reference.txt
	rm -f $fichtemp
	

$DIALOG  --ok-label "Validation" \
	  --nocancel \
	  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --form "Quel est votre choix" 10 50 1 \
	  "Version:"  1 1  "$version_reference"   1 10 7 0  2> $fichtemp

valret=$?
choix_version=`cat $fichtemp`
case $valret in

 0)    # Choix Version

	cat <<- EOF > $fichtemp
	select version
	from application
	where logiciel='glpi' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/liste-version.txt


	if grep -w "$choix_version" /tmp/liste-version.txt > /dev/null ; then

	rm -f /tmp/liste-version.txt
	rm -f $fichtemp

	else
	cat <<- EOF > /tmp/erreur
	Veuillez vous assurer que la version saisie
	               est correcte
	EOF

	erreur=`cat /tmp/erreur`

	$DIALOG --ok-label "Quitter" \
		 --colors \
		 --backtitle "Installation Serveur GLPI" \
		 --title "Erreur" \
		 --msgbox  "\Z1$erreur\Zn" 6 50 
	
	rm -f /tmp/liste-version.txt
	rm -f /tmp/erreur
	rm -f $fichtemp
	menu			
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	rm -f $fichtemp
	menu
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	rm -f $fichtemp
	menu
	;;

esac

(
 echo "20" ; sleep 1
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Installation Serveur GLPI" 10 60 0 \

	cat <<- EOF > $fichtemp
	select url
	from application
	where logiciel='glpi' and version='$choix_version' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/url-fichier.txt

	url_fichier=$(sed '$!d' /tmp/url-fichier.txt)
	rm -f /tmp/url-fichier.txt
	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select fichier
	from application
	where logiciel='glpi' and version='$choix_version' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/nom-fichier.txt

	nom_fichier=$(sed '$!d' /tmp/nom-fichier.txt)
	rm -f /tmp/nom-fichier.txt
	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select repertoire
	from application
	where logiciel='glpi' and version='$choix_version' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp >/tmp/nom-repertoire.txt

	nom_repertoire=$(sed '$!d' /tmp/nom-repertoire.txt)
	rm -f /tmp/nom-repertoire.txt
	rm -f $fichtemp

(
 echo "40" ; sleep 1
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Telechargement en cours" 10 60 0 \

	wget --no-check-certificate -P /var/www/ $url_fichier &> /dev/null

(
 echo "60" ; sleep 1
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Installation Serveur GLPI" 10 60 0 \

	
	if [ -d /var/www/glpi ] ; then
	mv /var/www/glpi /var/www/$version_installe_glpi 
	fi

	cd /var/www/
	tar xvzf $nom_fichier
	rm $nom_fichier
	chown -R www-data /var/www/glpi/config
	chown -R www-data /var/www/glpi/files


(
 echo "90" ; sleep 1
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Installation Serveur GLPI" 10 60 0 \

	cat <<- EOF > $fichtemp
	delete from inventaire
	where logiciel='glpi' and uname='`uname -n`' ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into inventaire ( logiciel, version, uname, date, heure )
	values ( 'glpi' , '$choix_version' , '`uname -n`' , '`date +%d.%m.%Y`' , '`date +%Hh%M`' ) ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table inventaire order by logiciel ;
	alter table inventaire order by uname ;
	EOF

	mysql -h $serveur_installation -u $utilisateur_installation -p$password_installation $base_installation < $fichtemp

	rm -f $fichtemp

(
 echo "100" ; sleep 2
) |
$DIALOG  --backtitle "Installation Serveur GLPI" \
	  --title "Installation Serveur GLPI" \
	  --gauge "Terminer" 10 60 0 \


menu

}

#############################################################################
# Fonction Replication Serveur GLPI
#############################################################################

replication_serveur_glpi()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG  --backtitle "Replication Serveur GLPI" \
	  --insecure \
	  --title "Replication Serveur GLPI" \
	  --mixedform "Quel est votre choix" 10 60 0 \
	  "Serveur Source:"       1 1   "$serveur_source"   1 31  22 20 0  \
	  "Serveur Destination:"  2 1   "`uname -n`"   2 31  22 20 0  \
	  "Password Serveur Source:"  3 1   "adnttzfbrr"   3 31  22 20 0  \
	  "Password Serveur Destination:"  4 1   "adnttzfbrr"   4 31  22 20 0  2> $fichtemp

	ligne1=$(sed -n 1p $fichtemp)
	ligne2=$(sed -n 2p $fichtemp)
	ligne3=$(sed -n 3p $fichtemp)
	ligne4=$(sed -n 4p $fichtemp)
	rm -f $fichtemp

	echo "$ligne1 $ligne2 $ligne3 $ligne4"

	sshpass -p $password_root_linux ssh -o StrictHostKeyChecking=no root@$serveur_source "cd /var/www ; tar cfvz glpi.tar.gz --exclude glpi/files/_dumps/'*.sql' --exclude glpi/files/_sessions/'sess_*' glpi/"

	sshpass -p $password_root_linux scp -p root@$serveur_source:/var/www/glpi.tar.gz /var/www/ 

	sshpass -p $password_root_linux ssh -o StrictHostKeyChecking=no root@$serveur_source "cd /var/www ; rm -f glpi.tar.gz"


if [ -d /var/lib/mysql/glpi ] ; then
 
	cat <<- EOF > $fichtemp
	drop database glpi;
	create database glpi character set utf8;
	EOF

	mysql -u root -p$password_root_mysql< $fichtemp

	rm -f $fichtemp

	/etc/init.d/mysql restart &> /dev/null
fi


if [ ! -d /var/lib/mysql/glpi ] ; then
 
	cat <<- EOF > $fichtemp
	create database glpi character set utf8;
	create user 'glpi'@'localhost' identified by 'glpi';
	create user 'glpi'@'%' identified by 'glpi';
	grant all privileges on glpi.* to 'glpi'@'localhost' identified by 'glpi';
	grant all privileges on glpi.* to 'glpi'@'%' identified by 'glpi';
	EOF

	mysql -u root -p$password_root_mysql< $fichtemp

	rm -f $fichtemp

	/etc/init.d/mysql restart &> /dev/null
fi

if [ -d /var/www/glpi ] ; then
	rm -rf /var/www/glpi
fi

	mysqldump -h $serveur_source -u root -p$password_root_mysql glpi > /root/glpi.sql

	mysql -uroot -p$password_root_mysql  glpi < /root/glpi.sql

	#rm -f /root/glpi.sql

	cd /var/www

	tar xvzf glpi.tar.gz

	#rm -f /var/www/glpi.tar.gz


menu
}


#############################################################################
# Fonction Installation PERL
#############################################################################

installation_perl()
{

(

if [ ! -d /usr/lib/perl/$version_perl/sys ] ; then
 echo "10" ; sleep 1
 echo "XXX" ; echo "Installation PERL"; echo "XXX"
	apt-get -y install perl &> /dev/null
fi

if [ ! -f /etc/ssl/openssl.cnf ] ; then
 echo "15" ; sleep 1
 echo "XXX" ; echo "Installation OpenSSL"; echo "XXX"
	apt-get -y install openssl &> /dev/null
fi

if [ ! -f /usr/lib/perl5/Net/SSLeay.pm ] ; then
 echo "20" ; sleep 1
 echo "XXX" ; echo "Installation libnet-ssleay-perl"; echo "XXX"
	apt-get -y install libnet-ssleay-perl &> /dev/null
fi

if [ ! -f /etc/perl/CPAN/Config.pm ] ||
   ! grep "'build_requires_install_policy' => q\[yes\]," /etc/perl/CPAN/Config.pm ; then

 echo "40" ; sleep 1
 echo "XXX" ; echo "Configuration PERL"; echo "XXX"

	cat <<- EOF > /etc/perl/CPAN/Config.pm

	# This is CPAN.pm's systemwide configuration file. This file provides
	# defaults for users, and the values can be changed in a per-user
	# configuration file. The user-config file is being looked for as
	# /root/.cpan/CPAN/MyConfig.pm.

	\$CPAN::Config = {
	  'applypatch' => q[],
	  'auto_commit' => q[0],
	  'build_cache' => q[100],
	  'build_dir' => q[/root/.cpan/build],
	  'build_dir_reuse' => q[0],
	  'build_requires_install_policy' => q[ask/yes],
	  'bzip2' => q[],
	  'cache_metadata' => q[1],
	  'check_sigs' => q[0],
	  'colorize_output' => q[0],
	  'commandnumber_in_prompt' => q[1],
	  'connect_to_internet_ok' => q[1],
	  'cpan_home' => q[/root/.cpan],
	  'curl' => q[],
	  'ftp' => q[],
	  'ftp_passive' => q[1],
	  'ftp_proxy' => q[],
	  'getcwd' => q[cwd],
	  'gpg' => q[/usr/bin/gpg],
	  'gzip' => q[/bin/gzip],
	  'halt_on_failure' => q[0],
	  'histfile' => q[/root/.cpan/histfile],
	  'histsize' => q[100],
	  'http_proxy' => q[],
	  'inactivity_timeout' => q[0],
	  'index_expire' => q[1],
	  'inhibit_startup_message' => q[0],
	  'keep_source_where' => q[/root/.cpan/sources],
	  'load_module_verbosity' => q[v],
	  'lynx' => q[],
	  'make' => q[/usr/bin/make],
	  'make_arg' => q[],
	  'make_install_arg' => q[],
	  'make_install_make_command' => q[/usr/bin/make],
	  'makepl_arg' => q[INSTALLDIRS=site],
	  'mbuild_arg' => q[],
	  'mbuild_install_arg' => q[],
	  'mbuild_install_build_command' => q[./Build],
	  'mbuildpl_arg' => q[--installdirs site],
	  'ncftp' => q[],
	  'ncftpget' => q[],
	  'no_proxy' => q[],
	  'pager' => q[/bin/more],
	  'patch' => q[/usr/bin/patch],
	  'perl5lib_verbosity' => q[v],
	  'prefer_installer' => q[MB],
	  'prefs_dir' => q[/root/.cpan/prefs],
	  'prerequisites_policy' => q[ask],
	  'proxy_pass' => q[],
	  'proxy_user' => q[],
	  'scan_cache' => q[atstart],
	  'shell' => q[/bin/bash],
	  'show_unparsable_versions' => q[0],
	  'show_upload_date' => q[0],
	  'show_zero_versions' => q[0],
	  'tar' => q[/bin/tar],
	  'tar_verbosity' => q[v],
	  'term_is_latin' => q[1],
	  'term_ornaments' => q[1],
	  'test_report' => q[0],
	  'trust_test_report_history' => q[0],
	  'unzip' => q[],
	  'urllist' => [],
	  'use_sqlite' => q[0],
	  'wget' => q[/usr/bin/wget],
	  'yaml_load_code' => q[0],
	  'yaml_module' => q[YAML],
	};
	1;
	__END__
	EOF


	sed -i "s/'build_requires_install_policy' => q\[ask\/yes\],/'build_requires_install_policy' => q\[yes\],/g" /etc/perl/CPAN/Config.pm
	sed -i "s/'prerequisites_policy' => q\[ask\],/'prerequisites_policy' => q\[follow\],/g" /etc/perl/CPAN/Config.pm
fi

if [ -f /etc/apt/apt.conf ] ; then
 echo "60" ; sleep 1
 echo "XXX" ; echo "Recherche d'un Proxy"; echo "XXX"

	if grep "http::Proxy" /etc/apt/apt.conf > /dev/null ; then
	fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$

	sed -n 's/.*Proxy\ \(.*\);.*/\1/ip' /etc/apt/apt.conf > $fichtemp

	adresse_ip=$(sed -n 's/.*@\(.*\)\/.*/\1/ip' $fichtemp)
	

	sed -n 's/.*http:\/\/\(.*\):.*/\1/ip' /etc/apt/apt.conf  > $fichtemp

	user_proxy=$(sed -n 's/^\(.*\):.*/\1/ip' $fichtemp)
	password_proxy=$(sed -n 's/.*:\(.*\)@.*/\1/ip' $fichtemp)

	sed -i "s/'http_proxy' => q\[\],/'http_proxy' => q\[http:\/\/$adresse_ip\/\],/g" /etc/perl/CPAN/Config.pm
	sed -i "s/'proxy_pass' => q\[\],/'proxy_pass' => q\[$password_proxy\],/g" /etc/perl/CPAN/Config.pm
	sed -i "s/'proxy_user' => q\[\],/'proxy_user' => q\[$user_proxy\],/g" /etc/perl/CPAN/Config.pm


	rm -f $fichtemp
	fi
fi

if grep "Debian GNU/Linux 5.0" /etc/issue.net > /dev/null && 
   ! grep "my \$answer = \"yes\";" /usr/share/perl/$version_perl/CPAN.pm > /dev/null; then 
 echo "70" ; sleep 1
 echo "XXX" ; echo "Modification du fichier CPAN.pm pour debian 5"; echo "XXX" ; sleep 2
	ligne=$(sed -n '/Is it OK to try to connect to the Internet/=' /usr/share/perl/$version_perl/CPAN.pm)
	sed -i "$ligne"s"/my $answer/#my $answer/g" /usr/share/perl/$version_perl/CPAN.pm
	sed -i "$ligne"a"\\\t\t  my \$answer = \"yes\";" /usr/share/perl/$version_perl/CPAN.pm
fi

if [ ! -f /usr/local/share/perl/$version_perl/YAML.pm ] ; then
 echo "80" ; sleep 1
 echo "XXX" ; echo "Installation YAML"; echo "XXX"
	cpan -f install YAML &> /dev/null
fi

 echo "100" ; sleep 1
 echo "XXX" ; echo "Terminer"; echo "XXX"
 sleep 2
) |
$DIALOG  --backtitle "Installation Agent Fusioninventory" \
	  --title "Installation PERL" \
	  --gauge "Installation PERL" 10 60 0 \

menu_installation_agent_fusioninventory
}


#############################################################################
# Fonction Installation Modules Cpan
#############################################################################

installation_modules_cpan()
{

	cpan -f install YAML
	cpan -f install ExtUtils::MakeMaker 
	cpan -f install File::Which
	cpan -f install HTTP::Server::Simple
	cpan -f install HTTP::Server::Simple::Authen
	cpan -f install IO::Capture::Stderr 
	cpan -f install IO::Socket::SSL
	cpan -f install IPC::Run
	cpan -f install LWP::Protocol::https
	cpan -f install Net::IP
	cpan -f install Test::Exception
	cpan -f install Test::MockModule 
	cpan -f install Test::More
	cpan -f install Text::Template
	cpan -f install UNIVERSAL::require
	cpan -f install XML::TreePP
	cpan -f install Digest::MD5
	cpan -f install File::Which
	cpan -f install Proc::Daemon
	cpan -f install Proc::PID::File

menu_installation_agent_fusioninventory
}


#############################################################################
# Fonction Installation Agent Fusioninventory
#############################################################################

installation_agent_fusioninventory()
{

	cpan -f install FusionInventory::Agent


menu_installation_agent_fusioninventory
}


#############################################################################
# Fonction Configuration Agent Fusioninventory
#############################################################################

configuration_agent_fusioninventory()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG  --ok-label "Validation" \
	  --nocancel \
	  --backtitle "Configuration Agent Fusioninventory" \
	  --title "Configuration Agent Fusioninventory" \
	  --form "Quel est votre choix" 10 54 1 \
	  "Adresse IP Fusioninventory:"  1 1  "$serveur_fusioninventory"   1 29 16 0  2> $fichtemp

valret=$?
adresse_ip=`cat $fichtemp`
case $valret in

 0)    # Configuration Agent Fusioninventory

	(
	echo "40" ; sleep 1
 	echo "XXX" ; echo "Configuration Agent Fusioninventory en cours"; echo "XXX"
		ligne=$(sed -n '/glpi/=' /usr/local/etc/fusioninventory/agent.cfg)
		sed -i "$ligne"d /usr/local/etc/fusioninventory/agent.cfg
		sed -i "$ligne"i"\server = http://$adresse_ip/glpi/plugins/fusioninventory/" /usr/local/etc/fusioninventory/agent.cfg
		 			
	echo "80" ; sleep 1
 	echo "XXX" ; echo "Configuration Agent Fusioninventory en cours"; echo "XXX"
		ligne=$(sed -n '/delaytime/=' /usr/local/etc/fusioninventory/agent.cfg)
		sed -i "$ligne"d /usr/local/etc/fusioninventory/agent.cfg
		sed -i "$ligne"i"\delaytime = 10" /usr/local/etc/fusioninventory/agent.cfg
		
 	echo "100" ; sleep 1
 	echo "XXX" ; echo "Terminer"; echo "XXX"
 	sleep 2
	) |
	$DIALOG  --backtitle "Installation Agent Fusioninventory" \
		  --title "Configuration Agent Fusioninventory" \
		  --gauge "Configuration Agent Fusioninventory en cours" 10 60 0 \


	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_installation_agent_fusioninventory
}


#############################################################################
# Fonction Installation Daemon Fusioninventory
#############################################################################

installation_daemon_fusioninventory()
{

(

 echo "20" ; sleep 1
 echo "XXX" ; echo "Installation Daemon Fusioninventory en cours"; echo "XXX"

	cat <<- EOF > /etc/init.d/fusioninventory
	#! /bin/bash

	### BEGIN INIT INFO
	# Provides:          fusioninventory-agent
	# Required-Start:    $local_fs $remote_fs $network $syslog
	# Required-Stop:     $local_fs $remote_fs $network $syslog
	# Default-Start:     2 3 4 5
	# Default-Stop:      0 1 6
	# Short-Description: starts FusionInventory Agent
	# Description:       starts FusionInventory Agent using start-stop-daemon
	### END INIT INFO


	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
	DAEMON=/usr/local/bin/fusioninventory-agent
	DAEMON_OPTS=-d
	DESC=fusioninventory-agent
	NAME=fusioninventory
	PIDFILE="/var/run/\$DESC.pid"


	test -x \$DAEMON || exit 0


	case "\$1" in
         start)
               echo -n "Starting \$DESC: "
               start-stop-daemon --start --quiet --exec \$DAEMON -- \$DAEMON_OPTS
               echo "is running."         
               ;; 

         stop)
               echo -n "Stopping \$DESC: "
               start-stop-daemon --stop --quiet --pidfile \$PIDFILE
               rm -f \$PIDFILE
               rm -rf /usr/local/var/\$NAME
               echo "is not running."
               ;;

         restart|force-reload)
               echo -n "Restarting \$DESC: "
               start-stop-daemon --stop --quiet --pidfile \$PIDFILE
               rm -f \$PIDFILE
               rm -rf /usr/local/var/\$NAME
               sleep 1
               start-stop-daemon --start --quiet --exec \$DAEMON -- \$DAEMON_OPTS
               echo "is running."
               ;;

         status)
               if [ -f \$PIDFILE ]
               then
                     echo "\$DESC: is running."
               else
                     echo "\$DESC: is not running."
               fi
               ;;

         *)
               echo "Usage: \$NAME {start|stop|restart|status}" >&2
               exit 1
               ;;

	esac

	exit 0
	EOF


 echo "60" ; sleep 1
 echo "XXX" ; echo "Installation Daemon Fusioninventory en cours"; echo "XXX"
	chmod 0755 /etc/init.d/fusioninventory
	update-rc.d fusioninventory defaults &> /dev/null

 echo "80" ; sleep 1
 echo "XXX" ; echo "Installation Daemon Fusioninventory en cours"; echo "XXX"
	if [ ! -f /var/run/fusioninventory-agent.pid ] ; then
		/etc/init.d/fusioninventory start &> /dev/null
	else
		/etc/init.d/fusioninventory restart &> /dev/null
	fi

 echo "100" ; sleep 1
 echo "XXX" ; echo "Terminer"; echo "XXX"
 sleep 2
) |
$DIALOG  --backtitle "Installation Agent Fusioninventory" \
	  --title "Installation Daemon Fusioninventory" \
	  --gauge "Installation Daemon Fusioninventory en cours" 10 60 0 \
		
menu_installation_agent_fusioninventory
}


#############################################################################
# Demarrage du programme
#############################################################################


menu

