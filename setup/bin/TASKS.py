from tasks import Task, TaskContext, Fedora41TaskContext


def _install(context: TaskContext) -> None:
	if isinstance(context, Fedora41TaskContext):
		context.dnf_install("")
	context.copy_file_to_bin("alert.bash", name="alert")
	pass


install: Task = Task.register("install", _install)
