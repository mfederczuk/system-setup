from abc import ABC
from collections.abc import Sequence
from typing import Self

from ..actions import TaskAction
from ..actions.exec import ExecAction


class TaskActionsBuilder[A: TaskAction](ABC):
	_actions: list[A] = []

	@property
	def actions(self) -> Sequence[A]:
		return (*self._actions,)

	def add_action(self, action: A) -> None:
		self._actions.append(action)

	def exec(self, *args: str) -> Self:
		self.add_action(ExecAction(args))
		return self
