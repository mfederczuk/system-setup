from .apt import AptPackagesInstallingAction
from .dnf import DnfCoprRepositoriesEnablingAction, DnfPackagesInstallingAction
from .exec import ExecAction
from .termux_pkg import TermuxPkgPackagesInstallingAction

DistroAgnosticAction = ExecAction

AndroidTermuxTaskAction = DistroAgnosticAction | TermuxPkgPackagesInstallingAction
Fedora41TaskAction = DistroAgnosticAction | DnfCoprRepositoriesEnablingAction | DnfPackagesInstallingAction
Ubuntu2204TaskAction = DistroAgnosticAction | AptPackagesInstallingAction

TaskAction = AndroidTermuxTaskAction | Fedora41TaskAction | Ubuntu2204TaskAction
