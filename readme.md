# Action for ideckia: SshConnect

## Definition

Create connections via ssh (it is using PuTTY atm)

### Custom name in connection window (putty exclusive)

* Open putty
  * Session
    * 'Saved Sessions' -> 'Default Settings' -> Load
  * Terminal
    * Features
      * Check 'Disable remote-controlled window title changing'
  * Session
    * 'Saved Sessions' -> 'Default Settings' -> Save
      

## Properties

| Name | Type | Default | Description | Possible values |
| ----- |----- | ----- | ----- | ----- |
| alias | String | null | Optional name for the connection. If not provided the text of the state will be use as alias (if any). | null |
| execPath | String | null | Custom SSH executable path. If omitted, will look for 'putty' in PATH environment variable. | null |
| portForwardType | String | null | Port-forwarding type | [local,remote,dynamic] |
| localPort | UInt | null | Local port | null |
| remoteHost | String | null | Remote host name or IP (with port) which will be forwarded to through the sshServer (if portForwardType is not null) | null |
| sshServer | String | null | The SSH server (with port) | null |
| sshUser | String | null | SSH user | null |
| sshPassword | String | null | SSH password | null |
| color | { disconnected : String, connected : String } | { connected : 'ff00aa00', disconnected : 'ffaa0000' } | Color definitions | null |


## Example in layout file

```json
{
    "state": {
        "text": "Port-forwarding example",
        "bgColor": "00ff00",
        "actions": [{
            "name": "ssh-connect",
            "props": {
                "alias": "my tunnel",
                "execPath": "/alt/path/to/ssh",
                "portForwardType": "local",
                "localPort": 4433,
                "remoteHost": "remote.host:443",
                "sshServer": "my.ssh.host",
                "sshUser": "user",
                "sshPassword": "securePass"
            }
        }]
    }
}
```