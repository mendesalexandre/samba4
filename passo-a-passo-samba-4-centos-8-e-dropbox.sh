
### Instalação do Samba 4 (Versão 4.12) Com Centos 8 + Dropbox para Upload 


## Alterar o nome do servidor (Altere conforme sua escolha)
vim /etc/hostname
toronto

## Para salvar e sair ESC :wq

# editar o /etc/hosts
vim /etc/hosts
# IP			#FQDN						#ALIAS
192.168.254.4	toronto.laboratorio.com.br	toronto
	  
	  
### Download do repositório EPEL e ativando repositório PowerTools 

vim /etc/yum.repos.d/CentOS-PowerTools.repo

 13 [PowerTools]
 14 name=CentOS-$releasever - PowerTools
 15 mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=PowerTools&infra=$infra
 16 #baseurl=http://mirror.centos.org/$contentdir/$releasever/PowerTools/$basearch/os/
 17 gpgcheck=1
 18 enabled=1 # Por padrão vem enabled=0 altere pra 1
 19 gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

yum install epel-release -y 


yum update 

	  
### Download das Depêndencias	  
yum install docbook-style-xsl gcc gdb gnutls-devel jansson-devel \
      keyutils-libs-devel krb5-workstation libacl-devel libaio-devel \
      libattr-devel libblkid-devel libtasn1 libtasn1-tools \
      libxml2-devel libxslt lmdb-devel openldap-devel pam-devel perl \
      perl-ExtUtils-MakeMaker perl-Parse-Yapp popt-devel python3-cryptography \
      python3-dns python3-gpg python36-devel readline-devel systemd-devel \
      tar zlib-devel gpgme-devel libarchive-devel libicu-devel tracker glib2 glibc libtirpc-devel \
	  bind bind-devel wget rsync rpcgen python3-docutils nautilus-devel git net-tools bind-utils bzip \
	  nautilus-devel python3-docutils
	  
# Faça o Download da versão do Samba a ser instalada, nesse caso vamos usar a versão mais atual.
[   ]	samba-4.12.0.tar.gz	2020-03-03 10:11	17M	 
https://download.samba.org/pub/samba/stable/samba-4.12.0.tar.gz

# Crie uma pasta para armazenamento dos sources do samba 

mkdir -p /usr/src/samba
cd /usr/src/samba
wget -c https://download.samba.org/pub/samba/stable/samba-4.12.0.tar.gz

# Após o download descompacte o código fonte e compile. 
tar -xvzf samba-4.12.0.tar.gz
cd samba-4.12.0


# Por padrão o samba compila em /usr/local/samba, mas seguindo o padrão FHS do Linux 
# Vamos instalar em /opt/samba
./configure --enable-debug --enable-selftest --with-systemd --prefix=/opt/samba

# Se todas as dependencias estiverem ok, vai ter aparecido um tela dizendo que a compilação ocorreu com sucesso!

