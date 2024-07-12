workspace {

    model {
        customer = person "User"
        provider = person "Service Providers"
        
        backend = softwareSystem "Anaytics Backend" {
            database = container "Database"
            api = container "Service API" {
                -> database "Uses"
            }
        }

        magda = softwareSystem "Metadata/Magda" "Metadata catalog" "Existing System" {
            magdaRegistry = container "Magda Registry" "Provides metadata and revord storage" "Scala" "Existing System"
        }
        registry = softwareSystem "Docker Registry" "Holds all the analytics steps provided by service providers" "Existing System"
        argo = softwareSystem "Workflow/Argo" "Workflow engine executing all orders" "Existing System" {
            argoService = container "Argo Service" "Provides a workflow engine" "Go" "Existing System"
        }
        minio = softwareSystem "Storage/Minio" "Storage for all artifacts used and produced in the system" "Existing System" {
            minioService = container "Minio Service" "Provides Artifact storage" "Go" "Existing System"
        }

        customer -> backend "discovers and orders analytics services from"
        provider -> backend "submits and manages service to be offerend on the marketplace"

        backend -> magda "stores orders, services, workflows and artifacts"
        backend -> registry "fetches containers implementing the analytics steps involved in executing order"
        backend -> argo "executes the workflows provided by a service to execute order" 
        backend -> minio "stores and fetches artifacts created or used during execution of an order"

        deploymentEnvironment "Staging" {
            deploymentNode "AKS" {
                containerInstance api
                containerInstance magdaRegistry
                containerInstance argoService
                containerInstance minioService "Existing System"
            }
            deploymentNode "Azure" {
                infrastructureNode "Registry Service" "Provides a managed docker registry" "?" "Existing System"
            }
        }
    }

    views {
        systemContext backend {
            include *
            autolayout
        }
 
        deployment * "Staging" {
            include *
            autolayout
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Existing System" {
                background #999999
                color #ffffff
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