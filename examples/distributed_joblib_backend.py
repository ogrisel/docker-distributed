from tornado import gen

from distributed import Executor
from distributed.utils import sync
from joblib._parallel_backends import ParallelBackendBase, AutoBatchingMixin


class DistributedBackend(ParallelBackendBase, AutoBatchingMixin):
    MIN_IDEAL_BATCH_DURATION = 0.2
    MAX_IDEAL_BATCH_DURATION = 1.0

    def __init__(self, scheduler_host='127.0.0.1:8786'):
        self.executor = Executor(scheduler_host)

    def configure(self, n_jobs=1, parallel=None, **backend_args):
        return self.effective_n_jobs(n_jobs)

    def effective_n_jobs(self, n_jobs=1):
        n = sync(self.executor.loop, self.executor.scheduler.ncores)
        return sum(n.values())

    def apply_async(self, func, callback=None):
        future = self.executor.submit(func, pure=False)

        @gen.coroutine
        def callback_wrapper():
            result = yield future._result()
            # Hope its safe that the callback happen in a separate thread
            # without locking
            callback(result)

        self.executor.loop.add_callback(callback_wrapper)

        # monkey patch to achieve AsyncResult API
        # Also calling result twice seems odd
        future.get = future.result
        return future

    def terminate(self):
        self.executor.shutdown()


#register_parallel_backend('distributed', DistributedParallel)