# example_async_websocket
Test project. Demonstrates how to use [micropython-async-websocket-client](https://pypi.org/project/micropython-async-websocket-client/) package.

Description will be soon...


Command to run test server:
```bash
uvicorn server:app --reload --workers 1 --host 0.0.0.0 --port 8000 --ws-ping-interval 10 --ws-ping-timeout 10 --log-level critical
```