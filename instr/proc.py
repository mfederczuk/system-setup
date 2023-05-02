# SPDX-License-Identifier: CC0-1.0

# there just is no rhyme or reason if something is in `os` or `sys`, so this is a wrapper module around the
# process-related things

import os
import sys
from typing import MutableMapping, NoReturn, TextIO

from instr.pathname import Pathname


stderr: TextIO = sys.stderr

environ: MutableMapping[str, str] = os.environ

argv: list[str] = sys.argv


def getcwd() -> Pathname:
    return Pathname(os.getcwd())


# pylint: disable=redefined-builtin
def exit(status: int) -> NoReturn:
    sys.exit(status)
# pylint: enable=redefined-builtin
