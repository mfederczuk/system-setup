from __future__ import annotations

from .abc import TaskActionsBuilder
from ..actions import Fedora41TaskAction
from ..actions.dnf import DnfCoprRepositoriesEnablingAction, DnfPackagesInstallingAction


class Fedora41TaskActionsBuilder(TaskActionsBuilder[Fedora41TaskAction]):

	@property
	def dnf(self) -> Dnf:
		return Dnf(builder=self)


class Dnf:
	_builder: Fedora41TaskActionsBuilder

	def __init__(self, builder: Fedora41TaskActionsBuilder):
		self._builder = builder

	@property
	def copr(self) -> DnfCopr:
		return DnfCopr(builder=self._builder)

	def install(self, /, *packages: str) -> Fedora41TaskActionsBuilder:
		self._builder.add_action(DnfPackagesInstallingAction(packages))
		return self._builder


class DnfCopr:
	_builder: Fedora41TaskActionsBuilder

	def __init__(self, builder: Fedora41TaskActionsBuilder):
		self._builder = builder

	def enable(self, /, *repositories: str) -> Fedora41TaskActionsBuilder:
		self._builder.add_action(DnfCoprRepositoriesEnablingAction(repositories))
		return self._builder
