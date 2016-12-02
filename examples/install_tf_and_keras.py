from distributed import Client
from subprocess import check_call

TF_URL = 'https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.12.0rc0-cp35-cp35m-linux_x86_64.whl'

def install_libs():
    check_call('pip install'.split() + [TF_URL])
    check_call('pip install keras'.split())

    
install_libs()

c = Client('dscheduler:8786')
c.run(install_libs)