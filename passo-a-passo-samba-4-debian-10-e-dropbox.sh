
### Instalação do Samba 4 (Versão 4.12) Com Debian 10 + Dropbox para Upload 

# Download das dependencias
apt-get install acl attr autoconf bind9utils bison build-essential \
  debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
  libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
  libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl \
  libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
  libpopt-dev libreadline-dev nettle-dev perl perl-modules-5.28 pkg-config \
  python-all-dev python-crypto python-dbg python-dev python-dnspython \
  python3-dnspython python-gpg python3-gpg python-markdown python3-markdown \
  python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils libtasn1-bin libicu-dev \
  libtracker-sparql-2.0-dev glib-2.0 python3-pyasn1 python3-cryptography python3-iso8601 libdbus-1-dev \
  bind9 


## Alterar o nome do servidor (Altere conforme sua escolha)
vim /etc/hostname
toronto

# Editar o /etc/hosts
vim /etc/hosts
# IP			#FQDN						#ALIAS
192.168.254.4	toronto.laboratorio.com.br	toronto
  
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
# Arquivo com as zonas do samba
include "/opt/samba/bind-dns/named.conf";

# Editando o arquivo do named.conf.options e incluindo os arquivos de DNS do Samba
vim /etc/named.conf.options

		   #Adicione o IP do servidor samba para que a porta 53 escute.
11 		   listen-on port 53 { 127.0.0.1; 192.168.254.4; };
		   # Ativando o recursion/query dentro da Rede Local.
20         allow-recursion { localhost; 192.168.254.0/24; };
21         allow-query     { localhost; 192.168.254.0/24; };

		   # Habilitando a chave do samba
40         tkey-gssapi-keytab "/opt/samba/bind-dns/dns.keytab";
41         minimal-responses yes;


#Provisionando o dominio
/opt/samba/bin/samba-tool domain provision --domain=LABORATORIO --adminpass=dominio@samba4 \
--dns-backend=BIND9_DLZ --server-role=dc \
--function-level=2008_R2 --use-xattr=yes \
--use-rfc2307 --realm=laboratorio.com.br

#Criando um arquivo para inicializar o samba atráves do systemd e também automaticamente no boot do S.O
vim /etc/systemd/system/samba.service

[Unit]
Description= Samba 4 Active Directory
After=syslog.target
After=network.target

[Service]
Type=forking
PIDFile=/opt/samba/var/run/samba.pid
ExecStart=/opt/samba/sbin/samba

[Install]
WantedBy=multi-user.target

# Se você estiver no Linux e usar o Appamor, precisa inserir as linhas referentes ao arquivo do bind do samba.
# Se o arquivo não existir, crie.
vim /etc/apparmor.d/usr.sbin.named

25   # Arquivos Samba4 - Bind9
26   /opt/samba/lib/** rm,
27   /opt/samba/bind-dns/dns.keytab rk,
28   /opt/samba/bind-dns/named.conf r,
29   /opt/samba/bind-dns/dns/** rwk,
30   /opt/samba/etc/smb.conf r,

# Reinicie o apparmor
service apparmor reload

#Inicie o bind9
service bind9 start

#Editando o /etc/resolv.conf
search laboratorio.com.br
domain laboratorio.com.br
nameserver 192.168.254.3



# Inicializando o bind (named) e samba

systemctl start named
systemctl start samba

# verificando as portas do samba 
netstat -putan | grep samba

# Fazendo um teste no dig para o dominio
dig -t SOA laboratorio.com.br


# WINBIND

ln -s /opt/samba/lib/libnss_winbind.so /lib
ln -s /lib/libnss_winbind.so /lib/libnss_winbind.so.2
ldconfig

#Para os sistemas de 64bits precisamos fazer da seguinte forma
ln -s /opt/samba/lib/libnss_winbind.so /lib64
ln -s /lib64/libnss_winbind.so /lib64/libnss_winbind.so.2
ldconfig



## Servidor NTP
apt-get install ntp ntpdate -y

Agora vamos fazer um backup do arquivo de configuração default do ntp.conf
mv /etc/ntp.conf /etc/ntp.conf.old

Agora vamos configurar o ntp
vim /etc/ntp.conf
#############################################################################
server 127.127.1.0
fudge  127.127.1.0 stratum 10
server a.ntp.br iburst prefer
server 0.pool.ntp.org  iburst prefer
server 1.pool.ntp.org  iburst prefer
driftfile /var/lib/ntp/ntp.drift
logfile /var/log/ntp
ntpsigndsocket /usr/local/samba/var/lib/ntp_signd/
restrict default kod nomodify notrap nopeer mssntp
restrict 127.0.0.1
restrict a.ntp.br mask 255.255.255.255 nomodify notrap nopeer noquery
restrict b.ntp.br mask 255.255.255.255 nomodify notrap nopeer noquery
restrict c.ntp.br mask 255.255.255.255 nomodify notrap nopeer noquery
#############################################################################

Iniciando o Daemon do NTP
systemctl start ntp

Testando o sincronismo do servidor de tempo

ntpq -p 127.0.0.1
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
 LOCAL(0)        .LOCL.          10 l    -   64    1    0.000    0.000   0.000
 a.ntp.br        .INIT.          16 u    -   64    0    0.000    0.000   0.000
 a.st1.ntp.br    .INIT.          16 u    -   64    0    0.000    0.000   0.000
 roma.coe.ufrj.b .INIT.          16 u    -   64    0    0.000    0.000   0.000
 
Atualizar o nosso ntp
ntpdate -u a.ntp.br

NOTA: Um cuidado que temos que tomar é referente a timezone do servidor, pra quem mora em um estado na qual não é o mesmo 
horario de Brasília deve ficar atento. 

Para verificar o tempo e hora usamos o comando: 
date

Para verificar a zona de tempo atual do seu servidor
timedatectl
[root@master fulano]# timedatectl
      Local time: Sex 2017-03-24 15:07:39 -04
  Universal time: Sex 2017-03-24 19:07:39 UTC
        RTC time: Sex 2017-03-24 19:07:35
       Time zone: America/Cuiaba (-04, -0400)
     NTP enabled: yes
NTP synchronized: no
 RTC in local TZ: no
      DST active: no
 Last DST change: DST ended at
                  Sáb 2017-02-18 23:59:59 -03
                  Sáb 2017-02-18 23:00:00 -04
 Next DST change: DST begins (the clock jumps one hour forward) at
                  Sáb 2017-10-14 23:59:59 -04
                  Dom 2017-10-15 01:00:00 -03



Listar as timezones disponiveis. 
timedatectl list-timezones

Filtrando as timezones de acordo com seu continente
timedatectl list-timezones | grep America/Cuiaba
[root@master fulano]# timedatectl list-timezones | grep America/Cuiaba
America/Cuiaba

#E por fim, caso necessário, alterando a timezone 
timedatectl set-timezone America/Cuiaba

Agora vamos ajustar o grupo do arquivo ntp_signd
chgrp ntp /usr/local/samba/var/lib/ntp_signd


#### INSTALAÇÃO DO DROPBOX #### 

## Criando usuário para montar o diretório do dropbox 
useradd -ou 0 -g 0 cloud -m -d /srv/storage/cloud -s /bin/bash
#OBS: Após a instalação, desative o shell do usuário cloud.

# Mude para o usuário cloud
su - cloud

# Baixe a versão mais recente do dropbox para Debian/Ubuntu de acordo com o sistema instalado na sua máquina.
https://www.dropbox.com/install-linux





# Criando o script para o shell.
# Crie  um arquivo /lib/systemd/system/dropbox@.service:
vim /lib/systemd/system/dropbox@.service

[Unit]
Description=Dropbox as a system service user %i

After=syslog.target
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/dropbox start
ExecStop=/usr/bin/dropbox stop
User=%i
#Group=%i # só se o usuário do grupo for de mesmo nome


# 'LANG' might be unnecessary, since systemd already sets the
# locale for all services according to "/etc/locale.conf".
# Run `systemctl show-environment` to make sure.
Environment=LANG=pt_BR.utf-8

[Install]
WantedBy=multi-user.target


# Ativando o script para o usuario cloud
systemctl enable dropbox@cloud.service

# O usuário cloud tem um id 0, ou seja, é root, vamos desabilitar o shell dele para não poder executar nenhum script. 
usermod -s /usr/sbin/nologin cloud

# Iniciando o script
systemctl start dropbox@cloud.service


### Montando disco com LVM

# Pacote do LVM
apt-get install lvm2

#Criando os volumes físicos
pvcreate /dev/sdb1
pvcreate /dev/sdb2

# Lista os volumes físicos
root@toronto:/home/fulano# pvscan
  PV /dev/sdb1                      lvm2 [<8,00 GiB]
  Total: 1 [<8,00 GiB] / in use: 0 [0   ] / in no VG: 1 [<8,00 GiB]


root@toronto:/home/fulano# pvdisplay
  "/dev/sdb1" is a new physical volume of "<8,00 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdb1
  VG Name
  PV Size               <8,00 GiB
  Allocatable           NO
  PE Size               0
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               zheGuL-73Pw-Z3vg-i4MQ-bYP2-juFl-2coL2l


# Criar os grupos de volumes (vgcreate)
vgcreate grupo_volume_1 /dev/sdb1

root@toronto:/home/fulano# vgcreate grupo_volume_1 /dev/sdb1
  Volume group "grupo_volume_1" successfully created
  
# Criar os volume Lógicos
lvcreate -l +100%FREE -n vol_log_1 grupo_volume_1










