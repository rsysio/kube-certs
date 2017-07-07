SHELL			:= /bin/bash
PATH			:= ${PATH}:${PWD}/bin
CFSSL_VERSION	?= 1.2

default: all

.PHONY: _get-bin
.SILENT: _get-bin
_get-bin:
	ls bin &> /dev/null || mkdir bin
	ls bin/cfssl &> /dev/null || \
		curl -s -o bin/cfssl https://pkg.cfssl.org/R$(CFSSL_VERSION)/cfssl_linux-amd64 && \
		chmod +x bin/cfssl
	ls bin/cfssljson &> /dev/null || \
		curl -s -o bin/cfssljson https://pkg.cfssl.org/R$(CFSSL_VERSION)/cfssljson_linux-amd64 && \
		chmod +x bin/cfssljson

.PHONY: ca
ca: _get-bin
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca
	ls -Al ca*.pem

.PHONY: admin
admin: _get-bin ca
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		admin-csr.json | cfssljson -bare admin
	ls -Al admin*.pem

.PHONY: proxy
proxy: _get-bin ca
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		kube-proxy-csr.json | cfssljson -bare kube-proxy
	ls -Al kube-proxy*.pem

.PHONY: kubernetes
kubernetes: _get-bin ca
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=ca-config.json \
		-profile=kubernetes \
		kubernetes-csr.json | cfssljson -bare kubernetes
	ls -Al kubernetes*.pem

all: clean admin proxy kubernetes

clean:
	rm -f *.csr *.pem
	ls -Al

check:
	openssl x509 -in kubernetes.pem -text
