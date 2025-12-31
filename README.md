# 🦇 nostramo-lab
**A High-Availability, Hyper-Converged Kubernetes Cluster**

Nostramo is a 3-node, bare-metal Kubernetes cluster built on Talos Linux. It serves as a declarative environment for testing GitOps workflows and cloud-native networking.

### The Tech Stack 🛠️
| Layer | Tool| Rationale |
| --- | --- | --- |
| OS | [Talos Linux](https://docs.siderolabs.com/talos/) | Security-hardened, immutable, and purely API-driven. |
| GitOps | [ArgoCD](https://argo-cd.readthedocs.io/) | Maintains the cluster's desired state automatically by referencing this repo. |
| Network | [MetalLB](https://metallb.io/) | Bridges the gap between bare metal and K8S by advertising IPs via Layer 2 ARP. |
| Ingress | [Traefik](https://doc.traefik.io/traefik/) | Deployed as a DaemonSet for high availability, managing external traffic routing. |
| Storage | [Longhorn](https://longhorn.io/docs/what-is-longhorn/) | Provides high-availability storage with cross-node replication for stateful workloads. |
| Telemetry | [VictoriaMetrics](https://docs.victoriametrics.com/helm/victoria-metrics-k8s-stack/) | Chosen for its high efficiency and low resource footprint compared to Prometheus. |
```mermaid
graph TD
    Argo{{"ArgoCD<br/>(GitOps Controller)"}}

    subgraph Networking ["Networking"]
        direction TB
        MetalLB("MetalLB<br/>(L2 Load Balancer)")
        Traefik("Traefik<br/>(Ingress Controller)")
    end

    subgraph Storage ["Storage"]
        Longhorn("Longhorn<br/>(Replicated Block Storage)")
    end

    subgraph Observability ["Observability"]
        direction TB
        VM("VictoriaMetrics<br/>(Telemetry)")
        Grafana("Grafana<br/>(Visualization)")
    end

    Argo -->|Manages| Networking
    Argo -->|Manages| Storage
    Argo -->|Manages| Observability
    
    MetalLB -.- Traefik
    VM -.- Grafana
```

### Infrastructure as Code 📜

#### GitOps Workflow:

**ArgoCD** manages the lifecycle of all services. I utilize sync waves to ensure that infrastructure (like MetalLB) is healthy before applications attempt to deploy.

Adding a service is as simple as committing a new Application manifest to the `apps/` directory.

**Node Configuration:**

Drift is eliminated through a Talos node configuration manifest. The OS runs in RAM, meaning that every reboot returns the node to a known clean state. 

Here are two key modifications made to node configuration to facilitate the current architecture:
- `cluster.apiServer.extraArgs.enable-aggregator-routing: true`
  - Enables load-balancing for the two instances of metrics-server that are running within the cluster.
- `cluster.allowSchedulingOnControlPlanes: true`
  - Allows scheduling workloads on control-plane nodes. Vital for spreading workloads among the three converged nodes.
 
### Tooling 🧰
**Talos Node Debugger: `debugger.sh`**

Because Talos is an immutable "no-SSH" OS, standard troubleshooting is restricted. This tool is developed to:
1) Launch a highly-privileged ephemeral pod on a target node.
2) Provide low-level access to the host namespaces for hardware/network debugging.
3) Automatically clean up all resources upon exit.

### Hardware & Efficiency 🔌
This lab demonstrates that enterprise features do not require enterprise budgets.
- **Compute:** 3x Ryzen 3550H (12 Cores / 24 Threads Total)
- **Memory:** 48GB DDR4 RAM
- **Storage:** 1.5TB NVME
- **Power Efficiency:** The entire cluster pulls **~150W** under heavy load.
```mermaid
graph TD
        Node1(["Talos Node 01<br/>(CP/Worker)"])
        Node2(["Talos Node 02<br/>(CP/Worker)"])
        Node3(["Talos Node 03<br/>(CP/Worker)"])

        Switch("Switch<br/>(192.168.68.0/24)")

        %% Connections
        Switch <-.-> Node1
        Switch <-.-> Node2
        Switch <-.-> Node3
```


