package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("Optional name for the connection. If not provided the text of the state will be use as alias (if any).")
	var alias:String;
	@:editable("Custom SSH executable path. If omitted, will look for 'putty' in PATH environment variable.")
	var execPath:String;
	@:editable("Port-forwarding type", null, ["local", "remote", "dynamic"])
	var portForwardType:String;
	@:editable("Local port")
	var localPort:UInt;
	@:editable("Remote host name or IP (with port) which will be forwarded to through the sshServer (if portForwardType is not null)")
	var remoteHost:String;
	@:editable("The SSH server (with port)")
	var sshServer:String;
	@:editable("SSH user")
	var sshUser:String;
	@:editable("SSH password")
	var sshPassword:String;
	@:editable("Color definitions", {connected: 'ff00aa00', disconnected: 'ffaa0000'})
	var color:{connected:String, disconnected:String};
}

@:name('ssh-connect')
@:description('Connect to SSH in a simple and fast way.')
class SshConnect extends IdeckiaAction {
	var execPath:String;

	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.execPath == null) {
				var envPath = Sys.getEnv('PATH').toLowerCase();

				if (envPath.indexOf('putty') == -1) {
					var msg = 'Could not find PuTTY (default) in the PATH enviroment variable. Configure your ssh executable with execPath property.';
					server.dialog.error(msg);
					reject(msg);
				}

				execPath = 'putty -ssh';
			} else {
				execPath = props.execPath;
			}

			if (props.alias == null)
				props.alias = initialState.text;

			if (props.portForwardType != null)
				props.portForwardType = props.portForwardType.charAt(0).toUpperCase();

			initialState.bgColor = props.color.disconnected;
			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (execPath == null)
				reject('No SSH command found. Define it in the action properties (execPath).');

			var options:ChildProcessSpawnOptions = {
				shell: true,
				detached: true,
				stdio: Ignore
			}

			if (executingProcess == null) {
				var cmd = buildCommand();
				server.log.debug('Connecting with ssh command: [${cmd}]');
				executingProcess = ChildProcess.spawn(cmd, options);
				executingProcess.unref();
				executingProcess.on('close', () -> {
					currentState.bgColor = props.color.disconnected;
					executingProcess = null;
					server.updateClientState(currentState);
				});
				executingProcess.on('error', reject);

				currentState.bgColor = props.color.connected;
			} else {
				server.log.debug('Disconnecting [${props.alias}]');
				killProcess(executingProcess.pid);
				currentState.bgColor = props.color.disconnected;
			}

			resolve(currentState);
		});
	}

	function buildCommand() {
		var cmd = execPath;
		cmd += ' ';
		if (props.portForwardType != null) {
			cmd += '-${props.portForwardType}';
			cmd += ' ${props.localPort}:';
			cmd += props.remoteHost;
			cmd += ' ';
		}
		if (props.sshUser != null)
			cmd += '${props.sshUser}@';
		cmd += props.sshServer;
		if (props.sshPassword != null)
			cmd += ' -pw ${props.sshPassword}';
		if (props.alias != null)
			cmd += ' -loghost "${props.alias}"';

		return cmd;
	}

	function killProcess(pid:Int, signal:String = 'SIGKILL') {
		if (Sys.systemName() == "Windows") {
			ChildProcess.exec('taskkill /PID ${pid} /T /F', (error, _, _) -> {
				if (error != null) {
					server.dialog.error('Error killing process: $error');
				}
			});
		} else {
			// see https://nodejs.org/api/child_process.html#child_process_options_detached
			// If pid is less than -1, then sig is sent to every process in the process group whose ID is -pid.
			js.Node.process.kill(-pid, 'SIGKILL');
		}
	}
}
