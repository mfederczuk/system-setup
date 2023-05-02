# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

import errno
import os
import re
from dataclasses import dataclass
from typing import Any


def require_arg_of_type(arg_name: str, actual_value: Any, expected_type: type):
    if not isinstance(arg_name, str):  # type: ignore
        raise TypeError(f"Argument 'arg_name' must be of type {str.__name__}")

    if not isinstance(expected_type, type):
        raise TypeError(f"Argument 'expected_type' must be of type {type.__name__}")

    if isinstance(actual_value, expected_type):
        return

    raise TypeError(f"Argument '{arg_name}' must be of type {expected_type.__name__}")


def require_arg_of_list_type(arg_name: str, actual_value: Any, expected_item_type: type):
    require_arg_of_type("expected_item_type", expected_item_type, type)

    require_arg_of_type(arg_name, actual_value, list)

    for (i, item) in enumerate(actual_value):
        if isinstance(item, expected_item_type):
            continue

        msg: str = (f"Item at index {i} of {list.__name__} argument '{arg_name}'" +
                    f"must be of type {expected_item_type.__name__}")
        raise ValueError(msg)


@dataclass(frozen=True)
class Pathname:

    value: str

    def __post_init__(self):
        require_arg_of_type("value", self.value, str)

        if self.value == "":
            raise ValueError("Empty pathnames are invalid")

    @staticmethod
    def create_normalized(value: str) -> "Pathname":
        return Pathname(value).normalized()

    def normalized(self) -> "Pathname":
        # note: not using `os.path.normpath()` because it also removes '..' components, which is wrong; it changes the
        #       behavior of the path resolution

        normalied_value: str = self.value

        while "/./" in normalied_value:
            normalied_value = normalied_value.replace("/./", "/")

        while "//" in normalied_value:
            normalied_value = normalied_value.replace("//", "/")

        if normalied_value.startswith("./") and len(self.value) > 2:
            normalied_value = normalied_value.removeprefix("./")

        if normalied_value.endswith("/."):
            normalied_value = normalied_value.removesuffix(".")

        return Pathname(normalied_value)

    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class File:

    pathname: Pathname

    def __post_init__(self):
        require_arg_of_type("pathname", self.pathname, Pathname)

    def with_pathname(self, new_pathname: Pathname) -> "File":
        require_arg_of_type("new_pathname", new_pathname, Pathname)

        return File(new_pathname)


@dataclass
class FileCopyInstruction:

    source: File
    target: File

    def __init__(self, source: File, target: File):
        require_arg_of_type("source", source, File)
        require_arg_of_type("target", target, File)

        self.source = source
        self.target = target


@dataclass
class InstructionGroup:

    name: str
    file_copy_instructions: list[FileCopyInstruction]

    def __init__(self, name: str, file_copy_instructions: list[FileCopyInstruction]):
        require_arg_of_type("name", name, str)
        require_arg_of_list_type("file_copy_instructions", file_copy_instructions, FileCopyInstruction)

        self.name = name
        self.file_copy_instructions = file_copy_instructions.copy()


class InstructionsReadError(Exception):

    pathname: str
    lineno: int
    msg: str

    def __init__(self, pathname: str, lineno: int, msg: str):
        require_arg_of_type("pathname", pathname, str)
        require_arg_of_type("lineno", lineno, int)
        require_arg_of_type("msg", msg, str)

        super().__init__(pathname, lineno, msg)

        self.pathname = pathname
        self.lineno = lineno
        self.msg = msg


def read_instructions(source_dir_pathname: str, home: str, xdg_config_home: str) -> list[InstructionGroup]:
    require_arg_of_type("source_dir_pathname", source_dir_pathname, str)
    require_arg_of_type("home", home, str)
    require_arg_of_type("xdg_config_home", xdg_config_home, str)

    file_pathname: str = os.path.join(source_dir_pathname, "Instructions.cfg")

    if not os.path.exists(file_pathname):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), file_pathname)

    if os.path.isdir(file_pathname):
        raise IsADirectoryError(errno.EISDIR, os.strerror(errno.EISDIR), file_pathname)

    instructions: list[InstructionGroup] = []

    with open(file_pathname, "r", encoding="utf8") as file_io_wrapper:
        lineno: int = 0

        current_instruction_group: InstructionGroup | None = None

        for line in file_io_wrapper:
            lineno += 1

            line = line.strip()

            if line == "" or line.startswith("#"):
                continue

            match: re.Match[str] | None = None

            if current_instruction_group is not None:
                match = re.match(r"^\}(\s*#.*)?$", line)
                if match is not None:
                    instructions.append(current_instruction_group)
                    current_instruction_group = None
                    continue

                match = re.match(
                    r"^Copy\s+File\s*\"(?P<source_pathname>[^\"]+)\"\s*To\s+File\s*\"(?P<target_pathname>[^\"]+)\"(\s*#.*)?$",
                    line,
                )
                if match is not None:
                    source_pathname: Pathname = Pathname.create_normalized(match.group("source_pathname"))

                    target_pathname_str: str = match.group("target_pathname")
                    if target_pathname_str.startswith("$HOME"):
                        target_pathname_str = target_pathname_str.removeprefix("$HOME")

                        target_pathname_str = os.path.join(
                            home,
                            os.path.relpath(target_pathname_str, os.path.abspath(os.sep)),
                        )
                    elif target_pathname_str.startswith("$XDG_CONFIG_HOME"):
                        target_pathname_str = target_pathname_str.removeprefix("$XDG_CONFIG_HOME")

                        target_pathname_str = os.path.join(
                            xdg_config_home,
                            os.path.relpath(target_pathname_str, os.path.abspath(os.sep)),
                        )

                    target_pathname: Pathname = Pathname.create_normalized(target_pathname_str)

                    file_copy_instruction = FileCopyInstruction(
                        source=File(source_pathname),
                        target=File(target_pathname),
                    )

                    current_instruction_group.file_copy_instructions.append(file_copy_instruction)
                    continue

                raise InstructionsReadError(file_pathname, lineno, "Invalid line in instruction definition")

            match = re.match(r"^Include\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
            if match is not None:
                source_dir_pathname_to_include: str = os.path.join(source_dir_pathname, match.group("pathname"))

                included_instructions: list[InstructionGroup] = read_instructions(
                    source_dir_pathname_to_include,
                    home,
                    xdg_config_home,
                )
                for instruction in included_instructions:
                    for (i, file_copy_instruction) in enumerate(instruction.file_copy_instructions):
                        instruction.file_copy_instructions[i] = FileCopyInstruction(
                            source=File(
                                Pathname.create_normalized(
                                    os.path.join(
                                        os.path.basename(source_dir_pathname_to_include),
                                        file_copy_instruction.source.pathname.value,
                                    )
                                )
                            ),
                            target=file_copy_instruction.target,
                        )

                instructions.extend(included_instructions)

                continue

            match = re.match(r"^Group\s*\"(?P<name>[^\"]+)\"\s*\{(\s*#.*)?$", line)
            if match is not None:
                name: str = match.group("name")
                current_instruction_group = InstructionGroup(name, [])
                continue

            raise InstructionsReadError(file_pathname, lineno, "Invalid top-level line")

    return instructions
