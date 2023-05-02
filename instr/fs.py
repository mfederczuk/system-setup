# SPDX-License-Identifier: CC0-1.0

# wrapper module around filesystem-related operations

import os
import shutil

from instr.pathname import Pathname


def exists(pathname: Pathname) -> bool:
    return os.path.exists(str(pathname))


def is_directory(pathname: Pathname) -> bool:
    return os.path.isdir(str(pathname))


def mkdirs(pathname: Pathname) -> None:
    os.makedirs(str(pathname), exist_ok=True)


def copy(source: Pathname, target: Pathname) -> None:
    shutil.copy(str(source), str(target))


def remove(pathname: Pathname) -> None:
    os.remove(str(pathname))
