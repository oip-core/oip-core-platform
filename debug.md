# Openshift behind CIAP

## SSL Passthrough routes

There are 3 external load balancers between internet & the openshift cluster:

[AWS NLB] -> [nginx] -> [AWS ELB] -> [Openshift]

Notes:
- Note that first AWS LB is of type NLB whereas the second is of type ELB Classic. NLB-type are newer and expose real client IPs.
- On the AWS \*LB, only port 80 & 443 are opened.
- nginx terminates all connections in order to log them
- nginx reopens an SSL connection to backend services when inbound connection requested it

Problem was related to SNI. When HA-proxy in OpenShift receives a packet to a passthrough route, it can't get the route's hostname from the HTTP header because it is encrypted... so it must find it elsewhere!

In order for nginx to send the requested hostname during the TLS ClientHello negociation, we need to add the following directives in the virtual host definition.

  proxy\_ssl\_server\_name on;
  proxy\_ssl\_name $host;

Adding this and restarting fixed the issue.

Curl was misleading in the various tests from various hosts on the chain for the same reason. The following command can't be used to test the passthrough route because the -H option forges an HTTP header that is encrypted and ha-proxy don't have access to it

[ha-proxy-pod] $ curl -kI -H 'Host: docker-registry-default.apps.ocp.lab-nxtit.com' https://localhost:443

Instead we must use one of the following commands (the first one requires a recent curl client).

[root@waf conf.d]# curl -k -I --connect-to docker-registry-default.apps.ocp.lab-nxtit.com:443:infra-elb.apps.ocp.lab-nxtit.priv:443 https://docker-registry-default.apps.ocp.lab-nxtit.com
[root@waf conf.d]# curl -k -I --resolve docker-registry-default.apps.ocp.lab-nxtit.com:443:infra-elb.apps.ocp.lab-nxtit.priv https://docker-registry-default.apps.ocp.lab-nxtit.com

Note: I don't know why by I couldn't run any of the previous two commands on the ha-proxy pod. The curl version is 7.29.0 and doesn't support the '--connect-to' option but the first command should have work.

