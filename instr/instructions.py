# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from __future__ import annotations

import errno
import os
import re
from dataclasses import dataclass
from typing import NoReturn

import fs
from pathname import Pathname, PathnamePrefixMatch, PathnameComponent


@dataclass(frozen=True)
class File:

    pathname: Pathname


@dataclass(frozen=True)
class FileCopyInstruction:

    source: File
    target: File

    def with_source(self: FileCopyInstruction, new_source: File) -> FileCopyInstruction:
        return FileCopyInstruction(
            source=new_source,
            target=self.target,
        )

    def with_target(self: FileCopyInstruction, new_target: File) -> FileCopyInstruction:
        return FileCopyInstruction(
            source=self.source,
            target=new_target,
        )


@dataclass(frozen=True)
class InstructionGroup:

    name: str
    file_copy_instructions: list[FileCopyInstruction]

    def __post_init__(self: InstructionGroup) -> None:
        if self.name == "":
            raise ValueError("Instruction group name must not be empty")

    def with_file_copy_instructions(
        self: InstructionGroup,
        new_file_copy_instructions: list[FileCopyInstruction],
    ) -> InstructionGroup:
        return InstructionGroup(
            name=self.name,
            file_copy_instructions=new_file_copy_instructions.copy(),
        )


class InstructionsReadError(Exception):

    pathname: Pathname
    lineno: int
    msg: str

    def __init__(self: InstructionsReadError, pathname: Pathname, lineno: int, msg: str) -> None:
        super().__init__(str(pathname), lineno, msg)

        self.pathname = pathname
        self.lineno = lineno
        self.msg = msg


_INSTRUCTIONS_FILE_PATHNAME_COMPONENT: PathnameComponent = PathnameComponent("Instructions.cfg")

_HOME_VAR_PREFIX_PATHNAME: Pathname = Pathname("$HOME")
_XDG_CONFIG_HOME_VAR_PREFIX_PATHNAME: Pathname = Pathname("$XDG_CONFIG_HOME")


def read_instructions(
    source_dir_pathname: Pathname,
    home_pathname: Pathname,
    xdg_config_home_pathname: Pathname,
) -> list[InstructionGroup] | NoReturn:
    instructions_file_pathname: Pathname = source_dir_pathname.appended_with(_INSTRUCTIONS_FILE_PATHNAME_COMPONENT)

    if not fs.exists(instructions_file_pathname):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), str(instructions_file_pathname))

    if fs.is_directory(instructions_file_pathname):
        raise IsADirectoryError(errno.EISDIR, os.strerror(errno.EISDIR), str(instructions_file_pathname))

    instruction_groups: list[InstructionGroup] = []

    with open(str(instructions_file_pathname), "r", encoding="utf8") as instructions_file:
        lineno: int = 0

        current_instruction_group: InstructionGroup | None = None

        for line in instructions_file:
            lineno += 1

            line = line.strip()

            if line == "" or line.startswith("#"):
                continue

            line_match: re.Match[str] | None = None

            if current_instruction_group is not None:
                line_match = re.match(r"^\}(\s*#.*)?$", line)
                if line_match is not None:
                    instruction_groups.append(current_instruction_group)
                    current_instruction_group = None
                    continue

                line_match = re.match(
                    r"^Copy\s+File\s*\"(?P<source_pathname>[^\"]+)\"\s*To\s+File\s*\"(?P<target_pathname>[^\"]+)\"(\s*#.*)?$",
                    line,
                )
                if line_match is not None:
                    source_pathname: Pathname = Pathname.create_normalized(line_match.group("source_pathname"))
                    target_pathname = Pathname(line_match.group("target_pathname"))

                    pathname_match: PathnamePrefixMatch | None = None

                    pathname_match = target_pathname.match_prefix(_HOME_VAR_PREFIX_PATHNAME)
                    if pathname_match is not None:
                        target_pathname = home_pathname.appended_with(pathname_match.suffix)

                    if pathname_match is None:
                        pathname_match = target_pathname.match_prefix(_XDG_CONFIG_HOME_VAR_PREFIX_PATHNAME)
                    if pathname_match is not None:
                        target_pathname = xdg_config_home_pathname.appended_with(pathname_match.suffix)

                    file_copy_instruction = FileCopyInstruction(
                        source=File(source_pathname),
                        target=File(target_pathname.normalized()),
                    )

                    current_instruction_group.file_copy_instructions.append(file_copy_instruction)
                    continue

                raise InstructionsReadError(
                    instructions_file_pathname,
                    lineno,
                    "Invalid line in instruction definition",
                )

            line_match = re.match(r"^Include\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
            if line_match is not None:
                include_pathname: Pathname = Pathname.create_normalized(line_match.group("pathname"))

                source_dir_pathname_to_include: Pathname = source_dir_pathname.appended_with(include_pathname)

                included_instruction_groups: list[InstructionGroup] = read_instructions(
                    source_dir_pathname_to_include,
                    home_pathname,
                    xdg_config_home_pathname,
                )

                for included_instruction_group in included_instruction_groups:
                    mapped_file_copy_instructions: list[FileCopyInstruction] = []

                    for included_file_copy_instruction in included_instruction_group.file_copy_instructions:
                        mapped_source_pathname: Pathname = include_pathname \
                            .appended_with(included_file_copy_instruction.source.pathname)

                        mapped_file_copy_instruction: FileCopyInstruction = included_file_copy_instruction \
                            .with_source(File(mapped_source_pathname))

                        mapped_file_copy_instructions.append(mapped_file_copy_instruction)

                    mapped_instruction_group: InstructionGroup = included_instruction_group \
                        .with_file_copy_instructions(mapped_file_copy_instructions)

                    instruction_groups.append(mapped_instruction_group)

                continue

            line_match = re.match(r"^Group\s*\"(?P<name>[^\"]+)\"\s*\{(\s*#.*)?$", line)
            if line_match is not None:
                name: str = line_match.group("name")
                current_instruction_group = InstructionGroup(name, [])
                continue

            raise InstructionsReadError(instructions_file_pathname, lineno, "Invalid top-level line")

    return instruction_groups
