# Software Development Kit (SDK)

Use the SDK to simplify developing services for the __IVCAP__ platform using Python.
The SDK abstracts the complexity of the underlying service architecture and API calls used in __IVCAP__ clients and services.

## Using the sdk for the ivcap_service

Start using the SDK easily by locating, downloading and starting your service repo from the [Reinventingscience ivcap-python-service-example](https://github.com/reinventingscience/ivcap-python-service-example) repo on [github](https://github.com/).

Make the _IVCAP_ Demo service using the instructions in the `README`

Import the high level resources and methods from `ivcap_sdk_service` and use them to build your service to accelerate development and ensure consistency and data integrity for the data used and generated with your service.

## Use Cases

### Implement a service

Build a complete service using the SDK and Python to build the container, interface with IVCAP and the main service.

### Run an analytics engine

Build an deployable service for an analytics engine that may be an existing application.
Where the existing application can be a self-contained executable running as though it was running on a local machine.  
Use the SDK with Python to build the container, setup the environment and analytics pre-conditions, interface with IVCAP, manage the data (source input files, and store output/results), run and monitor the analytics service/application, update reporting, and clean-up the post analytics environment nicely.

## Building a Service

When building your service, consider structuring your code to mirror the core items at play.

One approach might be to define a simple service to carry out a single task over a collection of Artifacts.
The overall service package structure may be as simple as a support class to for the iterating over the collection, the getting and putting of the artifacts and another class to carry out the task on an artifact.

Services that contain more than one task are known as complex services.

needed things for a service:
* Service Object with key fields populated
* The service method
* service registration

### Service Name

Name your service that helps your users understand what it does, such as `load_artifacts`.

### The Service description

Help service users to discover and use your service by setting this key information in the Service `object`.
This information should help the users to discover your service, describe what it is, what it does, what to use it for (and what not to use it for), how to use it, and the parameters they should provide.

This example shows the service name and description being set in the `name`, and `description` fields, along with some `parameters   that are to be used by the service.
```python
SERVICE = Service(
    name = "load-artifact",
    description = "Service to test loading and saving of artifacts",
    parameters = [
        Parameter(
            name='msg', 
            type=Type.STRING, 
            description='Message to display.'),
        Parameter(
            name='model', 
            type=Type.ARTIFACT, 
            description='Model to use (tgz archive of all needed components)'),
        Parameter(
            name='image', 
            type=Type.ARTIFACT, 
            description='Image to analyse'),
        Parameter(
            name='batch-size', 
            type=Type.INT, 
            description='Mini batch size of one gpu or cpu.',
            default=1),
        Parameter(
            name='device',
            type=Type.OPTION,
            options=[Option(value='cpu'), Option(value='gpu')],
            default="cpu",
            description="Select which device to inference, defaults to gpu."),
        # ... Parameters used by your service and any default values they may have.
    ]
)
```
Set your `providerID` with your ivcap provider number, i.e. `ivcap:provider:0000-0000-0000`

### Define the service

Define the entrypoint (main method) for the service

```python
def service(args: Dict, logger: logging):
    logger.info(f"Called with {args}")
    with args.load.open(asBinary=False) as f:
        # your service code...
```

Register the service with using the `register_service` method

```python
register_service(SERVICE, load_artifact) 
```

### Orders

TODO

#### Ordering a service

TODO

#### Checking the status of an order

TODO

#### Getting the results of an order
