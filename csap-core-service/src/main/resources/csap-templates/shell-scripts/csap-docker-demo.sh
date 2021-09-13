# demo and install, launch csap docker demo containers for csap-agent, ldap and installer




print_section "Starting csap demo on port 9011 , web credentials: csap / csap"

#
# optional for host docker: --pid=host --volume /var/run/docker.sock:/var/run/docker.sock \
# warning: this does a chmod 777 /var/run/docker.sock; post shutdown do: sudo chmod 770 /var/run/docker.sock
#
docker run \
	--rm --detach \
	--name csap-demo \
	--publish 9011:9011 --publish 9013:9013 --publish 9021:9021 --publish 9023:9023 \
	--env dockerHostFqdn=$(hostname --long) \
	csapplatform/demo:latest
	
	
	
print_line "In ~2 minutes, open http://$(hostname --long):9011"

print_section "to monitor init progress -  use csap docker log viewer, or run: docker logs --follow csap-demo"
	
exit ;

print_section "Starting open ldap server on host port 389"

if ! $(wait_for_port_free 389 5 "ldap server") ; then
	print_separator "ldap server port still running";
	print_line "Exiting: CSAP host dashboard port explorer can be used to identify process holding port"
	exit 90 ;
fi ;

docker run \
	--rm --detach \
	--name ldap-server \
	--publish 389:1389 \
	csapplatform/ldap-server


print_section "Starting ldap admin web app on host port 8080"


if ! $(wait_for_port_free 8080 5 "ldap server web app") ; then
	print_separator "Warning: ldap server port still running";
	print_line "Exiting: CSAP host dashboard port explorer can be used to identify process holding port"
	exit 90 ;
fi ;

docker run \
	--rm --detach \
	--name ldap-ui \
	--publish 8080:80 \
	--env PHPLDAPADMIN_LDAP_HOSTS=$(hostname --long)  \
	--env PHPLDAPADMIN_HTTPS=false \
	osixia/phpldapadmin:latest
	
print_with_head "Use csap host dashboard to view and launch, or open http://$(hostname --long):8080"	

delay_with_message 5 "csap login test credentials: admin/admin; LDAP test credentials:  cn=admin,dc=example,dc=org, pass: admin" ; 



#
#  publish - after builds, requires 
#

cred="xxx"
tag="xxx"


print_section "publishing images tagged: '$tag'"

if [ "$cred" == "xxx" ] || [ "$tag" == "xxx" ] ; then
	print_error "password and tag must be set"
	exit 99 ;
fi ;

docker login --username=csapplatform --password=$cred
exit_on_failure "$?" "Failed login"


print_section "pushing: csapplatform/installer:latest"

docker push csapplatform/installer:latest
docker tag  csapplatform/installer:latest csapplatform/installer:$tag
docker push csapplatform/installer:$tag


print_section "pushing: csapplatform/demo:latest"

docker push csapplatform/demo:latest
docker tag csapplatform/demo:latest csapplatform/demo:$tag
docker push csapplatform/demo:$tag


print_section "pushing: csapplatform/demo-snapshot:latest"
docker tag csapplatform/demo:latest csapplatform/demo-snapshot:latest
docker push csapplatform/demo-snapshot:latest




