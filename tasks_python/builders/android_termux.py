from __future__ import annotations

from .abc import TaskActionsBuilder
from ..actions import AndroidTermuxTaskAction
from ..actions.termux_pkg import TermuxPkgPackagesInstallingAction


class AndroidTermuxTaskActionsBuilder(TaskActionsBuilder[AndroidTermuxTaskAction]):

	@property
	def pkg(self) -> TermuxPkg:
		return TermuxPkg(builder=self)


class TermuxPkg:
	_builder: AndroidTermuxTaskActionsBuilder

	def __init__(self, builder: AndroidTermuxTaskActionsBuilder):
		self._builder = builder

	def install(self, /, *packages: str) -> AndroidTermuxTaskActionsBuilder:
		self._builder.add_action(TermuxPkgPackagesInstallingAction(packages))
		return self._builder
