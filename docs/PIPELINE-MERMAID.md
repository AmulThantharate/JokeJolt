# CI/CD Pipeline Flow Diagrams

## Main Pipeline Flow

```mermaid
graph TD
    A[Developer] -->|git push| B[GitHub Repository]
    B -->|Push to main/develop| C[CI Pipeline Triggered]

    C --> D[Code Quality & SAST]
    C --> E[Unit Tests]
    C --> F[Dependency Scanning]

    D --> G{All Checks Pass?}
    E --> G
    F --> G

    G -->|Yes| H[Build Docker Image]
    G -->|No| Z[❌ Pipeline Failed]

    H --> I[Container Security Scan - Trivy]
    I --> J[Nuclei DAST Scan]
    J --> K[IaC Security Scan]

    K --> L{Security Checks Pass?}
    L -->|Yes| M[Push to GHCR & ECR]
    L -->|No| Z

    M --> N{Which Branch?}
    N -->|develop| O[Deploy to Staging via ArgoCD]
    N -->|main| P[Deploy to Production via ArgoCD]

    O --> Q[Staging Health Check]
    P --> R[Production Health Check]

    Q --> S{Healthy?}
    R --> S

    S -->|Yes| T[✅ Deployment Success]
    S -->|No| U[Rollback Triggered]

    T --> V[Continuous Monitoring]
    U --> W[Alert Team]

    style A fill:#e1f5ff
    style T fill:#4caf50
    style Z fill:#f44336
    style U fill:#ff9800
```

## GitHub Actions Workflow

```mermaid
graph LR
    A[Push/PR] --> B{Event Type}

    B -->|PR| C[Run Code Quality]
    B -->|Push| D[Full Pipeline]

    C --> E[ESLint SAST]
    C --> F[Jest Tests]
    C --> G[Dependency Scan]

    E --> H{Pass?}
    F --> H
    G --> H

    H -->|Yes| I[Report Status]
    H -->|No| J[❌ PR Check Failed]

    D --> K[Build Docker]
    K --> L[Trivy Container Scan]
    L --> M[Nuclei Scan]
    M --> N[IaC Scan]

    N --> O{All Secure?}
    O -->|Yes| P[Push to Registries]
    O -->|No| Q[❌ Security Failed]

    P --> R{Branch?}
    R -->|develop| S[Deploy Staging]
    R -->|main| T[Deploy Production]

    style A fill:#e1f5ff
    style I fill:#4caf50
    style J fill:#f44336
    style Q fill:#f44336
```

## ArgoCD GitOps Flow

```mermaid
graph TD
    A[GitHub Repository] -->|Watch for changes| B[ArgoCD Controller]

    B --> C{Branch Detection}

    C -->|develop changed| D[Sync Staging App]
    C -->|main changed| E[Sync Production App]

    D --> F[Read k8s/staging/ manifests]
    E --> G[Read k8s/production/ manifests]

    F --> H[Apply to jokejolt-staging namespace]
    G --> I[Manual Approval Required]

    I -->|Approved| J[Apply to jokejolt-production namespace]
    I -->|Rejected| K[Sync Paused]

    H --> L[Kubernetes Deployment]
    J --> L

    L --> M[Pods Running]
    M --> N[Health Check]
    N --> O{Healthy?}

    O -->|Yes| P[✅ Sync Success]
    O -->|No| Q[Auto-Rollback]

    P --> R[Continuous Monitoring]
    Q --> S[Alert Team]

    style A fill:#e1f5ff
    style P fill:#4caf50
    style Q fill:#f44336
    style K fill:#ff9800
```

## Security Scanning Pipeline

```mermaid
graph TD
    A[Code Repository] --> B[Security Scanning]

    B --> C[SAST - ESLint]
    B --> D[SCA - npm audit + Trivy]
    B --> E[Container - Trivy]
    B --> F[DAST - Nuclei]
    B --> G[IaC - Trivy Config]

    C --> H[Vulnerability Results]
    D --> H
    E --> H
    F --> H
    G --> H

    H --> I{Severity Check}

    I -->|Critical Found| J[❌ Block Pipeline]
    I -->|High Found| J
    I -->|Clean| K[✅ Allow Deploy]

    J --> L[Security Report]
    K --> M[Proceed to Next Stage]

    style A fill:#e1f5ff
    style J fill:#f44336
    style K fill:#4caf50
    style L fill:#ff9800
```

## Multi-Environment Deployment

```mermaid
graph TB
    subgraph CI["Continuous Integration"]
        A[Code Commit] --> B[Run Tests]
        B --> C[Security Scans]
        C --> D[Build Image]
        D --> E[Push to Registries]
    end

    subgraph CD["Continuous Deployment"]
        E --> F{Branch?}

        F -->|develop| G[ArgoCD Staging]
        F -->|main| H[ArgoCD Production]

        G --> I[Auto-Sync Enabled]
        H --> J[Manual Approval]

        I --> K[Deploy to Staging]
        J -->|Approve| L[Deploy to Production]

        K --> M[Staging URL]
        L --> N[Production URL]
    end

    subgraph AWS["AWS Infrastructure"]
        M --> O[ALB - Staging]
        N --> P[ALB - Production]

        O --> Q[EKS Cluster - Staging]
        P --> R[EKS Cluster - Production]

        Q --> S[Pods: 2-10]
        R --> T[Pods: 3-20]
    end

    style A fill:#e1f5ff
    style K fill:#4caf50
    style L fill:#4caf50
    style J fill:#ff9800
```

## Container Security Pipeline

```mermaid
graph LR
    A[Dockerfile] --> B[Multi-Stage Build]

    B --> C[Stage 1: Builder]
    C -->|Install deps| D[Stage 2: Production]

    D -->|Copy node_modules| E[Final Image]
    E -->|Add app code| F[Optimized Image]

    F --> G[Scan with Trivy]
    G --> H{Vulnerabilities?}

    H -->|Critical| I[❌ Fail Build]
    H -->|Clean| J[Tag & Push]

    J --> K[Run Container]
    K --> L[Nuclei DAST Scan]
    L --> M{Issues Found?}

    M -->|Critical| N[❌ Block Deploy]
    M -->|Clean| O[✅ Image Approved]

    style A fill:#e1f5ff
    style I fill:#f44336
    style N fill:#f44336
    style O fill:#4caf50
```

## Nuclei Scan Details

```mermaid
graph TD
    A[Running Container] -->|Port 3001| B[Nuclei Scanner]

    B --> C[Load Templates]
    C --> D[API Security Tests]
    C --> E[Node.js Tests]
    C --> F[JWT Tests]
    C --> G[CORS Tests]
    C --> H[Default Logins]

    D --> I[Scan Results]
    E --> I
    F --> I
    G --> I
    H --> I

    I --> J{Severity Filter}
    J -->|Critical| K[Block Pipeline]
    J -->|High| K
    J -->|Medium| L[Warn Only]
    J -->|Low| M[Info Only]

    K --> N[Security Report]
    L --> N
    M --> O[✅ Pass with Warnings]

    style A fill:#e1f5ff
    style K fill:#f44336
    style O fill:#ffeb3b
```

## AWS Deployment Architecture

```mermaid
graph TB
    subgraph Registry["Container Registry"]
        A[GHCR] -->|Pull| B[AWS ECR]
    end

    subgraph EKS["Amazon EKS Cluster"]
        C[Worker Nodes] --> D[Pod 1]
        C --> E[Pod 2]
        C --> F[Pod 3]

        G[HPA] -->|Scale| C
    end

    subgraph Network["Networking"]
        H[ALB] -->|Route| I[Service]
        I --> D
        I --> E
        I --> F
    end

    B -->|Deploy| C
    H -->|Health Check| J[/health endpoint]

    J --> K{Status?}
    K -->|200 OK| L[✅ Healthy]
    K -->|Error| M[❌ Unhealthy]

    L --> N[Serve Traffic]
    M --> O[Rollback]

    style A fill:#e1f5ff
    style L fill:#4caf50
    style M fill:#f44336
```

## Pipeline Decision Tree

```mermaid
graph TD
    A[Code Change] --> B{PR or Push?}

    B -->|PR| C[Run Minimal Tests]
    B -->|Push| D[Run Full Pipeline]

    C --> E{Tests Pass?}
    E -->|Yes| F[Allow Merge]
    E -->|No| G[❌ Fix Issues]

    D --> H{Branch?}
    H -->|develop| I[Build + Security Scan]
    H -->|main| I

    I --> J{Security Pass?}
    J -->|No| K[❌ Fix Vulnerabilities]
    J -->|Yes| L[Push to Registry]

    L --> M{Environment?}
    M -->|Staging| N[Auto-Deploy]
    M -->|Production| O[Manual Approval]

    N --> P[Staging Validation]
    O -->|Approved| Q[Production Deploy]

    P --> R{Promote to Prod?}
    R -->|Yes| O
    R -->|No| S[Keep in Staging]

    Q --> T[Production Monitoring]

    style A fill:#e1f5ff
    style F fill:#4caf50
    style G fill:#f44336
    style K fill:#f44336
```

---

## Legend

| Symbol | Meaning |
|--------|---------|
| 🟦 Blue Box | External System/Actor |
| 🟩 Green Box | Success State |
| 🟥 Red Box | Failure State |
| 🟨 Yellow Box | Warning/Manual Action |
| 🟧 Orange Box | Waiting/Pending |

---

## How to View Diagrams

1. **GitHub**: Diagrams render automatically in markdown
2. **VS Code**: Install "Markdown Preview Mermaid Support" extension
3. **Online**: Use [Mermaid Live Editor](https://mermaid.live/)
4. **CLI**: Use `mmdc` (Mermaid CLI) to generate PNG/SVG

```bash
# Generate PNG from mermaid
npx @mermaid-js/mermaid-cli -i docs/PIPELINE-MERMAID.md -o pipeline.png
```
