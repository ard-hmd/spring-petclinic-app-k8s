#!/bin/bash

ENVIRONNMENT="$1"
DBHOST="$2"

for var in "ENVIRONNMENT" "DBHOST"; do
    if [[ -z "${!var}" ]]; then
        echo "Usage : $0 ENV DBHOST"
        echo "e.g : $0 qa c6wqjjevzbkj.eu-west-3.rds.amazonaws.com:3306"
        break
    fi
done

kubectl create namespace $ENVIRONNMENT && \
kubectl create secret generic customers-db-mysql --from-literal=mysql-root-password=password --namespace $ENVIRONNMENT && \
kubectl create secret generic vets-db-mysql --from-literal=mysql-root-password=password --namespace $ENVIRONNMENT && \
kubectl create secret generic visits-db-mysql --from-literal=mysql-root-password=password --namespace $ENVIRONNMENT

helm install spring-resources chart-resources \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	-n $ENVIRONNMEN
	T
echo "pause for 20sec for the resources to be online before deploying the microservices"
sleep 20 

helm install spring-api-gateway chart-api-gateway \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	-n $ENVIRONNMENT

helm install spring-customers chart-customers \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	-n $ENVIRONNMENT
	
helm install spring-vets chart-vets \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	-n $ENVIRONNMENT

helm install spring-visits chart-visits \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	-n $ENVIRONNMENT

echo
echo "You can track the progress with the following command:"
echo "kubectl get pods -n $ENVIRONNMENT -w"
echo
echo "Get the Load Balancer URL with the following command:"
echo "kubectl get svc -n $ENVIRONNMENT"
