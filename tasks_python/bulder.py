from __future__ import annotations

from collections.abc import Sequence
from typing import Self, TypeVar

from . import Task
from .actions import ExecAction, TaskAction
from .actions.apt import AptPackagesInstallingAction
from .actions.dnf import DnfCoprRepositoriesEnablingAction, DnfPackagesInstallingAction
from .actions.termux_pkg import TermuxPkgPackagesInstallingAction


# region dnf


class DnfCopr:

	# noinspection PyMethodMayBeStatic
	def enable(self, /, *repositories: str) -> DnfCoprRepositoriesEnablingAction:
		return DnfCoprRepositoriesEnablingAction(repositories)


class Dnf:

	@property
	def copr(self) -> DnfCopr:
		return DnfCopr()

	# noinspection PyMethodMayBeStatic
	def install(self, /, *packages: str) -> DnfPackagesInstallingAction:
		return DnfPackagesInstallingAction(packages)


# endregion


class TermuxPkg:

	# noinspection PyMethodMayBeStatic
	def install(self, /, *packages: str) -> TermuxPkgPackagesInstallingAction:
		return TermuxPkgPackagesInstallingAction(packages)


A = TypeVar("A", bound=TaskAction)

class TaskBuilder:
	_actions: Sequence[A] = ()

	def add_action(self, action: A) -> None:
		self._actions = (*self._actions, action)

	@property
	def apt(self) -> Apt:
		return Apt(builder=self)

	dnf: Dnf = Dnf()
	pkg: TermuxPkg = TermuxPkg()

	def exec(self, *args: str) -> Self:
		self.add_action(ExecAction(args))
		return self

	def build(self) -> Task:
		pass


class Apt:

	_builder: TaskBuilder

	def __init__(self, builder: TaskBuilder):
		self._builder = builder

	# noinspection PyMethodMayBeStatic
	def install(self, /, *packages: str) -> TaskBuilder:
		self._builder.add_action(AptPackagesInstallingAction(packages))
		return self._builder
