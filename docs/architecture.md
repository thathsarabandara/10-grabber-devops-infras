# Platform Architecture

This document describes the networking, deployment, and service orchestration architecture of the Grabber Platform on a single Ubuntu Server VM using k3s and Cloudflare Tunnel.

## Ingress Flow Architecture

All external traffic enters the platform via Cloudflare, is forwarded securely by an outbound-only Cloudflare Tunnel (`cloudflared`) to the internal NGINX Ingress Controller, and is then routed to the target services based on Host headers.

```mermaid
graph TD
    %% Internet/Clients
    User([Public User / Browser])
    ESP32([ESP32 Robot Arm])

    subgraph Cloudflare Network
        CF[Cloudflare Edge DNS / Proxy]
        CFT[Cloudflare Tunnel Endpoint]
    end

    subgraph Ubuntu VM Host
        subgraph cloudflare Namespace
            Tunnel[cloudflared Pod]
        end

        subgraph ingress-nginx Namespace
            IngController[NGINX Ingress Controller Service]
        end

        subgraph robot-platform Namespace
            Frontend[Frontend Pod - port 8080]
            APIGateway[API Gateway Pod - port 8000]
            MQTT[Mosquitto MQTT Pod - port 9001]
            
            Auth[Auth Service Pod]
            Robot[Robot Service Pod]
            Telemetry[Telemetry Service Pod]
            AI[AI Service Pod]
            
            MySQL[(MySQL Database)]
            Redis[(Redis Cache)]
        end

        subgraph monitoring Namespace
            Grafana[Grafana Dashboard Pod]
            Prometheus[Prometheus Server]
        end
    end

    %% Flow lines
    User -->|HTTPS dashboard.example.com| CF
    User -->|HTTPS api.example.com| CF
    User -->|HTTPS grafana.example.com| CF
    ESP32 -->|WSS mqtt.example.com| CF

    CF --> CFT
    CFT <==|Outbound WireGuard/QUIC Secure Tunnel|==> Tunnel
    
    Tunnel -->|Forward HTTP Traffic| IngController
    
    IngController -->|Host: dashboard.example.com| Frontend
    IngController -->|Host: api.example.com| APIGateway
    IngController -->|Host: mqtt.example.com| MQTT
    IngController -->|Host: grafana.example.com| Grafana

    %% Internal Microservice communication
    APIGateway --> Auth
    APIGateway --> Robot
    APIGateway --> Telemetry
    APIGateway --> AI

    %% DB/Broker dependencies
    Auth --> MySQL
    Auth --> Redis
    
    Robot --> MySQL
    Robot --> Redis
    Robot --> MQTT

    Telemetry --> MySQL
    Telemetry --> Redis
    Telemetry --> MQTT

    AI --> MySQL
    AI --> Redis
    
    %% Monitoring Metrics collection
    Prometheus -->|Scrape /metrics| APIGateway
    Prometheus -->|Scrape /metrics| Auth
    Prometheus -->|Scrape /metrics| Robot
    Prometheus -->|Scrape /metrics| Telemetry
    Prometheus -->|Scrape /metrics| AI
    Prometheus -->|Scrape /metrics| Frontend
    
    Grafana -->|Query Datasource| Prometheus
```

## Key Architectural Principles

1. **Zero Trust Exposure**: No host VM ports (such as 80, 443, 3306, 6379, 1883) need exposure to the public internet. The VM runs a secure UFW firewall blocking all incoming ports except SSH (TCP 22) for administration. Outbound-only tunnels established by `cloudflared` forward traffic from the Cloudflare Edge to the internal NGINX Ingress controller.
2. **Namespace Isolation**:
   - `robot-platform`: Runs application code and databases.
   - `ingress-nginx`: Hosts the NGINX ingress controller.
   - `cloudflare`: Dedicated namespace for the tunnel daemon.
   - `monitoring`: Contains Prometheus, Alertmanager, and Grafana.
3. **Internal-Only Databases**: MySQL, Redis, and raw MQTT (1883) do not have public ingresses or routes. They are restricted to ClusterIP services and are isolated via Kubernetes NetworkPolicies to prevent unauthorized lateral movement.
4. **WebSocket-Only Broker Connectivity**: The Mosquitto broker exposes WebSockets on port 9001, which is proxied through NGINX Ingress and Cloudflare Tunnel to support public robot telemetry streams. The standard TCP MQTT port (1883) remains internal-only.
