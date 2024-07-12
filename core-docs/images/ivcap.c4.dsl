workspace "CRE" {

  model {
    customer = person "User"
    provider = person "Workflow Providers"

    group "Intelligent Visual Collaboration Analytics Platform - IVCAP" {

      providerPortal = softwareSystem "API Gateway" {
          providerAPI = container "Provider API" "Implememnts public API" "Go"{
            caddy = component "Caddy" "Http and grpc" "Go" "Existing System"
            opa = component "OPA" "Authorizer" "Go" "Generated Component"
            goa = component "API router" "Authorizer" "Go" "Generated Component"
            workflows = component "Services" "Service implementation" "Go"
          }
      }

      orderDispatcher = softwareSystem "Order Dispatcher" "Creates appropriate workflow and schedules them with Argo" {
        orderDispatcherService = container "Order Dispatcher Service" "Creates appropriate workflow and schedules them with Argo" "Go"
      }

      queueService = softwareSystem "Queue Service" "Handles queue management and message handling"
      natsJetStream = softwareSystem "NATS JetStream Server" "Distributed messaging system delivering queue functionality"


      dfabric = softwareSystem "DataFabric Service" "" {
    }
    //   magda = softwareSystem "Magda Service" "Terria's Metadata catalog" "Terria" {
    //     magdaAPIServer = container "Magda API Server" "Primary entrypoint for Magda service" "Scala" "Existing System"
    //     magdaRegistry = container "Magda Registry" "Provides metadata and revord management" "Scala" "Existing System"
    //     magdaDB = container "Magda Database" "Holds all persistent metadata" "Postgres" "Existing System"
    //     magdaSearch = container "Magda Search" "Elastic search over all metadata" "ElasticSearch" "Existing System"
    //   }

      argo = softwareSystem "Argo" "Workflow engine executing all orders" "Extended System" {
        workflowController  = container "Argo WF Controller" "" "Go" "Existing System"
        analyticsStep  = container "Ananlytics Step" "Provider supplied container" "" "Provider Container"
        dataProxy = container "Data Proxy" "Captures all in and outgoing data from workflow tasks" "Go"
        exitHandler = container "Exit Handler" "Monitors and reports workflow state" "Go"
      }

      //minioProxy = softwareSystem "Storage Gateway" "Storage for all artifacts used and produced in the system" "Existing System"
    }

    // webFrontend = softwareSystem "Customer Front-End" "Developed by Avanade" "ThirdParty System"
    clientSDK = softwareSystem "Client SDK" "SDK for embedded analytics"
    serverSDK = softwareSystem "Server SDK" "SDK for building workflows"

    blobStore = softwareSystem "Blob Store" "" "Existing System"
    database = softwareSystem "Managed Database" "An SQL database, likely Postgres" "Existing System"

    registry = softwareSystem "Container Registry" "Holds all the analytics steps provided by workflow providers" "Existing System"

    //=========================
    // Relationships
    // customer -> webFrontend "user centric way of interacting with marketplacem"
    // webFrontend -> providerPortal "discovers and orders analytics workflows from"
    customer -> providerPortal "discovers and orders analytics workflows from"
    customer -> clientSDK "embeded into customer's analytics tool"
    clientSDK -> providerPortal "discovers and orders analytics workflows from"

    provider -> providerPortal "manages its workflows on the platform"
    provider -> serverSDK "uses"
    serverSDK -> providerPortal "manages its workflows on the platform"
    // TEMPORARY - Should ultimately be go away
    serverSDK -> registry "TEMPORARY: stores provider supplied dockerised analytics steps"

    providerPortal -> orderDispatcher "forward incoming orders for processing"
    providerPortal -> queueService "forward incoming queue resquests for processing"
    providerPortal -> registry "stores provider supplied dockerised analytics steps"
    providerPortal -> dfabric "reads and writes all relevant metadata (orders, workflows, accounts, ...)"
    providerPortal -> blobStore "reads and writes artifacts"


    orderDispatcher -> argo "dispatch order specific workflows"
    orderDispatcher -> dfabric "stores metadata of order related workflows"

    queueService -> dfabric "stores metadata of queue lifecycles"
    queueService -> natsJetStream "send requests to manage queues and deliver messages"

    // Argo internal
    workflowController -> registry "fetches containers implementing the analytics steps involved in executing order"
    workflowController -> analyticsStep "run based on workflow description"
    analyticsStep -> dataProxy "retrieve and store data"
    dataProxy -> blobStore "stores produced data products"
    dataProxy -> dfabric "stores metadata for accessed and produced data"
    workflowController -> exitHandler "called on workflow exit"
    exitHandler -> dfabric "update workflow/order state"

    // minioProxy -> blobStore "use cloud storage"

    caddy -> opa "authorize request"
    caddy -> goa "route request"
    goa -> workflows "handle request"

    # Magda
    // magdaAPIServer -> magdaRegistry
    // magdaAPIServer -> magdaDB
    // magdaDB -> magdaSearch
    dfabric -> database "persist and retrieve entities and their facets"

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
    systemlandscape "UserView" {
        include customer clientSDK providerPortal
        autoLayout
    }

    systemlandscape "WorkflowView" {
        include provider providerPortal registry serverSDK
        exclude "providerPortal -> registry"
        autoLayout
    }

    systemcontext providerPortal "SystemContext" {
        include  orderDispatcher
        include  queueService
        // include minioProxy magda
        include blobStore dfabric
        include registry blobStore argo
        //exclude "orderDispatcher -> magda"
        autoLayout
    }

    systemcontext orderDispatcher "OrderDispatcher" {
        include providerPortal dfabric argo
        //exclude "providerPortal -> magda" "argo -> magda"
        autoLayout
    }

    systemcontext queueService "QueueService" {
        include providerPortal dfabric natsJetStream
        exclude "providerPortal -> dfabric"
        autoLayout
    }

    container argo "WorkflowExecutor" {
        include *
        autoLayout
    }

    // container magda "MagdaMetaDataService" {
    //     include *
    //     autoLayout
    // }

    component providerAPI "APIGateway" {
        include *
        autoLayout
    }

    theme default

      styles {
          element "Person" {
              color #ffffff
              background #e5770d
              fontSize 22
              //shape Person
              shape Ellipse
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
