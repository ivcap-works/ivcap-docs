# SDK resources and methods

## SDK module resources and methods

The more commonly used resources include:

| Resource | Resource type | Description |
| --- | --- | --- |
| [`Service`](#service) | class | the class describing the service and its methods: |
|   `from_file` | class method | Enables the data for the class to be read from a yaml file |
|   `to_dict` | class method | returns a dict of the parameters for the service |
|   `to_yaml` | class method | Enables the class data to be serialised into a yaml string (that can be dumped out to a file) |
|   `append_arguments` | class method | returns an ArgumentParser for the service parameters |
| [`Parameter`](#parameter) | class | defines the structure of the parameter as used in the service parameters |
| [`Type`](#type) | class | defines the parameter |
| `SupportedMimeTypes` | Enum | An enumerated type for the supported MimeTypes of NETCDF, PNG, and JPEG |
| `ServiceArgs` | type | a subtype of the str type |
| [`register_service`](#register_service) | function | is used to register the service with the __IVCAP__ server |
| [`deliver_data`](#deliver_data) | function | is used to deliver the output of the service for storage |
| [`fetch_data`](#fetch_data) | function | is used to get an artifact to be used for analysis |
| [`create_metadata`](#create_metadata) | function | creates a metadata dict from the args |

### Import SDK resources

Import the specific `ivcap_sdk_service` resources that you will use in your service.  As this helps reduce the overall space requirements for your service.

An example for importing the `ivcap_sdk_service` package resources:
``` python
from ivcap_sdk_service import Service, Parameter, Type, SupportedMimeTypes, ServiceArgs
from ivcap_sdk_service import register_service, deliver_data, fetch_data, create_metadata
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


## Type

Use the global variable definitions for for the enumerated class _Type_ for consistency, and to use only parameter types that are handled by the _SDK_ and _IVCAP_.

Supported parameter types include _STRING_, _INT_, _FLOAT_, _BOOL_, _OPTION_, and _ARTIFACT_.
See their use in with [Parameters](#parameter).

## SupportedMimeTypes

Use the global variable definitions for for the enumerated class _SupportedMimeTypes_ for types that are handled by the _SDK_ and _IVCAP_.

Supported mime types include _NETCDF_, _PNG_, and _JPEG_.

See their use in with [deliver_data](#deliver_data).

## register_service

Register your service with _IVCAP_ using the `register_service` method with the [service definition and the service code](#service).  After your service is registered, users will be able to discover and use your service.

Load the detailed service description and help information in the [Parameter](#parameter) fields. 

Make the call to [register_service](#service) after the service description, and the service handler definition.

| Arg | Description | Default |
| --- | --- | --- |
| service (Service) | The Service object to register |  |
| handler (Callable[[Dict], int]) |  |  |

| Service Command | Return |
| --- | --- |
| `SERVICE_RUN` | attempts to run the service and passes the exit code to the system |
| `SERVICE_FILE` | creates a yaml file for the service parameters |
| `SERVICE_HELP` | creates the help text for how to use the service |
| anything else | Logs an entry for an unexpected command |

## deliver_data

Save output and generated artifacts and metadata using the `deliver_data` helper function.  
The deliver_data function takes as its arguments the name for the artifact, either a lambda for the file or the data, and the meta data. 

Deliver saves the artifact and its metadata details and returns the saved url as is seen in the sample code.
The sample code sets some meta-data, saves the image via the __deliver__ function, and logs the action of saving the image and its url.

| Arg | Description | Default |
| --- | --- | --- |
| name (str) | User friendly name |  |
| data_or_lambda (Union[Any, Callable[[IOWritable], None]]) | The data to deliver. Either directly or a callback providing a file-like handle for the data | |
| mime_type (Union[str, SupportedMimeTypes]) | The mime type of the data. Anything not starting with 'text' is assumed to be a binary content |  |
| collection_name (Optional[str], optional) | Optional collection name | Default None |
| metadata (Optional[Union[MetaDict, Sequence[MetaDict]]], optional) | Key/value pairs (or list of k/v pairs) to add as metadata | Default None |
| seekable (bool, optional) | If true, writable should be seekable (needed for NetCDF) | Default False |
| on_close (Optional[Callable[[Url]]], optional) | Called with assigned artifact ID | Default None |

| Raises | Description |
| --- | --- |
| NotImplementedError | Raised when no saver function is defined for 'type' |

| Returns | Description |
| --- | --- |
| None |  |

``` python
    meta = create_metadata('urn:ivcap.test:simple-python-service', **args._asdict())
    deliver_data("image.png", lambda fd: img.save(fd, format="png"), SupportedMimeTypes.JPEG, metadata=meta)
```

## fetch_data

Returns a file-like object providing the content of the reference file which may be the url or the ID for the file.

Args:

| Arg | Description | Default |
| --- | --- | --- |
| url (Url) | the Url for the image, the Url is a subtype of the str type |  |
| binary_content (bool) | boolean for if the file for in the Url has binary content | default True |
| no_caching (bool) | boolean for if the file is not to be cached | default False |
| seekable (bool) | boolean for if the file is seekable | default False |

| Returns | Description |
| --- | --- |
| IOReadable | The content of the artifact/item as a file-like object |

Use:
``` python
    # Create an image
    img = Image.new("RGB", (args.width, args.height), "white")
    
    # Add background
    if args.img_url:
        f = fetch_data(args.img_url)
        background = Image.open(f)
        img.paste(background)
        f.close() # the above code does not close the file
```

## create_metadata

Returns a dict for the args with the given schema URN added.

See create_metadata use in with [deliver_data](#deliver_data).

| Arg | Description | Default |
| --- | --- | --- |
| schema (str) | Schema URN |  |
| mdict Optional (MetaDict) | optional MetaDict is a (Dict[str, Union[str, Number, bool]]) type | {} empty dict |
| **args | reference to the input arguments |  |


| Returns | Description |
| --- | --- |
| Dict | a copy of the Args with the an additional entry for the schema |

