import asyncio
import ssl
from websockets.asyncio.server import serve
import argparse
from datetime import datetime

async def handler(websocket):
    ssl_object = websocket.transport.get_extra_info('ssl_object')

    if ssl_object:
        client_cert = ssl_object.getpeercert()

        # Extract Common Name (CN) from certificate
        common_name = None
        if client_cert:
            # Parse subject
            subject = client_cert.get('subject', [])
            for item in subject:
                for attr in item:
                    if attr[0].lower() == 'commonname':
                        common_name = attr[1]
                        break
                if common_name:
                    break

        print(f"New client: {common_name}")
    else:
        print("New anonymous client.")

    try:
        async for message in websocket:
            print(f"{datetime.now()}: {message}")
            await websocket.send(f"Echo: {message}")
    except Exception as ex:
        print("Connection is closed.")

async def main():
    parser = argparse.ArgumentParser(description="Args like --key=value")
    parser.add_argument('--ssl', action="store_true", help="Switch TLS on.")
    parser.add_argument('--ssl-keyfile', type=str, help="Server's secret key file.")
    parser.add_argument('--ssl-certfile', type=str, help="Server's certificate file.")
    parser.add_argument('--ssl-password', default=None, type=str, help="Pass phrase.")
    parser.add_argument('--ssl-ca-cert', type=str, help="CA's certificate.")
    parser.add_argument('--ssl-certs-reqs', type=int, default=0, help="Flag for certificate requires.")
    parser.add_argument('--port', type=int, default=8000, help='Port number')

    args = parser.parse_args()

    ssl_context = None
    if args.ssl:
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.verify_mode = args.ssl_certs_reqs
        ssl_context.load_cert_chain(certfile=args.ssl_certfile, keyfile=args.ssl_keyfile, password=args.ssl_password)
        if args.ssl_certs_reqs:
            ssl_context.load_verify_locations(cafile=args.ssl_ca_cert)

    async with serve(handler, "0.0.0.0", args.port, ssl=ssl_context) as server:
        print(f"Server started on 0.0.0.0:{args.port}")
        await server.serve_forever()

asyncio.run(main())