CFSSL_VERSION ?= 1.2

.PHONY: get-cfssl create-ca create-admin create-proxy create-kube all clean
.DEFAULT: all

get-cfssl:
	# get cfssl bin
	ls /usr/local/bin/cfssl || \
	(wget https://pkg.cfssl.org/R$(CFSSL_VERSION)/cfssl_linux-amd64 && \
	chmod +x cfssl_linux-amd64 && \
	sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl)
	# get cfssljson bin
	ls /usr/local/bin/cfssljson || \
	(wget https://pkg.cfssl.org/R$(CFSSL_VERSION)/cfssljson_linux-amd64 && \
	chmod +x cfssljson_linux-amd64 && \
	sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson)

create-ca:
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca

create-admin:
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		admin-csr.json | cfssljson -bare admin

create-proxy:
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		kube-proxy-csr.json | cfssljson -bare kube-proxy

create-kube:
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		kubernetes-csr.json | cfssljson -bare kubernetes

all: get-cfssl create-ca create-admin create-proxy create-kube

clean:
	rm -f *.csr *.pem
