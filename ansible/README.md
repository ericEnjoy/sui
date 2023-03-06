
`ansible/` This contains a ansible playbook for standing up your node. Successful execution of the playbook will result
in a systemd process running sui-node. Feel free use this or just consult the steps when provisioning your own node. 


# Configure a Linux system as a Sui node

This is a self contained Ansible role for configuring a Linux system as a Sui Node (fullnode or validator).

Tested with `ansible [core 2.13.4]` and:

- ubuntu 20.04 (linux/amd64) on bare metal
- ubuntu 22.04 (linux/amd64) on bare metal

## Prerequisites:

- install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- ssh access into the target host
- make sure your `genesis/key-pairs/` have been generated. Check the `genesis/README.md` for more info
- add target host to inventory.yaml
- Add your hostname to `ansible/roles/sui-node/files/validator.yaml`
- Copy your genesis.blob into the `roles/sui-node/files` directory 

## Example use:

- Configure everything:

`ansible-playbook -i inventory.yaml sui-node.yaml -e host=$inventory_name`
