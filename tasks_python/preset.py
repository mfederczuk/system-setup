from dataclasses import dataclass
from typing import final

from . import Input


@final
@dataclass(frozen=True)
class Preset:
	name: str
	input: Input
