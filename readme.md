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
| executable_path | String | SSH executable path. | false | "putty -ssh" | null |
| port_forward_type | String | '' | Port-forwarding type | ['', 'local', 'remote', 'dynamic'] |
| local_port | UInt | null | Local port | null |
| remote_host | String | null | Remote host name or IP (with port) which will be forwarded to through the ssh_server (if port_forward_type is not empty) | null |
| ssh_server | String | null | The SSH server (with port) | null |
| ssh_user | String | null | SSH user | null |
| ssh_password | String | null | SSH password | null |
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
                "executable_path": "/alt/path/to/ssh",
                "port_forward_type": "local",
                "local_port": 4433,
                "remote_host": "remote.host:443",
                "ssh_server": "my.ssh.host",
                "ssh_user": "user",
                "ssh_password": "securePass"
            }
        }]
    }
}
```