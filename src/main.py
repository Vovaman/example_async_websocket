import uasyncio as a
from main_f import read_loop, blink_loop

async def main():

    tasks = [read_loop(), blink_loop()]
    await a.gather(*tasks)

a.run(main())
