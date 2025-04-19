from abc import ABC, abstractmethod

from . import TaskContext


class TermuxPkg(ABC):

	@abstractmethod
	def install(self, /, *packages: str) -> None:
		raise NotImplementedError()


class AndroidTermuxTaskContext(TaskContext, ABC):

	@abstractmethod
	@property
	def pkg(self) -> TermuxPkg:
		raise NotImplementedError()
