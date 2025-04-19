from collections.abc import Sequence
from dataclasses import dataclass
from typing import final


@final
@dataclass(frozen=True)
class ExecAction:
	arguments: Sequence[str]
