from abc import ABC, abstractmethod

from . import TaskContext


class DnfCopr(ABC):

	@abstractmethod
	def enable(self, /, *coprs: str):
		raise NotImplementedError()


class Dnf(ABC):

	@abstractmethod
	@property
	def copr(self) -> DnfCopr:
		raise NotImplementedError()

	@abstractmethod
	def install(self, /, *packages: str) -> None:
		raise NotImplementedError()


class Fedora41TaskContext(TaskContext, ABC):

	@abstractmethod
	@property
	def dnf(self) -> Dnf:
		raise NotImplementedError()
