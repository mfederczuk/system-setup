from collections.abc import Sequence
from dataclasses import dataclass
from typing import final


@final
@dataclass(frozen=True)
class TermuxPkgPackagesInstallingAction:
	packages: Sequence[str]

	def __post_init__(self):
		if len(self.packages) == 0:
			raise ValueError("At least one package must be specified")

