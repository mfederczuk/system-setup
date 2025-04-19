from __future__ import annotations

from .abc import TaskActionsBuilder
from ..actions import Ubuntu2204TaskAction
from ..actions.apt import AptPackagesInstallingAction


class UbuntuTaskActionsBuilder(TaskActionsBuilder[Ubuntu2204TaskAction]):

	@property
	def apt(self) -> Apt:
		return Apt(builder=self)


class Apt:
	_builder: UbuntuTaskActionsBuilder

	def __init__(self, builder: UbuntuTaskActionsBuilder):
		self._builder = builder

	def install(self, /, *packages: str) -> UbuntuTaskActionsBuilder:
		self._builder.add_action(AptPackagesInstallingAction(packages))
		return self._builder
