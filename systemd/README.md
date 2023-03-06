

1. validator
2. fullnode
3. indexer


Link to sui_for_node_operators?



# Run a Sui Validator node using Systemd

Tested using:
- Ubuntu 20.04 (linux/amd64) on bare metal
- Ubuntu 22.04 (linux/amd64) on bare metal


## Prerequisites and setup


### Add the Sui user and the `/opt/sui` directories

```shell
sudo useradd sui
sudo mkdir -p /opt/sui/config
sudo mkdir -p /opt/sui/db
sudo mkdir -p /opt/sui/bin
sudo mkdir -p /opt/sui/key-pairs
sudo chown -R sui:sui /opt/sui
```

### Sui node (sui-node) binary, two options:
    
- Pre-built binary stored in Amazon S3:
        
```shell
wget https://sui-releases.s3.us-east-1.amazonaws.com/18e23a4790560aa10fb6c128744d162fda10b1c3/sui-node
chmod +x sui-node
sudo mv sui-node /opt/sui/bin
```

- Build from source:

```shell
git clone https://github.com/MystenLabs/sui.git && cd sui
git checkout testnet
cargo build --release --bin sui-node
mv ./target/release/sui-node /opt/sui/bin/sui-node
```

### Copy your `sui-testnet-wave2/genesis/key-pairs/` into `/opt/sui/key-pairs/` (generated during Genesis ceremony)

Make sure when you copy them they retain `sui` user permissions. To be safe you can re-run: `sudo chown -R sui:sui /opt/sui`

### Update validator.yaml and place it in the `/opt/sui/config/` directory.

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

### Place genesis.blob in `/opt/sui/config/` (should be available after the Genesis ceremony)

- TBC file link

### Copy the sui-node systemd service unit file 

Copy the file to `/etc/systemd/system/sui-node.service`.

### Reload systemd with this new service unit file, run:

```shell
sudo systemctl daemon-reload
```

### Enable the new service with systemd

```shell
sudo systemctl enable sui-node.service
```

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

## Start the Validator node

Start the Validator:

```shell
sudo systemctl start sui-node
```

Optionally, purge state/databases:

```shell
rm -rf /opt/sui/db/authorities_db /opt/sui/db/consensus_db
```

Check that the node is up and running with `sudo systemctl status sui-node` and follow the logs with `journalctl -f`

## Stop the Validator node

Stop the validator:
```shell
sudo systemctl stop sui-node
```

## Troubleshooting

See [runbooks](../sui_for_node_operators.md)
