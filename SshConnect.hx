package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("Optional name for the connection. If not provided the text of the state will be use as alias (if any).")
	var alias:String;
	@:editable("SSH executable path.", "putty -ssh")
	var executable_path:String;
	@:editable("Port-forwarding type", '', ['', "local", "remote", "dynamic"])
	var port_forward_type:String;
	@:editable("Local port")
	var local_port:UInt;
	@:editable("Remote host name or IP (with port) which will be forwarded to through the ssh_server (if port_forward_type is not empty)")
	var remote_host:String;
	@:editable("The SSH server (with port)")
	var ssh_server:String;
	@:editable("SSH user")
	var ssh_user:String;
	@:editable("SSH password")
	var ssh_password:String;
	var color:{connected:String, disconnected:String};
}

@:name('ssh-connect')
@:description('Connect to SSH in a simple and fast way.')
class SshConnect extends IdeckiaAction {
	var port_forward_type:String;

	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.alias == null)
				props.alias = initialState.text;

			if (props.port_forward_type != '')
				port_forward_type = props.port_forward_type.charAt(0).toUpperCase();

			if (props.color == null) {
				var colorData = getColorData('colors.json');
				if (colorData != null)
					props.color = colorData;
				else
					props.color = Macros.getColorData('colors.json');
			}

			initialState.bgColor = props.color.disconnected;
			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
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
				executingProcess.on('error', (error) -> {
					var msg = 'Error connecting to ssh: $error';
					server.dialog.error('SSH error', msg);
					reject(msg);
				});

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
		var cmd = props.executable_path;
		cmd += ' ';
		if (port_forward_type != null) {
			cmd += '-${port_forward_type}';
			cmd += ' ${props.local_port}:';
			cmd += props.remote_host;
			cmd += ' ';
		}
		if (props.ssh_user != null)
			cmd += '${props.ssh_user}@';
		cmd += props.ssh_server;
		if (props.ssh_password != null)
			cmd += ' -pw ${props.ssh_password}';
		if (props.alias != null)
			cmd += ' -loghost "${props.alias}"';

		return cmd;
	}

	function killProcess(pid:Int, signal:String = 'SIGKILL') {
		if (Sys.systemName() == "Windows") {
			ChildProcess.exec('taskkill /PID ${pid} /T /F', (error, _, _) -> {
				if (error != null) {
					server.dialog.error('SSH error', 'Error killing process: $error');
				}
			});
		} else {
			// see https://nodejs.org/api/child_process.html#child_process_options_detached
			// If pid is less than -1, then sig is sent to every process in the process group whose ID is -pid.
			js.Node.process.kill(-pid, 'SIGKILL');
		}
	}

	public static function getColorData(name:String) {
		var filePath:String = haxe.io.Path.join([js.Node.__dirname, name]);

		if (!sys.FileSystem.exists(filePath))
			return null;
		return haxe.Json.parse(sys.io.File.getContent(filePath));
	}
}
