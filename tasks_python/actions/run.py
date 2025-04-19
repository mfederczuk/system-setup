from dataclasses import dataclass
from typing import final

from .. import Task


@final
@dataclass(frozen=True)
class TaskRunAction:
	task: Task
