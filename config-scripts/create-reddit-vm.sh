#!/usr/bin/bash

GIVEN_NAME=$1
GENERATED_NAME="reddit-app-`mktemp --dry-run XXXXXXXX`"
INSTANCE=${GIVEN_NAME:-$GENERATED_NAME}


yc compute instance create \
	--name $INSTANCE \
	--hostname $INSTANCE \
	--memory=512M \
        --core-fraction=5 \
	--create-boot-disk name=reddit-full,size=12GB,image-family=reddit-full \
	--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
	--metadata serial-port-enable=1 \
	--ssh-key ~/.ssh/appuser.pub
