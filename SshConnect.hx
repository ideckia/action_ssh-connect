package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("prop_alias")
	var alias:String;
	@:editable("prop_executable_path", "putty -ssh")
	var executable_path:String;
	@:editable("prop_port_forward_type", '', ['', "local", "remote", "dynamic"])
	var port_forward_type:String;
	@:editable("prop_local_port")
	var local_port:UInt;
	@:editable("prop_remote_host")
	var remote_host:String;
	@:editable("prop_ssh_server")
	var ssh_server:String;
	@:editable("prop_ssh_user")
	var ssh_user:String;
	@:editable("prop_ssh_password")
	var ssh_password:String;
	var color:{connected:String, disconnected:String};
}

@:name('ssh-connect')
@:description('action_description')
@:localize
class SshConnect extends IdeckiaAction {
	static var DEFAULT_COLORS:{
		connected:String,
		disconnected:String
	} = Data.embedJson('colors.json');

	var port_forward_type:String;

	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.alias == null)
				props.alias = initialState.text;

			if (props.port_forward_type != '')
				port_forward_type = props.port_forward_type.charAt(0).toUpperCase();

			if (props.color == null) {
				var colorData = core.data.getJson('colors.json');
				if (colorData != null)
					props.color = colorData;
				else
					props.color = DEFAULT_COLORS;
			}

			initialState.bgColor = props.color.disconnected;
			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		return new js.lib.Promise((resolve, reject) -> {
			var options:ChildProcessSpawnOptions = {
				shell: true,
				detached: true,
				stdio: Ignore
			}

			if (executingProcess == null) {
				var cmd = buildCommand();
				core.log.debug('Connecting with ssh command: [${cmd}]');
				executingProcess = ChildProcess.spawn(cmd, options);
				executingProcess.unref();
				executingProcess.on('close', () -> {
					currentState.bgColor = props.color.disconnected;
					executingProcess = null;
					core.updateClientState(currentState);
				});
				executingProcess.on('error', (error) -> {
					var msg = 'Error connecting to ssh: $error';
					core.dialog.error('SSH error', msg);
					reject(msg);
				});

				currentState.bgColor = props.color.connected;
			} else {
				core.log.debug('Disconnecting [${props.alias}]');
				killProcess(executingProcess.pid);
				currentState.bgColor = props.color.disconnected;
			}

			resolve(new ActionOutcome({state: currentState}));
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
					core.dialog.error('SSH error', 'Error killing process: $error');
				}
			});
		} else {
			// see https://nodejs.org/api/child_process.html#child_process_options_detached
			// If pid is less than -1, then sig is sent to every process in the process group whose ID is -pid.
			js.Node.process.kill(-pid, 'SIGKILL');
		}
	}
}
