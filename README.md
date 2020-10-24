# Docker Kerio Connect

## Create Container:
```
docker run --name="KerioConnect" \
-p 80:80/tcp -p 443:443/tcp -p 4040:4040/tcp \
-p 25:25/tcp -p 465:465/tcp -p 587:587/tcp \
-p 110:110/tcp -p 995:995/tcp \
-p 143:143/tcp -p 993:993/tcp \
-p 119:119/tcp -p 563:563/tcp \
-p 389:389/tcp -p 636:636/tcp \
-p 5222:5222/tcp -p 5223:5223/tcp \
-v /#PATH IN HOST#:/config \
vsc55/kerio-connect:latest
```
or
```
docker create --name "KerioConnect" \
-p 80:80/tcp -p 443:443/tcp -p 4040:4040/tcp \
-p 25:25/tcp -p 465:465/tcp -p 587:587/tcp \
-p 110:110/tcp -p 995:995/tcp \
-p 143:143/tcp -p 993:993/tcp \
-p 119:119/tcp -p 563:563/tcp \
-p 389:389/tcp -p 636:636/tcp \
-p 5222:5222/tcp -p 5223:5223/tcp \
-v /#PATH IN HOST#:/config \
vsc55/kerio-connect:latest

docker container start KerioConnect
```

---
## Network Host:
If we want to use the host adapter and thus avoid having to add all the ports we can do it in the following way:
```
docker run --name "KerioConnect" \
-v /#PATH IN HOST#:/config \
--network host \
vsc55/kerio-connect:latest
```

**NOTE: It is recommended to use a host network adapter and not a bridge if using google relay smpt since from the bridge it gives problems (kerio connects to google's smtp server but there is no data traffic).**
