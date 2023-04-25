# SDK resources and methods

## SDK module resources

The more commonly used resources include:

| Resource | Resource type | Description |
| --- | --- | --- |
| [`Service`](#service) | class | the class describing the service and its methods: |
|   `from_file` | class method | Enables the data for the class to be read from a yaml file |
|   `to_dict` | class method | TODO |
|   `to_yaml` | class method | Enables the class data to be serialised into a yaml string (that can be dumped out to a file) |
|   `append_arguments` | class method | TODO |
| [`Parameter`](#parameter) | class | defines the structure of the parameter as used in the service parameters |
| [`Option`](#option) | class | defines the options that be used for a parameter |
| [`Type`](#type) | class | defines the parameter | 
| [`register_service`](#register_service) | function | is used to register the service with the __IVCAP__ server |
| [`deliver`](#deliver) | function | is used to deliver the output of the service for storage |
| [`cache_file`](#cache_file) | function | is used to get an artifact to be used for analysis |

### Import SDK resources

Import the specific `ivcap_sdk_service` resources that you will use in your service.  As this helps reduce the overall space requirements for your service.

An example for importing the `ivcap_sdk_service` package resources:
``` python
from ivcap_sdk_service import Service, Parameter, Option, Type, register_service, deliver, cache_file
```
## Service

Describe and define the service data objects held using the _Service_ dataclass which extends the _JSONWizard_ class.  Describing the service defines the `ServiceDescriptionT` json fields needed for to call the service (handler) and holds the data which describes how to use the service.

Note: Default values for the `service-id` (`id`), `provider-id`, and `account-id` are set in the container environment with the `MakeFile`.

Define default values for the key arguments and data items in a `Service` object that is used to register your `service`, i.e.:

```python
# Define Service data and parameters
MY_SERVICE_DEFINITION = Service(
    name = "service name",
    description = "description that makes sense to service users",
    parameters = [
        Parameter(
            name='msg', 
            type=Type.STRING, 
            description='Message to display.'),
            # ... List of data items and paramaters for the service object
    ]
)

# Define service 
def my_service(args: Dict, svc_logger: logging)
    # ... code for your_service

# Register service
register_service(MY_SERVICE_DEFINITION, my_service)
```

## Parameter

Pass data to the service using the parameters defined by the `Parameter` data class.
_Parameter_ extends _JSONWizard_ and is used in the `parameters` JSON field within the `ServiceDescriptionT` json object.

Read the parameters 

```python
MY_SERVICE_ARGS = Service(
    #... define the collection of parameter values
    parameters = [
        Parameter(
            name='msg', 
            type=Type.STRING, 
            description='Message to display.'),
        Parameter(
            name='img-art', 
            type=Type.ARTIFACT, 
            description='Image artifact to use as background.',
            optional=True),
        Parameter(
            name='img-url', 
            type=Type.STRING, 
            description='Image url (external) to use as background.',
            optional=True),
        Parameter(
            name='width', 
            type=Type.INT, 
            description='Image width.',
            default=640),
        Parameter(
            name='height', 
            type=Type.INT, 
            description='Image height.',
            default=480),
    ]
)

def my_service(args: Dict, svc_logger: logging)
    # ... code for your_service
    # Use parameter values with a simpler reference Create an image
    img = Image.new("RGB", (args.width, args.height), "white")
    # Testing and using parameter values that have the parameter name de-hyphenated
    if args.img_url:
        # code
```

Note: Parameter JSON field names using hyphenated notation are converted to the Python naming convention for use within your code.
I.e. `img-url` is referenced as `img_url` and `enable-auto-tune` is referenced as `enable_auto_tune` within your code.

## Option

Set the name, description, and value for _Parameter_ options using the _Option_ class.

```python
SERVICE = Service(
    # Service parameter with options
    parameters = [
        Parameter(
            name='precision',
            type=Type.OPTION,
            options=[Option(value='fp32'), Option(value='fp16'), Option(value='int8')],
            default="fp32",
            description='The tensorrt precision.'),
        # other Service parameters
    ]
)

    # is referenced as `args.precision` from within your code

```

## Type

Use the global variable definitions for for the enumerated class _Type_ for consistency, and to use only parameter types that are handled by the _SDK_ and _IVCAP_.

Supported parameter types include _STRING_, _INT_, _FLOAT_, _BOOL_, _OPTION_, and _ARTIFACT_.
See their use in with [Parameters](#parameter) and [Options](#option).

## register_service

Register your service with _IVCAP_ using the `register_service` method with the [service definition and the service code](#service).  After your service is registered, users will be able to discover and use your service.

Print the service description and configuration as a yaml with the `register service` method and the command / command line argument of TODO - is this the best spot for this desc?

Print the detailed help for how to use the service with the `register service` method and the command / command line argument of TODO - is this the best spot for this desc

Make the call to [register_service](#service) after the service description, and the service handler definition.

## deliver

Save output and generated artifacts and metadata using the `deliver` helper function.  
The deliver function takes as its arguments the name for the artifact, either a lambda for the file or the data, and the meta data. 

Deliver saves the artifact and its metadata details and returns the saved url as is seen in the sample code.
The sample code sets some meta-data, saves the image via the __deliver__ function, and logs the action of saving the image and its url.

``` python
    meta = {'urn:schema:image': {'width', example_img.width, 'height', example_img.height}} # set/append meta-data
    url = deliver(basename, lambda f: example_img.save(f, format='png'), **meta) # lambda fn: example_img.save("img_name.png")) # fn, format='png'))
    logger.debug(f"saving example image ({example_img}) type as '{url}'") # log the image was saved

```

## cache_file

Download, a copy of the artifact into the cache directory (for the service) using the  url and returns the url for the cached artifact.

The cache folder may be specified using the `IVCAP_CACHE_DIR` environment variable.  When the `IVCAP_CACHE_DIR` is not specified, the sdk will attempt to put the cache in a `/cache` sub-directory to the directory which is used to run the service.

``` python
    # Create an image
    img = Image.new("RGB", (args.width, args.height), "white")
    
    # Add background
    if args.img_url:
        f = cache_file(args.img_url)
        background = Image.open(f)
        img.paste(background)

```

