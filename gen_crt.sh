#!/usr/bin/env bash
# coding: utf-8
#
# $ ./gen_crt.sh --srv="IP or host name" --kl=<key length> --cn="client CN"
#
# --srv - default value is current hostname
# --kl - default value is 4096
# --cn - default value is result of command 'uuidgen'
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
SRV_NAME=$HOSTNAME

# Certificate validity period (10 years)
DAYS=3654

# common folder
TLS_DIR="./tls"

# Store for center authority (CA) root certificate
ROOT_DIR="./tls/rootCA"

# Path to server's certificate
SRV_DIR="./tls/"

# Path to clients directory
CLIENTS_DIR="./tls/clients"

# Client name
CLIENT_NAME=$(uuidgen)
# Path to client certificate
CLIENT_DIR="${CLIENTS_DIR}/${CLIENT_NAME}"

# CA root key name
ROOT_CA_KEY="${ROOT_DIR}/rootCA.key"

# CA root certificate name
ROOT_CA_CRT="${ROOT_DIR}/rootCA.crt.der"
ROOT_CA_CRT_PEM="${ROOT_DIR}/rootCA.crt.pem"

# key long
KEY_LENGTH=4096

regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

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
        --cn)
            CLIENT_NAME=${VALUE}
            CLIENT_DIR=${CLIENTS_DIR}/${CLIENT_NAME}
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

# create tls/clients
if [[ ! -d ${CLIENTS_DIR} ]]
then
    mkdir ${CLIENTS_DIR}
fi

if [[ ! -f ${ROOT_CA_KEY} ]]
then
    echo "Create root certificate and key..."
    # DER certificate is for using in controller,
    # current version of firmware (1.25.0) use only DER format
    openssl req -new -newkey rsa:${KEY_LENGTH} -keyout ${ROOT_CA_KEY} \
    -x509 -days ${DAYS} -outform DER -out ${ROOT_CA_CRT} \
    -subj "/CN=root_ca_center"

    # ...and uvicorn uses only PEM
    openssl x509 -inform der -in ${ROOT_CA_CRT} -out ${ROOT_CA_CRT_PEM}
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
if [[ ${SRV_NAME} =~ $regex ]]; then
    # srv_name is ip4
    echo -e "authorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nsubjectAltName=${SRV_NAME}" > server.ext
    openssl x509 ${SRV_CSR} -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} \
        -CAcreateserial -out ${SRV_CERT} -days ${DAYS} -extfile server.ext
else
    openssl x509 -req -in ${SRV_CSR} -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} \
        -CAcreateserial -out ${SRV_CERT} -days ${DAYS}
fi

echo "Create bundle: server_cert + server_key"
cat ${SRV_CERT} ${SRV_KEY} > ${SRV_BUNDLE}

# create tls/client
if [[ ! -d ${CLIENT_DIR} ]]
then
    mkdir "${CLIENT_DIR}"
fi

echo "Create client private key"
openssl genrsa -out "${CLIENT_DIR}/${CLIENT_NAME}.key" ${KEY_LENGTH}

echo "Create CSR for client. Attention: name of client is '${CLIENT_NAME}'"
openssl req -new -key "${CLIENT_DIR}/${CLIENT_NAME}.key" -out "${CLIENT_DIR}/${CLIENT_NAME}.csr" \
    -subj "/CN=${CLIENT_NAME}"

echo "Create client certificate"
openssl x509 -req -in "${CLIENT_DIR}/${CLIENT_NAME}.csr" \
    -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial \
    -out "${CLIENT_DIR}/${CLIENT_NAME}.crt" -days ${DAYS}

echo "Copy certificates to project catalog"
cp "${CLIENT_DIR}/${CLIENT_NAME}.key" src/
cp "${CLIENT_DIR}/${CLIENT_NAME}.crt" src/
cp "${ROOT_CA_CRT}" src/
