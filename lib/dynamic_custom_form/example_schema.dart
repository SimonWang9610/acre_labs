final oldSchema = [
  {
    "type": "DropdownButtonFormFieldWidget",
    "label": "Door Template",
    "isMultiSelect": false,
    "hint": "Select a Door Template",
    "items": [
      {
        "key": "No access on holidays",
        "value": "68238b0830686665579732a1",
        "child": {"type": "Text", "data": "No access on holidays"}
      },
      {
        "key": "Side door access for open house",
        "value": "68238b0830686665579732a2",
        "child": {"type": "Text", "data": "Side door access for open house"}
      }
    ],
    "initialValue": {
      "key": "No access on holidays",
      "value": "68238b0830686665579732a1"
    },
    "@actions": {
      "No access on holidays": {
        "One Time Event": {
          "@state": {"readonly": true},
          "@data": false,
        },
        "Schedule": {"@data": "0 0 * * 6"},
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
            {"key": "Main Doors", "value": "68238b0830686665579732a1"},
            {"key": "Side Doors", "value": "68238b0830686665579732a2"}
          ]
        },
        "Door Mode": {
          "@data": {"key": "Locked", "value": 1}
        }
      },
      "Side door access for open house": {
        "One Time Event": {
          "@state": {"readonly": true},
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
            {"key": "Side Doors", "value": "68238b0830686665579732a2"}
          ]
        },
        "Door Mode": {
          "@data": {"key": "Unlocked", "value": 2}
        }
      }
    }
  },
  {
    "type": "Padding",
    "padding": {"left": 10, "top": 10.0, "right": 20, "bottom": 10.0},
    "child": {
      "type": "CheckboxWidget",
      "label": "One Time Event",
      "initialValue": false,
      "@actions": {
        "true": {
          "Schedule": {
            "@state": {"visible": false}
          },
        },
        "false": {
          "Schedule": {
            "@state": {"visible": true}
          },
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
    "type": "DropdownButtonFormFieldWidget",
    "label": "Affected Door Groups",
    "hint": "Select the affected door groups.",
    "isRequired": true,
    "isMultiSelect": true, // allow multiple selections
    "items": [
      {
        "key": "Main Doors",
        "value": "68238b0830686665579732a1",
        "child": {"type": "Text", "data": "Main Doors"}
      },
      {
        "key": "Side Doors",
        "value": "68238b0830686665579732a2",
        "child": {"type": "Text", "data": "Side Doors"}
      }
    ]
  },
  {
    "type": "DropdownButtonFormFieldWidget",
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
