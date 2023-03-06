
<picture>
 <source media="(prefers-color-scheme: dark)" srcset="YOUR-DARKMODE-IMAGE">
 <source media="(prefers-color-scheme: light)" srcset="YOUR-LIGHTMODE-IMAGE">
 <img alt="YOUR-ALT-TEXT" src="YOUR-DEFAULT-IMAGE">
</picture>


# Sui for Node Operators

## Overview

This document aims to be a complete reference for anything related to operating a node on the Sui Platform.


`runbooks/` You can use these to find helpful notes around node operation, these of course depend how you've chosen to run your node
.



## papers

- [The Sui Smart Contracts Platform](https://github.com/MystenLabs/sui/blob/main/doc/paper/sui.pdf)
- [FastPay: High-Performance Byzantine Fault Tolerant Settlement](https://arxiv.org/pdf/2003.11506.pdf)
- [Narwhal and Tusk: A DAG-based Mempool and Efficient BFT Consensus](https://arxiv.org/pdf/2105.11827.pdf)



# Sui Runbooks

- [Basics - Start/Stop/Restart etc.](basics.md)
- [Logs](./logs.md)
- [Metrics](./metrics.md)
- [Connectivity](./connectivity.md)
- [Updating Sui Node](update.md)
- [Storage](storage.md)
- [Key Management](keys.md)
- [Sui Client](sui-client.md)
- [Troubleshooting](troubleshooting.md)





## Basic Operations


# Starting, stopping, and restarting Sui Node Basics

When an update is required to the Sui Node software the following can be used. Follow the relevant systemd or docker-compose runbook depending on your deployment type. It is highly unlikely that you will want to restart with a clean database.

## **systemd**

- Start

```
sudo systemctl start sui-node
```

- Stop

```
sudo systemctl stop sui-node
```

- Restart

```
sudo systemctl restart sui-node
```

- Check status

```
sudo systemctl status sui-node
```

## **docker-compose**

-  Start

```
sudo docker-compose up
```

- Start in detached mode

```shell
sudo docker-compose up -d
```

- Stop

```shell
sudo docker-compose down
```

- Restart

```shell
sudo docker-compose restart
```

- Check status

```shell
sudo docker-compose ps
```

## Manually starting sui-node (without systemd/docker)

```shell
sudo /usr/local/bin/sui-node --config-path /opt/sui/config/sui-node.yaml
```




# Connectivity

Confirm protocol connectivity:

```shell
nc -zv -G 5 myvalidator.myorg.com 8080
```

Review iptables:

```shell
sudo iptables -vnL
```

Socket analysis, is the node listening on the required ports:

```shell
ss -nl | egrep "(808[01234])"
```

Packet capture:

```shell

```


# Monitoring


# Metrics

View Sui Node metrics

## **Systemd**

- View all metrics

```shell
curl http://localhost:9184/metrics
```

- Search for a particular metric

```shell
curl http://localhost:9184/metrics | grep <METRIC>
```

## **Docker Compose**

- The container ID is required first

```shell
sudo docker-compose ps
```

```shell
sudo docker logs -f <$CONTAINER_ID>
```

^ TODO





# Logs

View Sui Node logs

## **Systemd**

- Assumes systemd unit is `sui-node`

- View and follow 

```shell
journalctl -u sui-node -f
```

- Search for a particular match

```shell
journalctl -u sui-node -g <SEARCH_TERM>
```

## **Docker Compose**

- View and follow

```shell
sudo docker-compose logs -f validator
```

- By default all logs are output, limit this using `--since`

```shell
sudo docker logs --since 10m -f validator
```






## Key Management

https://docs.google.com/document/d/1VeSorPsPMJUc93eETW6Cam5xGWoi2GjwcB4oVJi02rI/edit#


## Validator Keys

### Account Key
account.key
key type:
ed25519
purpose:
controls assets for staking
can live in HSM:
could potentially be cold (or stored 100% in HSM)
Response  Time Requirement

### Network Key
network.key
key type:
ed25519
Purpose:
narwhal primary, sui p2p, and metrics push TLS
Can Live in HSM:
No, TLS Libs can’t use remote signers
Response Time Requirement

### Worker Key
worker.key
key type:
ed25519
Purpose:
Used for TLS Authentication
Used to validate narwhal workers
Can Live in HSM:
No, needs to be in memory (TLS Lib not setup for remote signers)
Response Time Requirement

### Protocol Key
protocol.key
key type:
bls12381
purpose:
Used by validators to sign transactions for approval
used for narwhal consensus to sign rounds
can live in HSM:
no, needs to be in memory for low-latency operations
Response Time Requirement



## tally rule

2f+1 required to slash epoch rewards (stake or validators?)





# Updating Sui Node 

When an update is required to the Sui Node software the following can be used. Follow the relevant systemd or docker-compose runbook depending on your deployment type. It is highly unlikely that you will want to restart with a clean database.

## **systemd**

- assumes sui-node lives in `/opt/sui/bin/`
- assumes systemd service is named sui-node
- DO NOT delete sui databases

1. Stop sui-node systemd service

```
sudo systemctl stop sui-node
```

2. Fetch the new sui-node binary

```
SUI_SHA=<INSERT_SUI_SHA_HERE>
wget https://sui-releases.s3.us-east-1.amazonaws.com/${SUI_SHA}/sui-node
```

3. Update and move the new binary 

```
chmod +x sui-node
sudo mv sui-node /opt/sui/bin/
```

4. start sui-node systemd service

```
sudo systemctl start sui-node
```

## **docker-compose**

- DO NOT delete sui databases

1. Stop docker-compose

```
sudo docker-compose down
```

2. Update docker-compose.yaml to reference new image

```
-    image: mysten/sui-node:<OLD_SUI_SHA>
+    image: mysten/sui-node:<NEW_SUI_SHA>
```

3. Start docker-compose in detached mode:

```
sudo docker-compose up -d
```




# Troubleshooting

## `sui-node` startup issues

Confirm the location and contents of validator.yaml config file:

- Ensure that `sui-node --config-path [path_to]/validator.yaml` is pointed at a valid config file that is readable by `sui-node`.
- Confirm that each of the keyfiles exist and are readable by `sui-node`, eg:
  ```
  protocol-key-pair:
    path: /opt/sui/key-pairs/protocol.key
  ```
- Confirm that you've set the external_address in your `validator.yaml` to the publicly addressable hostname of your machine. Eg:

  ```
  p2p-config:
  external-address: /dns/validator.testnet.sui.io/udp/8084
  ```

Make sure you're running the correct version of `sui-node`:

```
$ curl https://sui-releases.s3.us-east-1.amazonaws.com/57b5688927544b18413ed3f9e2c7b85b8b7090a9/sui-node -o /home/ubuntu/sui-node
$ md5sum /home/ubuntu/sui-node
67ecedca3135e9be9ee16604f5a3c6b5  sui-node
$ md5sum /opt/sui/bin/sui-node
67ecedca3135e9be9ee16604f5a3c6b5  sui-node
```




# Storage

All Sui related data is stored by default under /opt/sui/db. This is controlled in the sui node configuration file (sui-node.yaml).

## **Systemd**

- What is the size of the local Sui database?

```shell
du -sh /opt/sui/db/authorities_db
du -sh /opt/sui/db/consensus_db
```

- Delete the local Sui databases
anges

```shell
sudo systemctl stop sui-node
sudo rm -rf /opt/sui/db/authorities_db /opt/sui/db/consensus_db
```

## **Docker Compose**

- What is the size of the local Sui database?

```shell
# get the volume location on disk
sudo docker volume inspect docker_suidb
# get the size of the volume on disk
sudo du -sh /var/lib/docker/volumes/docker_suidb/_data
```

- Delete the local Sui databases

```shell
sudo docker-compose down -v
```


