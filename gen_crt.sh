#!/usr/bin/env bash
# coding: utf-8
#
# $ sudo gen_crt.sh --srv=<your_server_name>
#
# script generates certificates, arranging them in directory structure:
# tls
#  - root
#      - rootCA.crt  # root certificate for certificates authority center
#      - rootCA.key  # private key for root certificate
#  - server
#      - <server_name>.crt   # server's certificate
#      - <server_name>.key   # private key for server's certificate
#      - <server_name>.pem   # <server_name>.crt + <server_name>.key
#  - client
#      - <client>.crt   # client's certificate
#      - <client>.key   # private key for client's certificate
#

# Server Name
SRV_NAME="server"

# Certificate validity period (10 years)
DAYS=3654

# common folder
TLS_DIR="./tls"

# Store for center authority (CA) root certificate
ROOT_DIR="./tls/rootCA"

# Path to server's certificate
SRV_DIR="./tls/"

# Path to client's certificate
CLIENT_DIR="./tls/client"

# CA root key name
ROOT_CA_KEY="${ROOT_DIR}/rootCA.key"

# CA root certificate name
ROOT_CA_CRT="${ROOT_DIR}/rootCA.crt"

# key long
KEY_LENGTH=4096

# Data
#COUNTRY="RU"  # Country Name
#STATE="Moscow"  # State or Province
#LOCALITY="Moscow"  # Locality Name
#ORG="Ostec-SMT"  # Organization Name
#OU="IT-Dept"  # Organizational Unit Name
#CN="ostec-ca-server"  # Common Name
#EMAIL="support@example.com"  # Email Address

while [[ "$1" != "" ]]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case ${PARAM} in
        --srv)
            SRV_NAME=${VALUE}
            SRV_DIR=${SRV_DIR}${SRV_NAME}
            ;;
        --kl)
            KEY_LENGTH=${VALUE}
            ;;
        *)
            echo "ERROR: unknown parameter \"${PARAM}\""
            exit 1
            ;;
    esac
    shift
done

# create tls folder
if [[ ! -d ${TLS_DIR} ]]
then
    mkdir ${TLS_DIR}
fi

# create tls/root
if [[ ! -d ${ROOT_DIR} ]]
then
    mkdir ${ROOT_DIR}
fi

# create tls/server
if [[ ! -d ${SRV_DIR} ]]
then
    mkdir ${SRV_DIR}
fi

# create tls/client
if [[ ! -d ${CLIENT_DIR} ]]
then
    mkdir ${CLIENT_DIR}
fi

if [[ ! -f ${ROOT_CA_KEY} ]]
then
    echo "Create root certificate and key..."
    openssl req -new -newkey rsa:${KEY_LENGTH} -nodes -keyout ${ROOT_CA_KEY} \
     -x509 -days ${DAYS} -out ${ROOT_CA_CRT} \
     -subj "/CN=root_ca_center"
fi

SRV_KEY=${SRV_DIR}/${SRV_NAME}.key
SRV_CERT=${SRV_DIR}/${SRV_NAME}.crt
SRV_CSR=${SRV_DIR}/${SRV_NAME}.csr
SRV_BUNDLE=${SRV_DIR}/${SRV_NAME}.pem

echo "Create private key for server certificate..."
openssl genrsa -out ${SRV_KEY} ${KEY_LENGTH}

echo "Create request"
openssl req -sha256 -new -key ${SRV_KEY} -out ${SRV_CSR} \
        -subj "/CN=${SRV_NAME}"

echo "Sign the CSR by own root CA certificate"
openssl x509 -req -in ${SRV_CSR} -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} \
    -CAcreateserial -out ${SRV_CERT} -days ${DAYS}

echo "Create bundle: server_cert + server_key"
cat ${SRV_CERT} ${SRV_KEY} > ${SRV_BUNDLE}

echo "Create client private key"
openssl genrsa -out ${CLIENT_DIR}/client.key ${KEY_LENGTH}

echo "Create CSR for client. Attention: name of client is 'first_client'"
openssl req -new -key ${CLIENT_DIR}/client.key -out ${CLIENT_DIR}/client.csr \
    -subj "/CN=first_client"

echo "Create client certificate"
openssl x509 -req -in ${CLIENT_DIR}/client.csr \
    -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial \
    -out ${CLIENT_DIR}/client.crt -days ${DAYS}
