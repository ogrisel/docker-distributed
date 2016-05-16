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


## The distributed docker image

The `Dockerfile` file in this repo can be used to build a docker image
with all the necessary tools to run our cluster, in particular:

- `conda` and `pip`,
- `jupyter`,
- `dask` and `distributed`,
- `bokeh` (useful for the cluster monitoring [web interface](
   https://distributed.readthedocs.io/en/latest/web.html)).

It is also possible to install additional tools using the `conda` and `pip`
command from within a running container.

The master branch of this github repo is synchronized with the
`ogrisel/distributed:latest` image on the docker registry:

https://hub.docker.com/ogrisel/distributed/

Pull and run the latest version of this container on your local docker engine as
follow:

```bash
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

```bash
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

```bash
$ carina create --nodes=3 --wait cluster-1
$ eval $(carina env cluster-1)
```

TODO dvm

Check that you `docker` client can access the carina cluster using the `docker
ps` and `docker info` commands.

Install the `docker-compose` client:

```bash
$ pip install docker-compose
```

TODO
