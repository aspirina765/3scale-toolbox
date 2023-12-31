## Metric

* [Create new metric](#create)
* [Apply metric](#apply)
* [List metrics](#list)
* [Delete metric](#delete)

### Create

* Creates a new metric
* Only metric name is required. `system-name` can be override with optional parameter.
* `service` positional argument is a service reference. It can be either service `id`, or service `system_name`. Toolbox will figure it out.
* This is not idempotent command. If metric with the same name already exists, command will fail.
* Create a `disabled` metric by `--disabled` flag. By default, it will be `enabled`.
* Several other options can be set. Check `usage`

```shell
NAME
    create - create metric

USAGE
    3scale metric create [opts] <remote>
    <service> <metric-name>

DESCRIPTION
    Create metric

OPTIONS
       --description=<value>      Metric description
       --disabled                 Disables this metric in all application
                                  plans
    -o --output=<value>           Output format. One of: json|yaml
    -t --system-name=<value>      Metric system name
       --unit=<value>             Metric unit. Default hit
```

### Apply

* Update existing metric. Create new one if it does not exist.
* `service` positional argument is a service reference. It can be either service `id`, or service `system_name`. Toolbox will figure it out.
* `metric` positional argument is a metric reference. It can be either metric `id`, or metric `system_name`. Toolbox will figure it out.
* This is command is `idempotent`.
* Update to `disabled` metric by `--disabled` flag.
* Update to `enabled` metric by `--enabled` flag.
* Several other options can be set. Check `usage`

```shell
NAME
    apply - Update metric

USAGE
    3scale metric apply [opts] <remote> <service>
    <metric>

DESCRIPTION
    Update (create if it does not exist) metric

OPTIONS
       --description=<value>      Metric description
       --disabled                 Disables this metric in all application
                                  plans
       --enabled                  Enables this metric in all application
                                  plans
    -n --name=<value>             Metric name
    -o --output=<value>           Output format. One of: json|yaml
       --unit=<value>             Metric unit. Default hit
```

### List

```shell
NAME
    list - list metrics

USAGE
    3scale metric list [opts] <remote> <service>

DESCRIPTION
    List metrics

OPTIONS
    -o --output=<value>           Output format. One of: json|yaml
```

### Delete

```shell
NAME
    delete - delete metric

USAGE
    3scale metric delete [opts] <remote>
    <service> <metric>

DESCRIPTION
    Delete metric
```
