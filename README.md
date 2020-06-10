
### Create AWS credentials
```
$ aws configure --profile default
```

### Install clients
https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html

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
### Get kubectl
```
$ sudo curl -sL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
$ sudo chmod +x /usr/local/bin/kubectl
```

### Create kubectl config
- Without assuming role
```
$ aws eks update-kubeconfig --region eu-west-1 --name testing --profile default
```
- Assuming admin role ( for non-creator users ) https://aws.amazon.com/es/premiumsupport/knowledge-center/eks-iam-permissions-namespaces/
```
$ aws eks update-kubeconfig --region eu-west-1 --name testing --profile default --role-arn $(terraform output kubectl_role_arn)
```

### Run testing pod
```
$ kubectl run -i --tty busybox --image=busybox --serviceaccount=aws-node --restart=Never -- sh
$ kubectl delete pod busybox

$ kubectl apply -f ../k8s/test-pod.yml
$ kubectl exec -it alpine -- sh
```

### SSH connection ( connect to workers through bastion )
```
$ ssh -i ./ssh/keys/default.pem -o ProxyCommand="ssh -i ./ssh/keys/default.pem -W %h:%p ec2-user@3.249.146.109" ec2-user@10.5.3.47
```