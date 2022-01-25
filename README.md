# example_async_websocket
This project was created to test [micropython-async-websocket-client](https://pypi.org/project/micropython-async-websocket-client/) package.

It deals with [micropython](https://micropython.org), [ESP32S controller](https://ru.wikipedia.org/wiki/%D0%A4%D0%B0%D0%B9%D0%BB:ESP32_Espressif_ESP-WROOM-32_Dev_Board.jpg) and it's clones.

Main ideas of referenced above packeage are:

1. Create keep alive channel with server for data exchange.
2. Problems with data exchange with server doesn't affect main cotrol loop.
3. There is possibility to send control signals from server to controller.

# test schema
We will realize and test such schema:
[schema](imgs/schema.png)

So, we will start:
- ESP32 controller as client for server
- server 
- another client (Postman)

## Controller 
It will periodically send to server SOS message and wait for messages from server.
## Server 
Server will wait for messages from client and broadcast them to all other clients.
## Postam 
[Postman](https://www.postman.com/) is another client for server. It is not necessary, but useful.

Command to run test server:
```bash
uvicorn server:app --reload --workers 1 --host 0.0.0.0 --port 8000 --ws-ping-interval 10 --ws-ping-timeout 10 --log-level critical
```