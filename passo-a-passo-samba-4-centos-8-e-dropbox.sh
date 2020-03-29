
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

#Apesar de não ter provisionado o dominio, vamos configurar o path, deixa o samba-tool disponível, 
# sem necessidade de passar o caminho absoluto do binário.
vim ~/.bash_profile
# Procure por
PATH=$PATH:$HOME/bin

#Acrescente o diretorio do samba, e deixe como o exemplo abaixo.
PATH=$PATH:$HOME/bin:/opt/samba/sbin:/opt/samba/bin

# Relendo o arquivo para as alterações entrarem em vigor. 
source ~/.bash_profile

# Editando o arquivo do named.conf e incluindo os arquivos de DNS do Samba
vim /etc/named.conf

		   #Adicione o IP do servidor samba para que a porta 53 escute.
11 		   listen-on port 53 { 127.0.0.1; 192.168.254.4; };
		   # Ativando o recursion/query dentro da Rede Local.
20         allow-recursion { localhost; 192.168.254.0/24; };
21         allow-query     { localhost; 192.168.254.0/24; };

		   # Habilitando a chave do samba
40         tkey-gssapi-keytab "/opt/samba/bind-dns/dns.keytab";
41         minimal-responses yes;

			# Arquivo com as zonas do samba
64 include "/opt/samba/bind-dns/named.conf";


#Criando um arquivo para inicializar o samba atráves do systemd e também automaticamente no boot do S.O
vim /etc/systemd/system/samba.service

[Unit]
Description= Samba 4 Active Directory
After=syslog.target
After=network.target

[Service]
Type=forking
PIDFile=/opt/samba/var/run/samba.pid # /usr/local/samba/var/run/samba.pid
ExecStart=/opt/samba/sbin/samba # /usr/local/samba/sbin/samba

[Install]
WantedBy=multi-user.target

# Inicializando o bind (named) e samba

systemctl start named
systemctl start samba

# verificando as portas do samba 
netstat -putan | grep samba



#### INSTALAÇÃO DO DROPBOX #### 

# Baixe a versão mais recente do dropbox 
https://www.dropbox.com/install-linux
https://linux.dropbox.com/packages/

# Baixe o pacote de instalação mais recente.
# Extraia o tarball:
tar xjf ./nautilus-dropbox-1.6.1.tar.bz2

#Na maioria das distribuições, os comandos a seguir devem completar a tarefa:
cd ./nautilus-dropbox-1.6.1
./configure && make && make install
