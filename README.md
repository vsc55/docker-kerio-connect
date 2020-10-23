# Docker Kerio Connect

## Create Container:
```
docker create --name KerioConnect -v ~/kerio_connect:/config -p 4040:4040/tcp 80:80/tcp 443:443/tcp 25:25/tcp 465:465/tcp 587:587/tcp 110:110/tcp 995:995/tcp 143:143/tcp 993:993/tcp 119:119/tcp 563:563/tcp 389:389/tcp 636:636/tcp 5222:5222/tcp 5223:5223/tcp vsc55/kerio-connect:latest
docker container start KerioConnect
```
or
```
docker run -v ~/kerio_connect:/config -p 4040:4040/tcp 80:80/tcp 443:443/tcp 25:25/tcp 465:465/tcp 587:587/tcp 110:110/tcp 995:995/tcp 143:143/tcp 993:993/tcp 119:119/tcp 563:563/tcp 389:389/tcp 636:636/tcp 5222:5222/tcp 5223:5223/tcp vsc55/kerio-connect:latest
```

---
## Network Host:
If we want to use the host adapter and thus avoid having to add all the ports we can do it in the following way:
```
docker create --name KerioConnect -v ~/kerio_connect:/config --network host vsc55/kerio-connect:latest
```

**NOTE: It is recommended to use a host network adapter and not a bridge if using google relay smpt since from the bridge it gives problems (kerio connects to google's smtp server but there is no data traffic).**
