final jsonFormDefinitions = [
  {
    "type": "Align",
    "alignment": "center",
    "child": {"type": "Text", "data": "Edit Door Mode Template"}
  },
  {
    "type": "DropdownButtonFormField",
    "label": "Template",
    "hint": "Select the door mode template to edit.",
    "isRequired": true,
    "items": [
      {
        "key": "Weekend, No Access",
        "value": "68238b0830686665579732a1",
        // indicate if the item is preselected
        "selected": true,
        "description": "No access to the office on weekends.",

        /// actions indicate how it would affect other fields when this item is selected
        "actions": {
          "One Time Event": {
            // set value for this choice
            // the value type must match the field value type
            "value": "unchecked",
            "readonly": true // whether this field can be interacted with
          },
          "Schedule": {
            "value": "0 0 * * 6" // cron expression for schedule
          },
          "Duration": {
            "visible": false,
          },
          "Door Mode Duration": {"value": "2d"},
          "Affected Door Groups": {
            // if show this field
            "visible": true,

            /// the values must be presented in the dropdown items
            /// they must be unique keys or values found in the dropdown item list of 'Affected Door Groups'
            "value": ["Main Doors", "Side Doors"]
          },
          "Door Mode": {"value": "Locked"}
        },

        /// the item widget to display in the dropdown
        "child": {
          "type": "Text",
          "data": "Weekend, No Access",
        },
      },
      {
        "key": "Side door access for open house",
        "value": "68237302f335be50f3ad0918",
        "description": "Access to side doors for open house events.",
        "actions": {
          "One Time Event": {
            "value": "checked", // set value for this choice
            "readonly": true // whether this field can be interacted with
          },
          "One Off Date": {
            "value": "2025-01-01T00:00:00Z" // one-off date for this event
          },
          "Door Mode Duration": {"value": "4h"},
          "Affected Door Groups": {
            "visible": false,
            "value": ["Side Doors"]
          },
          "Duration": {
            "visible": true, // show duration field for this event
            "value": "1d1h",
          },
          "Door Mode": {"value": "Unlocked"}
        },
        "child": {
          "type": "Text",
          "data": "Side door access for open house",
        },
      }
    ]
  },
  {
    "type": "Padding",
    "padding": {"left": 10, "top": 10.0, "right": 20, "bottom": 10.0},
    "child": {
      "type": "CheckboxWidget",
      "label": "One Time Event",
      "initialValue": "unchecked",
      "checked": {
        "actions": {
          // equivalent to "sets" when checkbox is checked/true
          "Schedule": {
            "visible": false // hide schedule field if this is a one-time event
          },
          "One Off Date": {
            "visible":
                true // show one-off dates field if this is a one-time event
          }
        }
      },
      "unchecked": {
        // equivalent to "sets" when checkbox is unchecked/false
        "Schedule": {
          "visible": true // show schedule field if this is not a one-time event
        },
        "One Off Date": {
          "visible":
              false // hide one-off dates field if this is not a one-time event
        }
      }
    }
  },
  {
    "type": "Padding",
    "padding": {"left": 0.0, "top": 10.0, "right": 0.0, "bottom": 10.0},
    "child": {
      "type": "CronSchedulePickerWidget",
      "label": "Schedule",
      "hint": "Select the schedule for this door mode.",
      "isOptional": false
    }
  },
  // {
  //   "type": "Padding",
  //   "padding": {"left": 0.0, "top": 10.0, "right": 0.0, "bottom": 10.0},
  //   "child": {
  //     "type": "DateTimePickerWidget",
  //     "label": "One Off Date",
  //     "initialDate": "2025-01-01T00:00:00Z",
  //     "isOptional": false
  //   }
  // },
  {
    "type": "Padding",
    "padding": {"left": 0.0, "top": 10.0, "right": 0.0, "bottom": 10.0},
    "child": {
      "type": "TimeDurationPickerWidget",
      "label": "Duration",
      "hint": "Select the duration for this door mode to be active.",
      "isOptional": false
    }
  },
  {
    "type": "MultiSelectDropdownWidget",
    "label": "Affected Door Groups",
    "hint": "Select the affected door groups.",
    "isRequired": true,
    "isMultiSelect": true, // allow multiple selections
    "items": [
      {
        "key": "Main Doors",
        "value": "68238b0830686665579732a1",
        "selected": true, // preselected
        "child": {"type": "Text", "data": "Main Doors"}
      },
      {
        "key": "Side Doors",
        "value": "68237302f335be50f3ad0918",
        "child": {"type": "Text", "data": "Side Doors"}
      }
    ]
  },
  {
    "type": "DropdownButtonFormField",
    "label": "Door Mode",
    "hint": "Select the door mode to be set.",
    "isRequired": true,
    "items": [
      {
        "key": "Normal",
        "value": 0,
        "child": {"type": "Text", "data": "Normal"}
      },
      {
        "key": "Locked",
        "value": 1,
        "child": {"type": "Text", "data": "Locked"}
      },
      {
        "key": "Unlocked",
        "value": 2,
        "child": {"type": "Text", "data": "Unlocked"}
      }
    ]
  }
];
