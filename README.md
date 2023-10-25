# Senior DevOps Engineer Technical Challenge


## Scenario
The product the engineering team is working on will use an event-driven architecture based on kafka and you are responsible for the infrastructure. The backend team has 2 microservices: `consumer` and `producer` which consist of a python application that reads and writes messages to kafka. The team has asked you to set up a kafka cluster and deploy the microservices to it.
The system should be able to handle a large volume of data and ensure high availability.


## Challenge Overview

## Instructions

1. Kafka Cluster:

- Set up an Apache Kafka cluster with at least two brokers.
- Define a topic called `posts` and propose a partition and replication strategy. Explain your reasoning.
- Your setup should also help the backend developers to test their python application locally.

2. Containerization & Deployment:
- The python applications have an initial docker container, make some improvements to it using best practices for containerization.
- Deploy the applications to your Kubernetes cluster.

3. IaC:
- Set your infrastructure as code using best practices. Think of how would you upgrade the kafka version, add more brokers, manage topics, etc.

4. Observability (Optional):
- Set up (or explain how to set) monitoring and alerting for your Kafka cluster.

Notes:
- We recommend you to use minikube, but you can also use kind, aks, or any other provider of your choice.
- Ask questions if something is unclear, we are here to help :)
- It is okay to make some assumptions but document and communicate them.
- Your focus should not be on the python application, but on its infrastructure.

## Evaluation Criteria:
- Containerization and deployment
- Automation degree of the infrastructure
- Correct configuration of Kafka
- Accounting for availability, scalability, and fault tolerance

## Deliverables:
- Code
- Documentation
- Showcase your work in a live demo


# Proposed Solution

# Event-Driven App with kafka
- Architecture
- CI/CD
- Observability

#### Pre-requisite
* Makefile command
* Docker Desktop on Mac (Not included in prepare script)
* Minikube
* Infra contains deployment code:
    - Script to install needed tools
    - App Helm Chart
    - Kafka k8s deployment files
    - Observability config

## Run the below commands to bootstrap the setup:

To install necessary tools needed to start your minikube cluster
```
make prepare
```

To start minikube cluster
```
make minikube-start
```

to generate minikube dashboard endpoint
* Note: Run in separate terminal (Always running)
```
make minikube-dashboard
```

To start kafka server
```
make kafka
```

Build api docker image
```
make build IMAGEID=2.0
```

Deploy Prometheus and Grafana
```
make monitoring
```

Run the following commands to build and deploy api into minikube cluster
```
make deploy IMAGEID=2.0
```

Run the following commands to port-forward kafdrop for kafka web UI
```
make kafdrop-ui
```

Run the following commands to port-forward grafana web UI
```
make grafana-ui
```

Run the following command to stop minikube from running
```
make minikube-stop
```

Run the following command to delete minikube cluster
```
make minikube-delete
```

## Deployment Components
* Kafka deploys k8s in raft mode:
    - Kafka uses the Raft consensus protocol to manage its own metadata instead of relying on ZooKeeper.
    - KRaft simplifies Kafka’s architecture by removing the need for a separate coordination service. Kafka users and operators only have to deal with one system instead of two.
    - Raft uses quorum in which its requires majority of nodes to be running e.g a three-node controller cluster can survive one failure.
    - Replication factor of 3 because it will provide the right balance between performance and fault tolerance, also allows Kafka to provide high availability of data and prevent data loss if the broker goes down or cannot handle the request.
    - Partitioning of 3 so that `posts` topic can be distributed among the 3 brokers in the clusters for faster data rerieval and processing. Also, for high throughput and scalability by distributing the load across multiple consumers, each handling a subset of the partitions.
    - Kafka deploys as statefulset because its stateful app and k8s statefulset provides pods stable hostnames/name which is needed to maintain cluster communications. Pods get started in sequential order to be highly available.
    - Headless k8s service is used allows direct access to endpoints on the pod from within the cluster (rather than providing a single endpoint for multiple pods). This allows Kafka to control which pod is responsible for handling requests based on which broker is the leader for a requested topic.
    - Topic is created when the cluster start but i would rather recommend that producer application create the topic if its not yet created or using kafka web ui to create and manage kafka cluster.
    - kafdrop web ui is added for kafka management.
    - kafka can be updated by updating k8s deployment file and apply the changes. Pods will be updated one after the other (RollingUpdate).
    - Add more broker by increasing statefulset replica number.

* Consumer and Producer app:
    - Build image with docker.
    - Run as app as non-root for security.
    - Deploy using created helm chart.

* Observability:
    - Deploy grafana, prometheus, alertmanager and kafka-exporter using official helm chart.
    - Monitoring directory having helm chart value files for grafana and prometheus.
    - This deployment handles all configurations with no manual intervention.

* Makefile:
    - It makes running commands more concise and clear to read.
    - it will make the presentation to be more systematic and efficient.

* Helm: 
    - it is very handy to maintains k8s manifest files template and be used for different application deployment.
    - 
