
### Create AWS credentials
```
$ aws configure --profile default
```

### Create infrasctructure
```
$ cd terraform
$ terraform init
$ terraform play
$ terraform apply
```

### SSH connection
```
$ terraform output ssh_private_key >key.pem
$ chmod 0600 key.pem
$ ssh -i key.pem ec2-user@$(terraform output bastion_dns_name)
```

### Create kubectl config
```
$ aws eks update-kubeconfig --name testing --profile default
```