import logging
import time
import aioprocessing
import asyncio
import multiprocessing
from .worker_process_base import WorkerProcessBase
from utils.event_defined import *

class TestProcess(WorkerProcessBase):
    def __init__(self, event_queue):
        super().__init__(100, event_queue)
        self._a = 100

    def block_init(self):
        time.sleep(3)
        self._a = 500

    def run(self):
        asyncio.run(self.aio_run())

    async def aio_run(self):
        await asyncio.sleep(1)
        print(f"lock = {self._queue_lock.value}")
        ret = self.call_event("abcd", 1, 2, 3)
        print(ret)
        print(self._a)
        await asyncio.sleep(1)
        

def foo(a, b, c):
    print(f"foo: {a}, {b}, {c}")

async def main():
    logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s [%(levelname)s] %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    )

    mgr = aioprocessing.AioManager()
    queue = mgr.Queue()
    p = TestProcess(queue)
    response_queue = p.get_response_queue()
    await asyncio.to_thread(p.block_init)
    p.start()
    e:Event = queue.get()
    foo(*e._args, **e._kwargs)
    response_queue.put(EventResponse(e._pid, e._event_id, 0, "okkk"))
    p.lock_event_queue()
    p.join()

if __name__ == "__main__":
    asyncio.run(main())

