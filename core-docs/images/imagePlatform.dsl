workspace "CSIRO" {

  model {
    collector = person "Data Collector"
    customer = person "Platform User"
    provider = person "Analytics Provider"
    
    
    enterprise "Image Analytics Platform" {
      analyticsService = softwareSystem "Analytics Portal" {
      }
      
      providerPortal = softwareSystem "Provider Portal" {
          providerAPI = container "Provider API" {
          }
      }
      
      ingestService = softwareSystem "Data Ingestion Portal" {
        ingestAPI = container "Ingest API Server"
        ingestQueue = container "Processing Queue"
      }

      magda = softwareSystem "Provenance Service" "Metadata catalog" {
        magdaRegistry = container "Magda Registry" "Provides metadata and revord storage" "Scala" "Existing System"
      }
      
      argo = softwareSystem "Workflow Executer" "Workflow engine executing all orders" {
        orderDispatcher = container "Order Dispatcher" "Creates approproiate workflow from templates and schedules them with Argom"
        argoService = container "Argo Service" "Provides a workflow engine" "Go" "Existing System"
        analyticsTask = container "Analytics Task" "Provided by Analytics Providers" "Docker" "Provided Task"
        dataProxy = container "Data Service" "Captures all in and outgoing data from workflow tasks"
        ensembleService = container "Ensemble Service" "Provides subset of data according to some criteria"
      }
    }
    
    minio = softwareSystem "Storage" "Storage for all artifacts used and produced in the system" "Existing System" {
      minioService = container "Minio Service" "Provides Artifact storage" "Go" "Existing System"
    }
  
    registry = softwareSystem "Docker Registry" "Holds all the analytics steps provided by service providers" "Existing System"

    // Relationships
    customer -> analyticsService "discovers and orders analytics services from"

    analyticsService -> magda "stores orders, search existing services"
    analyticsService -> argo "executes the workflows provided by a service to execute order" 
    argo -> registry "fetches containers implementing the analytics steps involved in executing order"
    argo -> minio "stores produced data products"
    argo -> magda "stores proveance on workflows and created artifacts"
    analyticsService -> minio "stores and fetches artifacts created or used during execution of an order"

    provider -> providerPortal "manages life cycle of services offered"
    providerPortal -> magda "stores service sescriptions and workflow templatess"
    providerPortal -> registry "stores containers implementing the analytics steps offered"

    collector -> ingestService "ingests data into platform for further analysis"
    ingestService -> magda "stores provenance & metadata on ingested data"
    ingestService -> minio "stores ingested data"
    
    # relationships to/from containers
    analyticsService -> orderDispatcher
    orderDispatcher -> argoService "Schedule workflow"
    orderDispatcher -> magda "Register provenance of analytics job"
    argoService -> registry
    argoService -> analyticsTask "Schedules tasks according to workflow"
    analyticsTask -> dataProxy "Request and provide data for analytics"
    dataProxy -> minio "Fetch and store data"
    dataProxy -> magda "Store provenance of data requested or produced"
    
    analyticsTask -> ensembleService
    ensembleService -> minio
    ensembleService -> magda
    
    # Inget Portal
    collector -> ingestAPI "ingests data into platform for further analysis"
    ingestAPI -> ingestQueue "enqueue for immediate processing"
    ingestQueue -> argo "dispatrch for processing"
    ingestAPI -> minio "store data items"
    ingestAPI -> magda "store provenance and metadata"
    
    # deploymentEnvironment "Staging" {
    #   deploymentNode "AKS" {
    #     containerInstance serviceAPI
    #     containerInstance magdaRegistry
    #     containerInstance argoService
    #     containerInstance minioService "Existing System"
    #   }
    #   deploymentNode "Azure" {
    #     infrastructureNode "Registry Service" "Provides a managed docker registry" "?" "Existing System"
    #   }
    # }
  }

  views {
    systemlandscape "SystemLandscape" {
        include *
        exclude argo -> magda
        exclude analyticsService -> minio
        autoLayout 
    }
    
    systemcontext ingestService "IngestContext" {
        include *
        autoLayout
    }

    systemcontext providerPortal "ProviderContext" {
        include *
        autoLayout
    }

    systemcontext analyticsService "UserContext" {
        include *
        autoLayout
    }
    
    container argo "WorkflowExecutor" {
        include *
        autoLayout
    }
    
    container ingestService "ingestService" {
        include *
        autoLayout
    }
    
    # deployment * "Staging" {
    #     include *
    #     autolayout
    # }

    theme default

      styles {
          element "Person" {
              color #ffffff
              fontSize 22
              shape Person
          }
          element "Customer" {
              background #08427b
          }
                  element "Support Staff" {
              background #999999
          }
  
          element "Software System" {
              background #1168bd
              color #ffffff
          }
          element "Existing System" {
              background #999999
              color #ffffff
          }
          element "Provided Task" {
              background #d400ff
          }
          element "Container" {
              background #438dd5
              color #ffffff
          }
          element "Web Browser" {
              shape WebBrowser
          }
          element "Mobile App" {
              shape MobileDeviceLandscape
          }
          element "Database" {
              shape Cylinder
          }
          element "Component" {
              background #85bbf0
              color #000000
          }
          element "Failover" {
              opacity 25
          }
      }
  }
    
}