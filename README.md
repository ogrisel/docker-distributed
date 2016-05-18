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

Alternatively it is possible to [install and manage Kubernetes by
your-self](http://kubernetes.io/docs/getting-started-guides/).

Here is the table of contents for this documentation:

- [The docker-distributed image](#the-docker-distributed-image)
- [Setting up a cluster using Kubernetes](#setting-up-a-cluster-using-kubernetes)
  - [Example setup with Google Container Engine](#example-setup-with-google-container-engine)
- [Setting up a cluster using Docker Compose](#setting-up-a-cluster-using-docker-compose)
  - [Example setup with Carina](#example-setup-with-carina)

DISCLAIMER: the configuration in this repository is not secure. If you want to
use this in production, please make sure to setup an HTTPS reverse proxy instead
of exposing the Jupyter 8888 port and the distributed service ports on a public
IP address and protect the Jupyter notebook access with a password.

If you want to setup a multi-user environment you might also want to extend this
configuration to use [Jupyter Hub](https://jupyterhub.readthedocs.io/en/latest/)
instead of accessing a Jupyter notebook server directly. Please note however
that the distributed workers will be run using the same unix user and therefore
this sample configuration cannot be used to implement proper multi-tenancy.


## The docker-distributed image

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

Register on the [Google Cloud Platform](https://cloud.google.com/), setup a
billing account and create a project with the Google Compute Engine API enabled.

Install the client SDK that includes the
[gcloud](https://cloud.google.com/sdk/gcloud/) command line interface or use the
in-browser Google Cloud Shell where `gcloud` installed.

Ensure that your client SDK is up to date:

```
$ gcloud components update
```

At the time of writing, the latest generation of Intel CPU architectures
available on GCE is the Haswell architecture. It is available only in [specific
zones](https://cloud.google.com/compute/docs/regions-zones/regions-zones). Using
modern CPU architectures is highly recommended for vector intensive CPU
workloads. In particular it makes it possible to get the most of optimized
linear algebra routines implemented by OpenBLAS and MKL internally used by NumPy
and SciPy for instance. Let us configure the zone used to provision the cluster
and create it:

```
$ gcloud config set compute/zone europe-west1-d
$ gcloud container clusters create cluster-1 \
    --num-nodes 3 \
    --machine-type n1-highcpu-32 \
    --scopes bigquery,storage-rw \
    --wait
Creating cluster cluster-1...done.
Created [https://container.googleapis.com/v1/projects/ogrisel/zones/europe-west1-d/clusters/cluster-1].
kubeconfig entry generated for cluster-1.
NAME       ZONE            MASTER_VERSION  MASTER_IP        MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
cluster-1  europe-west1-d  1.2.4           130.211.103.197  n1-highcpu-32  1.2.4         3          RUNNING
```

Other [machine types](https://cloud.google.com/compute/docs/machine-types) are
available if you would rather trade CPUs for RAM for instance. You can also
grant access to other GCP services via `--scopes` if you need. See the
[documentation](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)
for more details.

We further need to fetch the cluster credentials to get `kubectl` authorized
to connect to the newly provisioned cluster:

```
$ gcloud container clusters get-credentials cluster-1
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-1.
```

We can now deploy the kubernetes configuration onto the cluster:

```
$ git clone https://github.com/ogrisel/docker-distributed
$ cd docker-distributed
$ kubectl create -f kubernetes/
service "dscheduler" created
service "dscheduler-status" created
replicationcontroller "dscheduler" created
replicationcontroller "dworker" created
service "jupyter-notebook" created
replicationcontroller "jupyter-notebook" created
```
The containers are running in "pods":

```
$ kubectl get pods
NAME                     READY     STATUS              RESTARTS   AGE
dscheduler-hebul         0/1       ContainerCreating   0          32s
dworker-2dpr1            0/1       ContainerCreating   0          32s
dworker-gsgja            0/1       ContainerCreating   0          32s
dworker-vm3vg            0/1       ContainerCreating   0          32s
jupyter-notebook-z58dm   0/1       ContainerCreating   0          32s
```

we can get the logs of a specific pod with `kubectl logs`:

```
$ kubectl logs -f dscheduler-hebul
distributed.scheduler - INFO - Scheduler at:       10.115.249.189:8786
distributed.scheduler - INFO -      http at:       10.115.249.189:9786
distributed.scheduler - INFO -  Bokeh UI at:  http://10.115.249.189:8787/status/
distributed.core - INFO - Connection from 10.112.2.3:50873 to Scheduler
distributed.scheduler - INFO - Register 10.112.2.3:59918
distributed.scheduler - INFO - Starting worker compute stream, 10.112.2.3:59918
distributed.core - INFO - Connection from 10.112.0.6:55149 to Scheduler
distributed.scheduler - INFO - Register 10.112.0.6:55103
distributed.scheduler - INFO - Starting worker compute stream, 10.112.0.6:55103
bokeh.command.subcommands.serve - INFO - Check for unused sessions every 50 milliseconds
bokeh.command.subcommands.serve - INFO - Unused sessions last for 1 milliseconds
bokeh.command.subcommands.serve - INFO - Starting Bokeh server on port 8787 with applications at paths ['/status', '/tasks']
distributed.core - INFO - Connection from 10.112.1.1:59452 to Scheduler
distributed.core - INFO - Connection from 10.112.1.1:59453 to Scheduler
distributed.core - INFO - Connection from 10.112.1.4:48952 to Scheduler
distributed.scheduler - INFO - Register 10.112.1.4:54760
distributed.scheduler - INFO - Starting worker compute stream, 10.112.1.4:54760
```

we can also execute arbitrary commands inside the running containers with
`kubectl exec`, for instance to open an interactive shell session for debugging
purposes:

```
$ kubectl exec -ti dscheduler-hebul bash
root@dscheduler-hebul:/work# ls -l examples/
total 56
-rw-r--r-- 1 basicuser root  1344 May 17 11:29 distributed_joblib_backend.py
-rw-r--r-- 1 basicuser root 33712 May 17 11:29 sklearn_parameter_search.ipynb
-rw-r--r-- 1 basicuser root 14407 May 17 11:29 sklearn_parameter_search_joblib.ipynb
```

Our kubernetes configuration publishes HTTP endpoints with the `LoadBalancer`
type on external IP addresses (those can take one minute or two to show up):

```
$ kubectl get services
NAME                CLUSTER-IP       EXTERNAL-IP      PORT(S)             AGE
dscheduler          10.115.249.189   <none>           8786/TCP,9786/TCP   4m
dscheduler-status   10.115.244.201   130.211.50.206   8787/TCP            4m
jupyter-notebook    10.115.254.255   146.148.114.90   80/TCP              4m
kubernetes          10.115.240.1     <none>           443/TCP             10m
```

This means that is possible to point a browser to:

- http://146.148.114.90 to get access to the Jupyter notebook server
- http://130.211.50.206:8787/status to get the [distributed monitoring
  web interface](https://distributed.readthedocs.io/en/latest/web.html).

You can run the example notebooks from the `examples/` folder via the Jupyter
interface. In particular note that the distributed scheduler of the cluster
can be reached from any node under the host name `dscheduler` on port 8786.
You can check by typing the following snippet in a new notebook cell:

```python
>>> from distributed import Executor
>>> e = Executor('dscheduler:8786')
<Executor: scheduler=dscheduler:8786 workers=3 threads=36>
```

Please refer to the [distributed
documentation](https://distributed.readthedocs.io) to learn how to use the
executor interface to schedule computation on the cluster.

Once you are down with the analysis don't forget to save the results to some
external storage (for instance push your notebooks to some external git
repository). Then you can shutdown the cluster with:

```
$ gcloud container clusters delete cluster-1
```

WARNING: deploying kubernetes services with the `type=LoadBalancer` will cause
GCP to automatically provision dedicated firewall rules and load balancer
instances that are not automatically deleted when you shutdown the GKE cluster.
You have to delete those manually for instance by going to the "Networking" tab
of the Google Cloud Console web interface. Those additional firewall rules and
load balancers are billed on an hourly basis so don't forget to delete them
when you don't need them anymore.


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
8787 possibly on a different node).

As in the kubernetes example above you can run the example notebooks from the
`examples/` folder via the Jupyter interface on port 8888.

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
