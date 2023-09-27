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
	--set dbhost_customers=$DBHOST \
	--set dbhost_vets=$DBHOST \
	--set dbhost_visits=$DBHOST \
	-n $ENVIRONNMENT

echo "pause for 10sec for the resources to be online before deploying the microservices"
sleep 10 

helm install spring-api-gateway chart-api-gateway \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=$DBHOST \
	--set dbhost_vets=$DBHOST \
	--set dbhost_visits=$DBHOST \
	-n $ENVIRONNMENT

helm install spring-customers chart-customers \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=$DBHOST \
	--set dbhost_vets=$DBHOST \
	--set dbhost_visits=$DBHOST \
	--set dbname_visits:visitsdb \
	--set dbuser_visits=admin \
	--set dbname_customers=customersdb \
	--set dbuser_customers=admin \
	--set dbname_vets=vetsdb \
	--set dbuser_vets=admin \
	-n $ENVIRONNMENT
	
helm install spring-vets chart-vets \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=customersdb.$DBHOST \
	--set dbhost_vets=vetsdb.$DBHOST \
	--set dbhost_visits=visitsdb.$DBHOST \
	--set dbname_visits:visitsdb \
	--set dbuser_visits=admin \
	--set dbname_customers=customersdb \
	--set dbuser_customers=admin \
	--set dbname_vets=vetsdb \
	--set dbuser_vets=admin \
	-n $ENVIRONNMENT

helm install spring-visits chart-visits \
	--set namespace=$ENVIRONNMENT \
	--set repository_prefix=michelnguyenfr \
	--set dbhost_customers=$DBHOST \
	--set dbhost_vets=$DBHOST \
	--set dbhost_visits=$DBHOST \
	--set dbname_visits:visitsdb \
	--set dbuser_visits=admin \
	--set dbname_customers=customersdb \
	--set dbuser_customers=admin \
	--set dbname_vets=vetsdb \
	--set dbuser_vets=admin \
	-n $ENVIRONNMENT

echo
echo "You can track the progress with the following command:"
echo "kubectl get pods -n $ENVIRONNMENT -w"
echo
echo "Get the Load Balancer URL with the following command:"
echo "kubectl get svc -n $ENVIRONNMENT"
