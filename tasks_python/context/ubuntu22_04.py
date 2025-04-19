from abc import ABC, abstractmethod

from . import TaskContext


class Apt(ABC):

	@abstractmethod
	def install(self, /, *packages: str) -> None:
		raise NotImplementedError()


class Ubuntu2204TaskContext(TaskContext, ABC):

	@abstractmethod
	@property
	def apt(self) -> Apt:
		raise NotImplementedError()
