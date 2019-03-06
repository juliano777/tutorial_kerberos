# https://www.kerberos.org/software/tutorial.html

# https://www.certdepot.net/rhel7-configure-kerberos-kdc/
# https://www.certdepot.net/rhel7-configure-system-authenticate-using-kerberos/

## Termos

# Realm / Domínio

"
Domínio administrativo de autenticação.
Se a autenticação for configurada para mais de um domínio (realm), Cross-Authentication, um mesmo ticket pode ser usado para esses domínios.
O nome de um domíno é case sensitive.
Em uma organização recomenda-se colocar o nome do domínio com o mesmo DNS, mas em letras maiúsculas, e. g.; DNS: empresa.com, seu domínio (realm) Kerberos será EMPRESA.COM.
"

# Principal

"
É o nome usado para se referir às entradas no banco de dados do servidor de autenticação.
Um principal é associado com cada usuário, host, serviço dentro de um domínio.

    component1/component2/.../componentN@REALM

No entanto, na prática é melhor utilizar dois componentes.
para uma entrada a um usuário o principal pode ser feito da seguinte maneira:

    Name[/Instance]@REALM

A instância é opcional e normalmente é usada para descrever melhor o tipo de usuário.

    pippo@EXAMPLE.COM    admin/admin@EXAMPLE.COM    pluto/admin@EXAMPLE.COM

Se em vez disso, as entradas se referirem a serviços, os principais assumem a seguinte forma:

    Service/Hostname@REALM

O primeiro componente se refere a um serviço (ftp, imap, etc) ou a palavra host que seria para acesso genérico.
O segundo componente é o FQDN do DNS.

    imap/mbox.example.com@EXAMPLE.COM
    host/server.example.com@EXAMPLE.COM
    afs/example.com@EXAMPLE.COM

Podemos notar que o último exemplo é uma exceção porque o segundo componente não é um hostname, mas o nome de uma célula AFS ao qual o principal se refere.
"

# Ticket

"
É alguma coisa que o cliente apresenta a um servidor de aplicação que demonstra que sua identidade foi autenticada.
Tickets são emitidos pelo servidor de autenticação e encriptados usando uma chave secreta que somente o servidor de autenticação possui e conhece.
Como a chave secreta é compartilhada apenas entre os servidores de autenticação, nem mesmo o cliente conhece seu conteúdo.
Principais informações contidas no ticket:

- Username;
- O principal;
- Endereço da máquina cliente para o qual o ticket pode ser usado (opcional);
- Data / hora de emissão e validade do ticket;
- Chave de sessão

Cada ticket tem uma expiração (geralmente 10 horas).
"

# 
# Realm: ${DOM_UPPER}
# DNS: ${DOM_UPPER}
# hostname
# Servidor: kdc.${DOM_UPPER}

"
Packages required:

    KDC server package: krb5-server
    Admin package: krb5-libs
    Client package: krb5-workstation

Configuration Files:

    /var/kerberos/krb5kdc/kdc.conf
    /var/kerberos/krb5kdc/kadm5.acl
    /etc/krb5.conf

Important Paths:

    KDC path: /var/kerberos/krb5kdc/
"


# Instalação de pacotes e limpeza posterior:

yum install -y krb5-{server,libs,workstation} libkadm5 ntp pam_krb5 \
&& yum clean all



# Digite o endereço de servidor NTP: <ntp.cais.rnp.br>

read -p 'Digite o endereço de servidor NTP: ' NTPSERVER



# Digite o seu domínio:

read -p 'Digite o hostname do servidor: ' SRV_HOSTNAME



# Digite o seu domínio:

read -p 'Digite o seu domínio: ' DOM_LOW



# Convertendo o domínio para letras maiúsculas

export DOM_UPPER=`echo ${DOM_LOW} | tr 'a-z' 'A-Z'`



# FQDN DO SERVER

export SRV_FQDN="${SRV_HOSTNAME}.${DOM_LOW}"



# Configurando o hostname:

hostnamectl set-hostname ${SRV_FQDN} && systemctl restart systemd-hostnamed



# Sincronizando o relógio do sistema;

ntpdate ${NTPSERVER}



# Criar o arquivo de configuração para sincronização do NTP

cat << EOF > /etc/ntp.conf
tinker panic 0
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
server ntpdate ${NTPSERVER} iburst
driftfile /var/lib/ntp/drift
EOF



# Iniciando e habilitando o serviço do NTP:

systemctl start ntpd.service

systemctl enable ntpd.service



# /etc/krb5.conf

cat << EOF > /etc/krb5.conf
[libdefaults]
    default_realm = ${DOM_UPPER}
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    forwardable = true
    udp_preference_limit = 1000000
    default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

[realms]
    ${DOM_UPPER} = {
        kdc = ${SRV_FQDN}:88
        admin_server = ${SRV_FQDN}:749
        default_domain = ${DOM_LOW}
    }

[domain_realm]
    .${DOM_LOW} = ${DOM_UPPER}
     ${DOM_LOW} = ${DOM_UPPER}

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOF



# /var/kerberos/krb5kdc/kdc.conf

cat << EOF > /var/kerberos/krb5kdc/kdc.conf
default_realm = ${DOM_UPPER}

[kdcdefaults]
    v4_mode = nopreauth
    kdc_ports = 88
    kdc_tcp_ports = 88
[realms]
    ${DOM_UPPER} = {        
        admin_keytab = /etc/kadm5.keytab
        database_name = /var/kerberos/krb5kdc/principal
        acl_file = /var/kerberos/krb5kdc/kadm5.acl
        key_stash_file = /var/kerberos/krb5kdc/stash
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal \
des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
        default_principal_flags = +preauth
    }
EOF



# /var/kerberos/krb5kdc/kadm5.acl

echo "*/admin@${DOM_UPPER}	    *" > /var/kerberos/krb5kdc/kadm5.acl



# Create the database and set a good password which you can remember. This command also stashes your password on the KDC so you don’t have to enter it each time you start the KDC

kdb5_util create -r ${DOM_UPPER} -s



# Now on the KDC create a admin principal and also a test user (user1):

kadmin.local -q 'addprinc root/admin'
kadmin.local -q 'addprinc user1'
kadmin.local -q 'ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin'
kadmin.local -q 'ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw'



# Listar os principais da base:

kadmin.local -q listprincs

'
Authenticating as principal root/admin@${DOM_UPPER} with password.
K/M@DOMINIO
kadmin/admin@DOMINIO
kadmin/changepw@DOMINIO
kadmin/ec2-23-23-86-44.compute-1.amazonaws.com@${DOM_UPPER}
kiprop/ec2-23-23-86-44.compute-1.amazonaws.com@${DOM_UPPER}
krbtgt/${DOM_UPPER}@DOMINIO
root/admin@DOMINIO
user1@DOMINIO
'



# Apagar principais desnecessários:

kadmin.local -q 'delprinc kadmin/ec2-23-23-86-44.compute-1.amazonaws.com@${DOM_UPPER}'
kadmin.local -q 'delprinc kiprop/ec2-23-23-86-44.compute-1.amazonaws.com@${DOM_UPPER}'



# Iniciar Kerberos KDC e kadmin daemons e também habilitá-los (krb5kdc e admin):

systemctl start k{rb5kdc,admin}.service
systemctl enable k{rb5kdc,admin}.service



# Agora, vamos criar uma entidade principal para o nosso servidor KDC e colocá-lo na tabela de chaves (keytab):

kadmin.local -q "addprinc -randkey host/${SRV_HOSTNAME}.${DOM_UPPER}"
kadmin.local -q "ktadd host/${SRV_HOSTNAME}.${DOM_UPPER}"



# =============================================================================
# Configurando o Cliente Kerberos
# =============================================================================



# Instale o Kerberos client:

yum -y install krb5-workstation && yum clean all



# Transfira seu /etc/krb5.conf (que foi criado a partir do comando acima) do servidor KDC para o cliente:

scp root@kerberos.${DOM_UPPER}:/etc/krb5.conf /etc/krb5.conf



# Adicione alguns principais no host:

kadmin -p root/admin



# Adicione alguns principais no host:

kadmin -q 'addprinc -randkey host/client.${DOM_UPPER}'
kadmin -q 'ktadd host/kerberos.${DOM_UPPER}'



# =============================================================================
# Configurando a autenticação Kerberos no SSH
# =============================================================================



Pre-Req: Make sure you can issue a kinit -k host/fqdn@REALM and get back a kerberos ticket without having to specify a password.
Step1: Configuring SSH Server



# 

kinit -k host/${DOM_UPPER}@${DOM_UPPER}




Configure /etc/ssh/sshd_config file to include the following lines:

KerberosAuthentication yes
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes
UsePAM no

Now, restart the ssh daemon.



Step2: Configure the SSH Client

Configure /etc/ssh_config to include following lines:

Host *.domain.com
  GSSAPIAuthentication yes
  GSSAPIDelegateCredentials yes


























