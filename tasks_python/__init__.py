from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import final

from .actions import AndroidTermuxTaskAction, Fedora41TaskAction, TaskAction, Ubuntu2204TaskAction


@final
@dataclass
class Input:
	xdg_config_home: str


@final
@dataclass(frozen=True)
class AndroidTermuxTask:
	name: str
	actions: Sequence[AndroidTermuxTaskAction]


@final
@dataclass(frozen=True)
class Fedora41Task:
	name: str
	actions: Sequence[Fedora41TaskAction]


@final
@dataclass(frozen=True)
class Ubuntu2204Task:
	name: str
	actions: Sequence[Ubuntu2204TaskAction]


Task = AndroidTermuxTask | Fedora41Task | Ubuntu2204Task
