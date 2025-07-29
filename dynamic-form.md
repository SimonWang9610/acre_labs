# Dynamic Custom Form Proposal
This proposal aims to extend the existing custom form to support user interactions in a custom form, and as a result of that, a custom form would render different fields according to user interactions (e.g., dropdown selection/text input/check selection).


# Schemas

## `@preset`
> `@preset` is optional. If provided, the field value will be initialized with the preset values.

```json
{
   "@preset": <UIAction>
}
```

It means the field will be initialized with the value provided in `@preset`. If the field is a dropdown, it will be initialized with the selected item. If the field is a text input, it will be initialized with the text.

## `@ui-configuration`
> `@ui-configuration` is optional. If provided, it will be used to configure the UI behavior of the field.

```json
{
   "@ui-configuration": <UIConfiguration>
}
```

Typically, it is used to describe the field's UI behavior, such as whether it is optional, required, or has a hint.

## `@actions`
> `@actions` is optional. If provided, it will be used to configure the actions that will be triggered when the field is selected or interacted with.

```json
{
    "@actions": {
        "triggerKey": {
            "fieldA": <UIAction>,
            "fieldB": <UIAction>,
        },
        "triggerKey2": {
            "fieldC": <UIAction>,
            "fieldD": <UIAction>,
        }
    }
}
```

It means when the `triggerKey` is focused (e.g., selected in a dropdown, checked/unchecked in a checkbox), the `fieldA` and `fieldB` will be notified and execute the corresponding `UIAction`


## UIAction
> `@state` is optional. if not provided, defaults to `{visible: true, readonly: false}`; Any missing field would be filled by the corresponding default field value.

> `@data` is optional. If provided, it must be passed carefully by the developer to ensure its value compatible with the final submitted value of this field.

> `@data` will REPLACE the current value instead of merging with the current value. 

```json
{
    "@state": {
        "visible": <boolean>,
        "readonly": <boolean>
    },
    "@data": <consistent with the datatype submitted to the server for this field>
}
```

### Examples

#### CheckBoxWidget (labeled as `Include Child Folders`)

```json
{
    "@data": true
}
```
Any action triggers `@data` of this field will update its value in `CFManager`. For this field, it will submit as:
```json
{
    "Include Child Folders": true
}
```

#### DropdownButtonFormField (single-selection, labeled as `Door Mode`)
> assume we want to submit its value as an object
> developers must ensure the selected item can be found in the dropdown item list

```json
{
    "@data": {
        "key": "Normal",
        "value": 0
    }
}
```

Any action triggers `@data` of this field will update its value in `CFManager`. For this field, it will submit as:
```json
{
    "Door Mode": {
        "key": "Normal",
        "value": 0
    }
}
```

#### DropdownButtonFormField (multi-selection, labeled as `Door Groups`)
> assume we want to submit its value as a list of objects
> developers must ensure the selected items can be found in the dropdown item list
```json
{
    "@data": [
        {
            "key": "Group1",
            "value": 1
        },
        {
            "key": "Group2",
            "value": 2
        }
    ]
}
```
Any action triggers `@data` of this field will update its value in `CFManager`. For this field, it will submit as:
```json
{
    "Door Groups": [
        {
            "key": "Group1",
            "value": 1
        },
        {
            "key": "Group2",
            "value": 2
        }
    ]
}
```


#### TextFormFieldWidget (labeled as `Template Name`)
```json
{
    "@data": "Main Door Template"
}
```
Any action triggers `@data` of this field will update its value in `CFManager`. For this field, it will submit as:
```json
{
    "Template Name": "Main Door Template"
}
```

## UIConfiguration
> developers could create different UI configurations for different fields, and the following is the common schema for all fields.
> TODO: add more fields from the existing custom form definitions

```json
{
    "isOptional": <boolean>,
    "isRequired": <boolean>,
    "hint": "<string>",
    "dropdownType": "<data-source-type | optional>",
    "nonField": <boolean | optional>,
}
```

If `nonField` is set to true, it indicates that this field is not part of the form submission and it is only for UI purposes. For example, it could be used to display a message or a section header.

# Examples

## DropdownButtonFormField

Old schema with the support of dynamic actions, it will not introduce any break changes to the existing custom form definitions. We only introduce `@actions` to the existing schema, and it will be used to configure the actions that will be triggered when the field is selected or interacted with.

For now, `@actions` only supports on those fields whose have predefined values instead of fetching values from our server. Because, we need to know the `triggerKey` exactly to bind the actions to corresponding fields.

```json
{
    "type": "DropdownButtonFormField",
    "label": "Door Template",
    "isMultiSelect": false,
    "hint": "Select a Door Template",
    "items": [
        {
            "key": "No access on holidays",
            "value": "68238b0830686665579732a1",
            "child": {
                "type": "Text",
                "data": "No access on holidays"
            }
        },
        {
            "key": "Side door access for open house",
            "value": "68238b0830686665579732a2",
            "child": {
                "type": "Text",
                "data": "Side door access for open house"
            }
        }
    ],
    "initialValue": {
        "key": "No access on holidays",
        "value": "68238b0830686665579732a1"
    },
    "@actions": {
        "No access on holidays": {
            "One Time Event": {
                "@state": {
                    "readonly": true
                },
                "@data": false,
            },
            "Schedule": {
                "@data": "0 0 * * 6"
            },
            "Duration": {
                "@state": {
                    "visible": false,
                },
            },
            "Affected Door Groups": {
                "@state": {
                    "visible": true,
                },
                "@data": [
                    {
                        "key": "Main Doors",
                        "value": "68238b0830686665579732a1"
                    },
                    {
                        "key": "Side Doors",
                        "value": "68238b0830686665579732a2"
                    }
                ]
            },
            "Door Mode": {
                "@data": {
                    "key": "Locked",
                    "value": 1
                }
            }
        },
        "Side door access for open house": {
            "One Time Event": {
                "@state": {
                    "readonly": true
                },
                "@data": true,
            },
            "Schedule": {
                "@state": {
                    "visible": false,
                },
            },
            "Duration": {
                "@state": {
                    "visible": true,
                },
                "@data": "4h"
            },
            "Affected Door Groups": {
                "@state": {
                    "visible": true,
                },
                "@data": [
                    {
                        "key": "Side Doors",
                        "value": "68238b0830686665579732a2"
                    }
                ]
            },
            "Door Mode": {
                "@data": {
                    "key": "Unlocked",
                    "value": 2
                }
            }
        }
    }
}
```

By using `SchemaConverter`, we can convert the old schema to the new schema with dynamic actions support.

```json
{
    "type": "DropdownButtonFormField",
    "label": "Door Template",
    "items": [
        {
            "key": "No access on holidays",
            "value": "68238b0830686665579732a1",
            "child": {
                "type": "Text",
                "data": "No access on holidays"
            }
        },
        {
            "key": "Side door access for open house",
            "value": "68238b0830686665579732a2",
            "child": {
                "type": "Text",
                "data": "Side door access for open house"
            }
        }
    ],
    "@preset": {
        "@data": {
            "key": "No access on holidays",
            "value": "68238b0830686665579732a1"
        },
    },
    "@ui-configuration": {
        "isMultiSelect": false,
        "hint": "Select a Door Template",
    },
    "@actions": {
        "No access on holidays": {
            "One Time Event": {
                "@state": {
                    "readonly": true
                },
                "@data": false,
            },
            "Schedule": {
                "@data": "0 0 * * 6"
            },
            "Duration": {
                "@state": {
                    "visible": false,
                },
            },
            "Affected Door Groups": {
                "@state": {
                    "visible": true,
                },
                "@data": [
                    {
                        "key": "Main Doors",
                        "value": "68238b0830686665579732a1"
                    },
                    {
                        "key": "Side Doors",
                        "value": "68238b0830686665579732a2"
                    }
                ]
            },
            "Door Mode": {
                "@data": {
                    "key": "Locked",
                    "value": 1
                }
            }
        },
        "Side door access for open house": {
            "One Time Event": {
                "@state": {
                    "readonly": false
                },
                "@data": true,
            },
            "Schedule": {
                "@state": {
                    "visible": false,
                },
            },
            "Duration": {
                "@state": {
                    "visible": true,
                },
                "@data": "4h"
            },
            "Affected Door Groups": {
                "@state": {
                    "visible": true,
                },
                "@data": [
                    {
                        "key": "Side Doors",
                        "value": "68238b0830686665579732a2"
                    }
                ]
            },
            "Door Mode": {
                "@data": {
                    "key": "Unlocked",
                    "value": 2
                }
            }
        }
    }
}
```

The above schema means:

1. When users select "No access on holidays", the following fields will be shown:
   - One Time Event: readonly, with a value of `false`
   - Schedule: with a value of `0 0 * * 6`
   - Duration: hidden
   - Affected Door Groups: visible, with the list of the given two groups
   - Door Mode: set to "Locked"
2. When users select "Side door access for open house", the following fields will be shown:
   - One Time Event: readonly, with a value of `true`
   - Schedule: hidden
   - Duration: visible, with a value of `4h`
   - Affected Door Groups: visible, with the list of the given group
   - Door Mode: set to "Unlocked"
