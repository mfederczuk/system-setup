from abc import ABC, abstractmethod
from collections.abc import Mapping
from os import PathLike


class TaskContext(ABC):

	@abstractmethod
	def copy_file_to_bin(self, file_path: str | PathLike[str], /, *, name: str | None = None) -> None:
		raise NotImplementedError()

	@abstractmethod
	def copy_files_to_bin(self, files: Mapping[str | PathLike[str], str], /) -> None:
		raise NotImplementedError()

	@abstractmethod
	def exec(self, /, *args: str) -> None:
		raise NotImplementedError()
