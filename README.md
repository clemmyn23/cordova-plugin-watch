# Cordova Watch Plugin

##Description
Currently a WIP both in code and documentation

##Usage

Sends a dictionary of values that a paired device can use to synchronize its state.

Use this method to communicate recent state information to the counterpart. When the counterpart wakes, it can use this information to update its own state. Sending a new dictionary with this method overwrites the previous dictionary.

Example:
```
context =
  info: "Something"
  date: new Date
window.watch.updateApplicationContext context, success, error
```

Sends a message immediately to the paired device and optionally handles a response.

Use this method to transfer data to a reachable counterpart. These methods are intended for immediate communication between your iOS app and WatchKit extension.

Example:
```
message =
  info: "Something"
  date: new Date
window.watch.sendMessage message, success, error
```
