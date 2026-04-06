# 🎭 JokeJolt - Joke Generator API

A production-ready REST API built with **Node.js** and **Express** that serves random jokes from [JokeAPI](https://v2.jokeapi.dev). Features a comprehensive DevSecOps pipeline with automated security scanning, containerization, and GitOps-based deployment.

[![CI/CD](https://github.com/AmulThantharate/JokeJolt/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/AmulThantharate/JokeJolt/actions/workflows/ci-cd.yml)
![Node.js](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#-quick-start)
- [API Endpoints](#-api-endpoints)
- [Security](#-security)
- [Development](#-development)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Tech Stack](#-tech-stack)
- [Documentation](#-documentation)

---

## ✨ Features

- **RESTful API** with clean JSON responses
- **Rate Limiting** (30 req/min per IP)
- **Security First**: SAST, DAST, dependency & container scanning
- **CI/CD**: GitHub Actions & Jenkins pipelines
- **GitOps Deployment**: ArgoCD integration for automated deployments
- **Containerized**: Multi-stage Docker builds
- **Kubernetes Ready**: Full K8s manifests for staging & production
- **Infrastructure as Code**: Vagrant-based local K8s cluster setup
- **Monitoring**: Health checks, uptime tracking, and structured logging

---

## 🚀 Quick Start

### Prerequisites

- Node.js >= 18.0.0
- npm or yarn

### Run Locally

```bash
# 1. Clone the repository
git clone https://github.com/AmulThantharate/JokeJolt.git
cd JokeJolt

# 2. Install dependencies
npm install

# 3. (Optional) Create a .env file
echo "PORT=3000" > .env

# 4. Start the server
npm start
```

The server will be available at **http://localhost:3000**.

### Run with Docker

```bash
# Build the image
docker build -t jokejolt .

# Run the container
docker run -p 3000:3000 jokejolt
```

---

## 📡 API Endpoints

| Method | Path        | Description                   | Query Parameters                     |
| ------ | ----------- | ----------------------------- | ------------------------------------ |
| GET    | `/`         | Welcome message               | -                                    |
| GET    | `/joke`     | Fetch a random joke           | `category`, `blacklistFlags`, `type` |
| GET    | `/health`   | Health check (status, uptime) | -                                    |
| GET    | `/api-docs` | Swagger UI documentation      | -                                    |

### Example: Fetch a Joke

```bash
curl http://localhost:3000/joke
```

Response:

```json
{
  "type": "twopart",
  "category": "Programming",
  "setup": "Why do programmers prefer dark mode?",
  "delivery": "Because light attracts bugs!"
}
```

### Query Parameters for `/joke`

- **category**: Joke category (e.g., `Programming`, `Dark`, `Pun`)
- **blacklistFlags**: Comma-separated list of flags to exclude
- **type**: Joke type (`single` or `twopart`)

---

## 🔒 Security

This project implements a comprehensive **DevSecOps** pipeline:

### Security Scanning Layers

1. **SAST** - ESLint for static code analysis
2. **Code Quality** - SonarQube for continuous code quality inspection
3. **Quality Gate** - SonarQube quality gate enforcement
4. **Dependency Scanning** - npm audit + Trivy for vulnerable packages
5. **Container Scanning** - Trivy image scanning for CVEs
6. **DAST** - Nuclei for dynamic application security testing
7. **IaC Scanning** - Trivy config scanning for Kubernetes & Dockerfiles

### Pipeline Tools

- **SonarQube**: Code quality analysis, bug detection, security hotspot identification
- **Trivy**: Filesystem, container, and IaC scanning
- **Nuclei**: API and web vulnerability scanning
- **Hadolint**: Dockerfile best practices
- **ESLint**: Code quality and security patterns

### SonarQube Integration

The Jenkins pipeline includes SonarQube scanning with:
- **Static Analysis**: Detects code smells, bugs, and security vulnerabilities
- **Coverage Reports**: Tracks test coverage trends
- **Quality Gates**: Enforces minimum quality standards before deployment
- **Security Hotspots**: Identifies potential security issues requiring review
- **Technical Debt**: Estimates remediation effort

Configure SonarQube in Jenkins:
1. Install SonarQube Scanner plugin
2. Configure SonarQube server in Jenkins (Manage Jenkins > Configure System)
3. Add SonarQube installation (Manage Jenkins > Global Tool Configuration)

[View full pipeline documentation](docs/DEVSECOPS-PIPELINE.md)

---

## 🛠 Development

### Available Scripts

```bash
npm start          # Start production server
npm run dev        # Start with nodemon (hot reload)
npm test           # Run test suite
npm run test:ci    # Run tests in CI mode with coverage
npm run lint       # Run ESLint
npm run smoke      # Run smoke tests
```

### Project Structure

```
JokeJolt/
├── app.js                 # Application entry point
├── package.json           # Dependencies and scripts
├── Dockerfile             # Multi-stage container build
├── Jenkinsfile            # Jenkins CI/CD pipeline
├── .github/workflows/     # GitHub Actions workflows
│   └── ci-cd.yml         # CI/CD pipeline definition
├── k8s/                   # Kubernetes manifests
│   ├── staging/          # Staging environment
│   └── production/       # Production environment
├── docs/                  # Documentation
│   ├── DEVSECOPS-PIPELINE.md
│   ├── DEPLOYMENT-OPTIONS.md
│   └── VAGRANT-SETUP.md
└── scripts/              # Utility scripts
    └── setup-vagrant.sh  # Local K8s cluster setup
```

---

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:ci

# Run smoke tests
npm run smoke
```

The project uses:

- **Jest** for unit and integration testing
- **Supertest** for HTTP endpoint testing
- **axios-mock-adapter** for mocking external API calls

---

## 🚢 Deployment

### Kubernetes with ArgoCD (GitOps)

The project uses ArgoCD for automated GitOps deployments:

1. **Push code** to `develop` → Auto-deploys to staging
2. **Push code** to `main` → Auto-deploys to production

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Sync staging application
argocd app sync jokejolt-staging
```

### Local Testing with Vagrant

Set up a local 2-node Kubernetes cluster for testing:

```bash
# Start the cluster with ArgoCD
./scripts/setup-vagrant.sh up

# Get ArgoCD credentials
./scripts/setup-vagrant.sh argocd

# Deploy JokeJolt
./scripts/setup-vagrant.sh deploy
```

See [Vagrant Setup Guide](docs/VAGRANT-SETUP.md) for details.

### Cloud Deployment

- **GitHub Container Registry (GHCR)**: Primary container registry
- **AWS ECR**: Optional - see [Deployment Options](docs/DEPLOYMENT-OPTIONS.md)
- **AWS EKS/ECS**: Ready with manifests in backup

---

## ⚙️ Environment Variables

| Variable   | Default      | Description           |
| ---------- | ------------ | --------------------- |
| `PORT`     | `3000`       | Server listening port |
| `NODE_ENV` | `production` | Runtime environment   |

---

## 🛠 Tech Stack

### Runtime

- **Node.js** - JavaScript runtime
- **Express** - Web framework

### Dependencies

- **axios** - HTTP client for JokeAPI
- **express-rate-limit** - Rate limiting middleware
- **morgan** - HTTP request logger
- **dotenv** - Environment variable management

### DevOps & Security

- **Docker** - Containerization
- **Kubernetes** - Container orchestration
- **ArgoCD** - GitOps continuous deployment
- **Trivy** - Vulnerability scanner
- **Nuclei** - DAST security scanner
- **ESLint** - Static code analysis
- **Jest** - Testing framework

---

## 📚 Documentation

- [DevSecOps Pipeline](docs/DEVSECOPS-PIPELINE.md) - Complete CI/CD pipeline documentation
- [Deployment Options](docs/DEPLOYMENT-OPTIONS.md) - AWS and cloud deployment guide
- [Vagrant Setup](docs/VAGRANT-SETUP.md) - Local Kubernetes cluster setup
- [Pipeline Diagram](docs/PIPELINE-MERMAID.md) - Visual pipeline architecture

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

All PRs trigger the CI/CD pipeline with security scanning.

---

## 📄 License

MIT License - see LICENSE file for details.

---

## 🙏 Acknowledgments

- [JokeAPI](https://v2.jokeapi.dev) for the joke data source
- Open source security tools: Trivy, Nuclei, ESLint
