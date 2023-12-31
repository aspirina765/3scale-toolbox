## Service

* [Create new service](#create)
* [Apply service](#apply)
* [List services](#list)
* [Show service](#show)
* [Delete service](#delete)
* [Copy service](copy-service.md)

### Create

* Creates a new service
* Only service name is required. `system-name` can be overridden with an optional parameter.
* This is not idempotent command. If service with the same name already exists, the command will fail.
* Several other options can be set. Check `usage`

```shell
NAME
    create - Create a service

USAGE
    3scale service create [options] <remote>
    <service-name>

DESCRIPTION
    Create a service

OPTIONS
    -a --authentication-mode=<value>      Specify authentication mode of the
                                          service ('1' for API key, '2' for
                                          App Id / App Key, 'oauth' for OAuth
                                          mode, 'oidc' for OpenID Connect)
    -d --deployment-mode=<value>          Specify the deployment mode of the
                                          service
       --description=<value>              Specify the description of the
                                          service
    -o --output=<value>                   Output format. One of: json|yaml
    -s --system-name=<value>              Specify the system-name of the
                                          service
       --support-email=<value>            Specify the support email of the
                                          service
```

### Apply

* Update existing service. Create new one if it does not exist.
* `service-id_or_system-name` positional argument is a service reference. It can be either service `id`, or service `system_name`. Toolbox will figure it out.
* This is command is `idempotent`.
* Several other options can be set. Check `usage`

```shell
NAME
    apply - Update service

USAGE
    3scale service apply <remote>
    <service-id_or_system-name>

DESCRIPTION
    Update (create if it does not exist) service

OPTIONS
    -a --authentication-mode=<value>      Specify authentication mode of the
                                          service ('1' for API key, '2' for
                                          App Id / App Key, 'oauth' for OAuth
                                          mode, 'oidc' for OpenID Connect)
    -d --deployment-mode=<value>          Specify the deployment mode of the
                                          service
       --description=<value>              Specify the description of the
                                          service
    -n --name=<value>                     Specify the name of the metric
    -o --output=<value>                   Output format. One of: json|yaml
       --support-email=<value>            Specify the support email of the
                                          service
```

### List

```shell
NAME
    list - List all services

USAGE
    3scale service list <remote>

DESCRIPTION
    List all services

OPTIONS
    -o --output=<value>           Output format. One of: json|yaml
```

### Show
```shell
NAME
    show - Show the information of a service

USAGE
    3scale service show <remote>
    <service-id_or_system-name>

DESCRIPTION
    Show the information of a service

OPTIONS
    -o --output=<value>           Output format. One of: json|yaml
```


### Delete

```shell
NAME
    delete - Delete a service

USAGE
    3scale service delete <remote>
    <service-id_or_system-name>

DESCRIPTION
    Delete a service
```
