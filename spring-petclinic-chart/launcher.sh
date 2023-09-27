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

service_names=("resources" "api-gateway" "customers" "vets" "visits")

for service_name in ${service_names[@]}
do
	helm upgrade --install spring-$service_name chart-$service_name \
		--set namespace=$ENVIRONNMENT \
		--set repository_prefix=michelnguyenfr \
		--set dbhost_customers=$DBHOST \
		--set dbhost_vets=$DBHOST \
		--set dbhost_visits=$DBHOST \
		--set dbname_visits=visitsdb \
		--set dbuser_visits=admin \
		--set dbname_customers=customersdb \
		--set dbuser_customers=admin \
		--set dbname_vets=vetsdb \
		--set dbuser_vets=admin \
		-n $ENVIRONNMENT
done


echo
echo "You can track the progress with the following command:"
echo "kubectl get pods -n $ENVIRONNMENT -w"
echo
echo "Get the Load Balancer URL with the following command:"
echo "kubectl get svc -n $ENVIRONNMENT"
