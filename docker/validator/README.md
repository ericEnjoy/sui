
# Run a Sui Validator node on Testnet using Docker Compose

Tested using:
- ubuntu 20.04 (linux/amd64) on bare metal
- ubuntu 22.04 (linux/amd64) on bare metal

## Prerequisites and Setup

- Dependencies

 `sudo apt install docker-compose`

- Update validator.yaml and place it in the `/opt/sui/config/` directory.

Add the paths to your private keys to validator.yaml. If you chose to put them in `/opt/sui/key-pairs`, you can use the following example: 

```
protocol-key-pair: 
  path: /opt/sui/key-pairs/protocol.key
account-key-pair: 
  path: /opt/sui/key-pairs/account.key
worker-key-pair: 
  path: /opt/sui/key-pairs/worker.key
network-key-pair: 
  path: /opt/sui/key-pairs/network.key
```

- Genesis blob should be in (genesis.blob available post genesis ceremony) `/opt/sui/config`

### Connectivity

All connectivity currently happens using IPv4.

You may need to explicitly open the following ports for required connectivity:


```
- TCP 8080 in/out (sui-node protocol)
- UDP 8081 in/out (sui-node primary)
- UDP 8082 in/out (sui-node worker)
- TCP 8083 localhost
- UDP 8084 in/out (sui-node peer to peer)
```

## Starting the Validator node

Start the Validator:

`sudo docker-compose up`

Optional - detached mode: 

`sudo docker-compose up -d`


## Stopping the Validator node

Stop the Validator:

`sudo docker-compose down`

Optional - delete volumes (database):

`sudo docker-compose down -v`

## Testing and Troubleshooting

See [runbooks](../runbooks/README.md)
