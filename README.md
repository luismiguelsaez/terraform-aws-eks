
### Create AWS credentials
```
$ aws configure --profile default
```

### Install clients ( https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html )
```
$ curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
$ sudo cp /tmp/eksctl /usr/local/bin/
$ sudo chmod +x /usr/local/bin/eksctl
```
```
$ curl -sL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /tmp/kubectl
$ sudo mv /tmp/kubectl /usr/local/bin/
$ sudo chmod +x /usr/local/bin/kubectl
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
- Without assuming role
```
$ aws eks update-kubeconfig --region eu-west-1 --name testing --profile default
```
- Assuming admin role ( for non-creator users ) https://aws.amazon.com/es/premiumsupport/knowledge-center/eks-iam-permissions-namespaces/
```
$ eksctl create iamidentitymapping --cluster testing --arn $(terraform output kubectl_role_arn) --username kubectl
$ aws eks update-kubeconfig --region eu-west-1 --name testing --profile default --role-arn $(terraform output kubectl_role_arn)
$ aws sts assume-role --region eu-west-1 --profile default --role-arn $(terraform output kubectl_role_arn) --role-session-name test
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