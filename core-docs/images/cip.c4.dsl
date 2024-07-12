workspace "CRE" {

  model {
    customer = person "Marketplace Customer"
    provider = person "Service Providers"
    
    enterprise "Climate Intelligence Platform - CIP" {
      
      providerPortal = softwareSystem "API Gateway" {
          providerAPI = container "Provider API" "Implememnts public API" "Go"{
            caddy = component "Caddy" "Http and grpc" "Go" "Existing System"
            opa = component "OPA" "Authorizer" "Go" "Generated Component"
            goa = component "API router" "Authorizer" "Go" "Generated Component"
            services = component "Services" "Service implementation" "Go"
          }
      }
      
      orderDispatcher = softwareSystem "Order Dispatcher" "Creates approproiate workflow from templates and schedules them with Argom" {
        orderDispatcherService = container "Order Dispatcher Service" "Creates approproiate workflow from templates and schedules them with Argo" "Go"
      }

      magda = softwareSystem "Magda Service" "Terria's Metadata catalog" "Terria" {
        magdaAPIServer = container "Magda API Server" "Primary entrypoint for Magda service" "Scala" "Existing System"
        magdaRegistry = container "Magda Registry" "Provides metadata and revord management" "Scala" "Existing System"
        magdaDB = container "Magda Database" "Holds all persistent metadata" "Postgres" "Existing System"
        magdaSearch = container "Magda Search" "Elastic search over all metadata" "ElasticSearch" "Existing System"
      }
      
      argo = softwareSystem "Argo" "Workflow engine executing all orders" "Extended System" {
        workflowController  = container "Argo WF Controller" "" "Go" "Existing System"
        analyticsStep  = container "Ananlytics Step" "Provider supplied container" "" "Provider Container"
        dataProxy = container "Data Proxy" "Captures all in and outgoing data from workflow tasks" "Go"
        exitHandler = container "Exit Handler" "Monitors and reports workflow state" "Go"
      }
      
      minioProxy = softwareSystem "Minio Gateway" "Storage for all artifacts used and produced in the system" "Existing System" 
    }
    
    webFrontend = softwareSystem "Customer Front-End" "Developed by Avanade" "ThirdParty System"
    clientSDK = softwareSystem "Client SDK" "SDK for embedded analytics" 
    serverSDK = softwareSystem "Server SDK" "SDK for building services" 
    
    azureBlobStore = softwareSystem "Az Blob Store" "" "Existing System" 
    
    registry = softwareSystem "Az Container Registry" "Holds all the analytics steps provided by service providers" "Existing System"

    //=========================
    // Relationships
    customer -> webFrontend "user centric way of interacting with marketplacem"
    webFrontend -> providerPortal "discovers and orders analytics services from"
    customer -> providerPortal "discovers and orders analytics services from"
    customer -> clientSDK "embeded into customer's analytics tool"
    clientSDK -> providerPortal "discovers and orders analytics services from"
    
    provider -> providerPortal "manages its services on the marketplace"
    provider -> serverSDK "uses"

    
    providerPortal -> orderDispatcher "forward incoming orders for processing"
    providerPortal -> registry "stores provider supplied dockerised analytics steps"
    providerPortal -> magda "reads and writes all relevant metadata (orders, services, accounts, ...)"
    providerPortal -> minioProxy "reads and writes artifacts"
    
    
    
    orderDispatcher -> argo "dispatch order specific workflows"
    orderDispatcher -> magda "stores provenance & metadata of order related workflows"

    // Argo intornal
    workflowController -> registry "fetches containers implementing the analytics steps involved in executing order"
    workflowController -> analyticsStep "run based on workflow description"
    analyticsStep -> dataProxy "retrieve and store data"
    dataProxy -> minioProxy "stores produced data products"
    dataProxy -> magda "stores metadata for accessed and produced data"
    workflowController -> exitHandler "called on workflow exit"
    exitHandler -> magda "update workflow/order state"
    
    minioProxy -> azureBlobStore "use cloud storage"
    
    caddy -> opa "authorize request"
    caddy -> goa "route request"
    goa -> services "handle request"
    
    # Magda
    magdaAPIServer -> magdaRegistry
    magdaAPIServer -> magdaDB
    magdaDB -> magdaSearch


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
    systemlandscape "CustomerView-CIP" {
        include customer webFrontend clientSDK providerPortal
        autoLayout 
    }
    
    systemlandscape "ProviderView-CIP" {
        include provider providerPortal registry serverSDK
        autoLayout 
    }

    systemcontext providerPortal "SystemContext-CIP" {
        include  orderDispatcher  
        include minioProxy magda  
        include registry azureBlobStore argo
        exclude "orderDispatcher -> magda"
        autoLayout
    }

    systemcontext orderDispatcher "OrderDispatcher-CIP" {
        include providerPortal magda argo
        exclude "providerPortal -> magda" "argo -> magda"
        autoLayout
    }
    
    container argo "WorkflowExecutor-CIP" {
        include *
        autoLayout
    }
    
    container magda "MagdaMetaDataService-CIP" {
        include *
        autoLayout
    }

    component providerAPI "APIGateway-CIP" {
        include *
        autoLayout
    }
    
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
          
          element "Terria" {
              background #08abd5
              color #ffffff
          }
          
          element "Extended System" {
              background #99b2c9
              color #ffffff
          }
          
          element "Generated Component" {
              background #c0a2f2
              color #ffffff
          }
          
          element "Existing System" {
              background #999999
              color #ffffff
          }
          element "ThirdParty System" {
              background #F47A24
              color #ffffff
          }
          
          
          element "Provider Container" {
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
