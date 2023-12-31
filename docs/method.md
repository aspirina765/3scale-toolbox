## Method

* [Create new method](#create)
* [Apply method](#apply)
* [List methods](#list)
* [Delete method](#delete)

### Create

* Creates a new method
* Only method name is required. `system-name` can be override with optional parameter.
* `service` positional argument is a service reference. It can be either service `id`, or service `system_name`. Toolbox will figure it out.
* This is not idempotent command. If method with the same name already exists, command will fail.
* Create a `disabled` method by `--disabled` flag. By default, it will be `enabled`.
* Several other options can be set. Check `usage`

```shell
NAME
    create - create method

USAGE
    3scale method create [opts] <remote>
    <service> <method-name>

DESCRIPTION
    Create method

OPTIONS
       --description=<value>      Method description
       --disabled                 Disables this method in all application
                                  plans
    -o --output=<value>           Output format. One of: json|yaml
    -t --system-name=<value>      Method system name
```

### Apply

* Update existing method. Create new one if it does not exist.
* `service` positional argument is a service reference. It can be either service `id`, or service `system_name`. Toolbox will figure it out.
* `method` positional argument is a method reference. It can be either method `id`, or method `system_name`. Toolbox will figure it out.
* This is command is `idempotent`.
* Update to `disabled` method by `--disabled` flag.
* Update to `enabled` method by `--enabled` flag.
* Several other options can be set. Check `usage`

```shell
NAME
    apply - Update method

USAGE
    3scale method apply [opts] <remote> <service>
    <method>

DESCRIPTION
    Update (create if it does not exist) method

OPTIONS
       --description=<value>      Method description
       --disabled                 Disables this method in all application
                                  plans
       --enabled                  Enables this method in all application
                                  plans
    -n --name=<value>             Method name
    -o --output=<value>           Output format. One of: json|yam
```

### List

```shell
NAME
    list - list methods

USAGE
    3scale method list [opts] <remote> <service>

DESCRIPTION
    List methods

OPTIONS
    -o --output=<value>           Output format. One of: json|yaml
```

### Delete

```shell
NAME
    delete - delete method

USAGE
    3scale method delete [opts] <remote>
    <service> <method>

DESCRIPTION
    Delete method
```
