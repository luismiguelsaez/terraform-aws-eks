
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

### Create kubectl config
```
$ aws eks update-kubeconfig --name testing --profile default
```