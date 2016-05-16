# Docker provisioning of Python Distributed compute cluster

This repo hosts some sample configuration to set up docker-containerized
environments for interactive cluster computing in Python with [Jupyter
notebook](http://jupyter.org/) and
[distributed](https://distributed.readthedocs.org/)  possibly in conjunction
with [dask](http://dask.pydata.org/) and other tools from the PyData and SciPy
ecosystems.

This docker image is meant to be run with container orchestration tools such as
Docker [Swarm](https://docs.docker.com/swarm/) +
[Compose](https://docs.docker.com/compose/) or
[Kubernetes](http://kubernetes.io/), either on premise or on public clouds. The
configuration files in this repo are vendor agnostic and only rely upon Open
Source tools.

The Docker Swarm API is provided as a hosted service by:

- [Azure Container Service](https://azure.microsoft.com/en-us/services/container-service/)
- [Carina by Rackspace](https://getcarina.com/)

The Kubernetes API is provided as a hosted service by:

- [Google Container Engine](https://cloud.google.com/container-engine/)
- [OpenShift by Red Hat](https://www.openshift.com/)


DISCLAIMER: the configuration in this repository is not secure. If you want to
use this in production, please make sure to setup an HTTPS reverse proxy instead
of exposing the Jupyter 8888 port and the distributed service ports on a public
IP address and protect the Jupyter notebook access with a password.

If you want to setup a multi-user environment you might also want to extend this
configuration to use [Jupyter Hub](https://jupyterhub.readthedocs.io/en/latest/)
instead of accessing a Jupyter notebook server directly. Please note however
that the distributed workers will be run using the same unix user and therefore
this sample configuration cannot be used to implement proper multi-tenancy.


## The distributed docker image

The `Dockerfile` file in this repo can be used to build a docker image
with all the necessary tools to run our cluster, in particular:

- `conda` and `pip` to install additional tools and libraries,
- `jupyter` for the notebook interface accessed from any web browser,
- `dask` and `distributed`,
- `psutil` and `bokeh` (useful for the [cluster monitoring web interface](
   https://distributed.readthedocs.io/en/latest/web.html)).

It is also possible to install additional tools using the `conda` and `pip`
command from within a running container.

The master branch of this github repo is synchronized with the
`ogrisel/distributed:latest` image on the docker registry:

https://hub.docker.com/ogrisel/distributed/

Pull and run the latest version of this container on your local docker engine as
follow:

```
$ docker pull ogrisel/distributed:latest
latest: Pulling from ogrisel/distributed
[...]
$ docker run -ti --rm ogrisel/distributed bash
root@37dba41caa3c:/work# ls -l examples/
total 56
-rw-rw-r-- 1 basicuser root  1344 May 11 07:44 distributed_joblib_backend.py
-rw-rw-r-- 1 basicuser root 33712 May 11 07:44 sklearn_parameter_search.ipynb
-rw-rw-r-- 1 basicuser root 14407 May 11 07:44 sklearn_parameter_search_joblib.ipynb
```

Alternatively it is also possible to re-build the `ogrisel/distributed` image
using the `docker build` command:

```
$ git clone https://github.com/ogrisel/docker-distributed
$ cd docker-distributed
$ docker build -t ogrisel/distributed .
[...]
```

This image will be used to run 3 types of services:

- the `jupyter notebook` server,
- the `distributed` scheduler service,
- one `distributed` worker per-host in the compute cluster.

Those services can be easily orchestrated on public cloud providers with the one
of the following tools.

## Setting up a cluster using Kubernetes

[kubectl](http://kubernetes.io/docs/hellonode/) is a client tool to configure
and launch containerized services on a Kubernetes cluster. It can read the yaml
configuration files in the `kubernetes/` folder of this repository.


### Example setup with Google Container Engine

TODO

## Setting up a cluster using Docker Compose

[docker-compose](https://docs.docker.com/compose/) is a client tool to configure
and launch containerized services on a Docker Swarm cluster. It reads the
configuration of the cluster in the `docker-compose.yml` file of this
repository.

### Example setup with Carina

Create an account at https://getcarina.com and follow the [carina get started
instructions](https://getcarina.com/docs/getting-started/getting-started-carina-cli/)
to install the `docker` client and the `carina` command line tool.

Once you are setup, create a new carina cluster and configure your shell
environment variables so that your `docker` client can access it:

```
$ carina create --nodes=3 --wait cluster-1
ClusterName         Flavor              Nodes               AutoScale           Status
cluster-1           container1-4G       3                   false               active
$ eval $(carina env cluster-1)
```

If you installed the `dvm` tool, you can make sure to use a version of a the
docker client that matches the version of docker of the carina cluster by
typing:

```
$ dvm use
Now using Docker 1.10.3
```

Check that you `docker` client can access the carina cluster using the `docker
ps` and `docker info` commands.

Install the `docker-compose` client:

```
$ pip install docker-compose
```

Deploy the Jupyter and distributed services as conigured in the
`docker-compose.yml` file of this repo:

```
$ git clone https://github.com/ogrisel/docker-distributed
$ cd docker-distributed
$ docker-compose up -d
Creating network "dockerdistributed_distributed" with driver "overlay"
Pulling dscheduler (ogrisel/distributed:latest)...
2fc95c02-b444-4730-bfb1-bd662e2e044e-n3: Pulling ogrisel/distributed:latest... : downloaded
2fc95c02-b444-4730-bfb1-bd662e2e044e-n1: Pulling ogrisel/distributed:latest... : downloaded
2fc95c02-b444-4730-bfb1-bd662e2e044e-n2: Pulling ogrisel/distributed:latest... : downloaded
Creating dscheduler
Creating dockerdistributed_dworker_1
Creating jupyter
```

Increase the number of `distributed` workers to match the number of nodes in the
carina cluster:

```
$ docker-compose scale dworker=3
Creating and starting dockerdistributed_dworker_2 ... done
Creating and starting dockerdistributed_dworker_3 ... done
```

Use the `docker ps` command to find out the public IP address and port of the
public Jupyter notebook interface (on port 8888) and the [distributed monitoring
web interface](https://distributed.readthedocs.io/en/latest/web.html) (on port
8787 possibly on a different node). You can run the example notebooks from the
`examples/` folder via the Jupyter interface on port 8888. In particular note
that the distributed scheduler of the cluster can be reached from any node under
the host name `dscheduler` on port 8786. You can check by typing the following
snippet in a new notebook cell:

```python
>>> from distributed import Executor
>>> e = Executor('dscheduler:8786')
<Executor: scheduler=dscheduler:8786 workers=3 threads=36>
```

Please refer to the [distributed
documentation](https://distributed.readthedocs.io) to learn how to use the
executor interface to schedule computation on the cluster.

It is often useful to check that you don't get any error in the logs when
running the computation. You can access the aggregate logs of all the running
services with:

```
$ docker-compose logs -f
[...]
```

Sometimes it can also be useful to open a root shell session in the container
that run Jupyter notebook process with `docker exec`:

```
$ docker exec -ti jupyter bash
root@aff49b550f0c:/work# ls

bin  examples  miniconda  requirements.txt
```

When you are done with your computation, upload your results to some external
storage server or to github and don't forget to shutdown the cluster:

```
$ docker-compose down
$ carina rm cluster-1
$ dvm deactivate
```
