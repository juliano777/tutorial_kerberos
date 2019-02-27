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


