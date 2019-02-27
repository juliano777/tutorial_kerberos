# https://www.kerberos.org/software/tutorial.html

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
# Realm: FOO.COM
# DNS: foo.com
# hostname
# Servidor: kerberos.foo.com

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

yum install -y krb5-{server,libs,workstation} libkadm5 ntp && yum clean all



# Sincronizando o relógio do sistema;

ntpdate ntp.cais.rnp.br



# Criar o arquivo de configuração para sincronização do NTP

cat << EOF > /etc/ntp.conf
tinker panic 0
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
server ntpdate ntp.cais.rnp.br iburst
driftfile /var/lib/ntp/drift
EOF



# Iniciando e habilitando o serviço do NTP:

systemctl start  ntpd.service

systemctl enable ntpd.service



# /etc/krb5.conf

cat << EOF > /etc/krb5.conf
[libdefaults]
    default_realm = FOO.COM
    dns_lookup_realm = false
    dns_lookup_kdc = false
    ticket_lifetime = 24h
    forwardable = true
    udp_preference_limit = 1000000
    default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
    permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

[realms]
    FOO.COM = {
        kdc = kerberos.foo.com:88
        admin_server = kerberos.foo.com:749
        default_domain = foo.com
    }

[domain_realm]
    .foo.com = FOO.COM
     foo.com = FOO.COM

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOF



# /var/kerberos/krb5kdc/kdc.conf

cat << EOF > /var/kerberos/krb5kdc/kdc.conf
default_realm = FOO.COM

[kdcdefaults]
    v4_mode = nopreauth
    kdc_ports = 0

[realms]
    FOO.COM = {
        kdc_ports = 88
        admin_keytab = /etc/kadm5.keytab
        database_name = /var/kerberos/krb5kdc/principal
        acl_file = /var/kerberos/krb5kdc/kadm5.acl
        key_stash_file = /var/kerberos/krb5kdc/stash
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
        default_principal_flags = +preauth
    }
EOF



# /var/kerberos/krb5kdc/kadm5.acl

echo '*/admin@FOO.COM	    *' > /var/kerberos/krb5kdc/kadm5.acl



# SDSSSD

kdb5_util create -r CW.COM -s



# 

kadmin.local << EOF
addprinc root/admin
addprinc user1
ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/admin
ktadd -k /var/kerberos/krb5kdc/kadm5.keytab kadmin/changepw
exit
EOF







