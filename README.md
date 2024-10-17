# 𒌐 DevSecOps Learning Journey 𒌐 

As a freshly graduated cybersecurity engineer and a DevSecOps intern, I wanted to get better. So I embarked on a journey to learn about DevOps technologies and tools. Following advice from Claude, I explored Kubernetes and many other awesome tools over the course of a month and a half. This project reflects my progress, the technologies I used, and the DevSecOps practices I learned along the way.

---

## 𒌐 Technologies Used 𒌐 

- **Containerization & Orchestration:** Docker, Minikube, Kubernetes  
- **Infrastructure as Code (IaC):** Terraform, Helm, Ansible 
- **CI/CD Tools:** Jenkins, GitHub Actions  
- **Databases:** PostgreSQL, Redis  
- **Monitoring & Logging:** Prometheus, Grafana, ELK Stack  
- **Service Mesh:** Istio  
- **Security Tools:** Trivy, Checkov  
- **Secrets Management:** HashiCorp Vault  

---

## 𒌐 DevSecOps Practices Learned 𒌐 

- Containerization and microservices deployment
- Automating infrastructure with IaC tools (Terraform, Helm)  
- CI/CD pipeline setup and deployment automation
- Multi-environment management (dev, staging, prod)  
- Monitoring and observability practices with Prometheus, Grafana, and ELK Stack 
- Service mesh implementation with Istio  
- Traffic routing using Istio Ingress Gateway  
- TLS termination at Istio Ingress and mutual TLS encryption  
- Rate limiting for traffic management  
- Caching strategies using Redis  
- Retry and timeout improvements with Istio  
- Canary and blue/green deployments for safe releases  
- A/B testing using user subsets, cookies, or geo-IP  using Istio's VirtualService feature
- Horizontal pod autoscaling for performance optimization  
- Resiliency patterns: circuit breaker and fault injection  
- Secrets management using HashiCorp Vault (KV2 Engine, Dynamic Database Secrets, Transit Engine)
- Security and compliance: network policies, RBAC, security scanning, SBOM Generation (Trivy, Checkov)  
- GitOps workflows for streamlined deployments

---

## 📋 Learning Roadmap 

### **Level 1: Basic Setup**
1. Create a simple microservices application (e.g., a basic web app with a backend API)  
2. Containerize the application using Docker  
3. Set up a local Kubernetes cluster using Minikube or kind  
4. Create Kubernetes manifests (Deployments, Services) for your application  
5. Manually deploy the application to your local cluster  

### **Level 2: CI/CD Pipeline**
6. Set up a Git repository for your project  
7. Implement a CI pipeline using **Jenkins** (set up locally, created a user, etc.)  
8. Automate building and pushing Docker images to a container registry  
9. Automate deployment to your local Kubernetes cluster  

### **Level 3: Multi-Environment Setup**
10. Set up multiple namespaces in your cluster to represent different environments (dev, staging, prod)  
11. Use Helm charts to manage environment-specific configurations  
12. Modify your CI/CD pipeline to deploy to different environments based on branch or tag  

### **Level 4: Infrastructure as Code (IaC)**
13. Use **Terraform** to provision and manage Kubernetes clusters  
14. Explore cloud-based Kubernetes solutions (e.g., EKS, GKE, or AKS)  
15. Extend your CI/CD pipeline to manage infrastructure changes  

### **Level 5: Advanced Kubernetes Features**
16. Implement horizontal pod autoscaling for your applications  
17. Set up monitoring and logging (Prometheus, Grafana, ELK)  
18. Implement a service mesh using **Istio** or **Linkerd**  
19. Set up TLS termination at Istio Ingress and mutual TLS encryption  
20. Implement rate limiting for traffic management  
21. Use caching with Redis  
22. Enhance resilience with circuit breaker and fault injection patterns  
23. Set up canary and blue/green deployments for safe releases  
24. Implement retry and timeout improvements using Istio  
25. Set up A/B testing using user subsets, cookies, or geo-IP  
26. Implement traffic routing using Istio Ingress Gateway  

### **Level 6: Security and Compliance**
27. Implement network policies for secure communication between services  
28. Set up **RBAC** (Role-Based Access Control) for your cluster  
29. Manage secrets using **HashiCorp Vault**  
30. Perform security scans on containers and manifests using **Trivy** and **Checkov**  

### **Level 7: Advanced CI/CD and GitOps**
31. Implement GitOps principles with tools like **ArgoCD** or **Flux**  
32. Set up blue-green deployments  
33. Introduce chaos engineering practices to test system resilience  

---

## 𒌐 Conclusion 𒌐 

This project has been an incredible learning experience that exposed me to a variety of tools and practices in the DevSecOps ecosystem. Following the roadmap allowed me to gradually build my knowledge, automate processes, and enhance the security and scalability of my systems.  

Thank you for checking out my journey!

