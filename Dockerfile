FROM alpine
RUN apk add --no-cache curl make git bash

# install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x ./kubectl && mv ./kubectl /usr/bin/kubectl
RUN kubectl version || true

# install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash && chmod +x ./kustomize && mv kustomize /usr/bin/kustomize
RUN kustomize version

# copy plugin.sh which contains deployment logic
COPY plugin.sh /drone/

ENTRYPOINT [ "/drone/plugin.sh" ]
