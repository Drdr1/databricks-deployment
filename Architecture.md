# Modular Databricks Architecture

The following diagram illustrates the architecture of the modular Databricks setup:

```mermaid
graph TB
    subgraph "Root Module"
        Main[main.tf]
        Vars[variables.tf]
        Out[outputs.tf]
        Prov[providers.tf]
    end
    
    subgraph "Azure Resources"
        subgraph "Workspace Module"
            ADB[Azure Databricks Workspace]
        end
        
        subgraph "Unity Catalog Module"
            UC[Unity Catalog]
            SA[Storage Account]
            AC[Access Connector]
        end
    end
    
    subgraph "Databricks Resources"
        subgraph "Compute Module"
            IC[Inference Cluster]
            MC[Monitoring Cluster]
            IW[Inference SQL Warehouse]
            DW[Dashboard SQL Warehouse]
        end
        
        subgraph "Inference Module"
            IT[Inference Tables]
            IV[Inference Volumes]
        end
        
        subgraph "Monitoring Module"
            MT[Monitoring Tables]
            MJ[Monitoring Jobs]
        end
        
        subgraph "Dashboards Module"
            DQ[Dashboard Queries]
            DD[Dashboard Definitions]
        end
    end
    
    Main --> Workspace Module
    Main --> Unity Catalog Module
    Main --> Compute Module
    Main --> Inference Module
    Main --> Monitoring Module
    Main --> Dashboards Module
    
    Workspace Module --> ADB
    Unity Catalog Module --> UC
    Unity Catalog Module --> SA
    Unity Catalog Module --> AC
    
    Compute Module --> IC
    Compute Module --> MC
    Compute Module --> IW
    Compute Module --> DW
    
    Inference Module --> IT
    Inference Module --> IV
    
    Monitoring Module --> MT
    Monitoring Module --> MJ
    
    Dashboards Module --> DQ
    Dashboards Module --> DD
    
    ADB --> IC
    ADB --> MC
    ADB --> IW
    ADB --> DW
    
    SA --> UC
    AC --> SA
    
    IC --> IT
    MC --> MT
    
    MJ --> MT
    DQ --> MT
    DD --> DQ
    
    IW --> IT
    DW --> DQ
```

## Module Dependencies

The diagram shows the dependencies between modules:

1. **Workspace Module** is the foundation that all other modules depend on
2. **Unity Catalog Module** depends on the Workspace Module
3. **Compute Module** depends on the Workspace Module
4. **Inference Module** depends on the Workspace, Compute, and optionally Unity Catalog Modules
5. **Monitoring Module** depends on the Workspace and Compute Modules
6. **Dashboards Module** depends on the Workspace, Compute, and Monitoring Modules

This modular approach allows you to:
- Deploy only the modules you need
- Maintain each module independently
- Reuse modules across different environments
- Test modules in isolation