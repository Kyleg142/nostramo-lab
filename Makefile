# 192.168.68.68 is treated as the LEADER
NODES := 192.168.68.68 192.168.68.94 192.168.68.95
CP_ENDPOINT := 192.168.68.68

.PHONY: all provision nuke config

all: provision config

# Applies the node config to each node and bootstraps the cluster.
provision:
	@echo "PROVISIONING ALL NODES"
	@for node in $(NODES); do \
	    talosctl apply-config --insecure --nodes $$node --file controlplane.yaml; \
	done

	@echo "STANDBY FOR PROVISIONING..."
	timeout 300s sh -c 'until \
		$(foreach node,$(NODES),nc -nzv $(node) 50000 &&) \
		true; do sleep 5; done'

	@#ONLY BOOTSTRAP THE FIRST NODE the others join automatically
	@echo "BOOTSTRAPPING THE CLUSTER"
	talosctl bootstrap --nodes $(CP_ENDPOINT)

	@echo "STANDBY FOR BOOTSTRAPPING..."
	talosctl health --nodes $(CP_ENDPOINT) --wait-timeout 10m

	@echo "CREATING NAMESPACES"
	kubectl create ns argocd
	kubectl create ns debug
	kubectl label ns debug pod-security.kubernetes.io/enforce=privileged

	@echo "INSTALLING ARGOCD..."
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

	@echo "SUCCESS! PULLING FROM GIT..."
	kubectl apply -f root-app.yaml

	@echo "BOOTSTRAPPING COMPLETE!"

# Generates fresh configs for talosctl and kubectl in their default directories
config:
	@echo "GENERATING KUBECONFIG & TALOSCONFIG..."
	cp talosconfig ~/.talos/config
	talosctl --nodes $(CP_ENDPOINT) --talosconfig ./talosconfig kubeconfig
	@echo "CONFIG GENERATED!"

# Resets each node to baseline (maintenance mode)
nuke:
	@echo "☢️ RESETTING CLUSTER..."
	@for node in $(NODES); do \
	    echo "💥 RESETTING $$node..."; \
		talosctl reset -n $$node --graceful=false --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --reboot; \
	done
