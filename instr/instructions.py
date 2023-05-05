# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

import errno
import os
import re
from dataclasses import dataclass

from instr import fs
from instr.pathname import Pathname, PathnameComponent


@dataclass(frozen=True)
class File:

    pathname: Pathname

    def with_pathname(self, new_pathname: Pathname) -> "File":
        return File(new_pathname)


@dataclass
class FileCopyInstruction:

    source: File
    target: File


@dataclass
class InstructionGroup:

    name: str
    file_copy_instructions: list[FileCopyInstruction]

    def __init__(self, name: str, file_copy_instructions: list[FileCopyInstruction]):
        self.name = name
        self.file_copy_instructions = file_copy_instructions.copy()


class InstructionsReadError(Exception):

    pathname: Pathname
    lineno: int
    msg: str

    def __init__(self, pathname: Pathname, lineno: int, msg: str):
        super().__init__(pathname, lineno, msg)

        self.pathname = pathname
        self.lineno = lineno
        self.msg = msg


@dataclass(frozen=True)
class _InstructionsReadState:

    current_instruction_group: InstructionGroup | None


# region _read_line()

@dataclass(frozen=True)
class _FileInclude:

    instructions: list[InstructionGroup]


@dataclass(frozen=True)
class _GroupBegin:

    name: str


@dataclass(frozen=True)
class _NewFileCopyInstruction:

    target_instruction_group: InstructionGroup
    new_file_copy_instruction: FileCopyInstruction


@dataclass(frozen=True)
class _GroupEnd:

    instruction_group: InstructionGroup


@dataclass(frozen=True)
class _ReadFailure:

    message: str


def _read_line(
    state: _InstructionsReadState,
    line: str,
    source_dir_pathname: Pathname,
    home: Pathname,
    xdg_config_home: Pathname,
) -> None | _FileInclude | _GroupBegin | _NewFileCopyInstruction | _GroupEnd | _ReadFailure:
    line = line.strip()

    if line == "" or line.startswith("#"):
        return None

    match: re.Match[str] | None = None

    if state.current_instruction_group is not None:
        match = re.match(r"^\}(\s*#.*)?$", line)
        if match is not None:
            return _GroupEnd(
                instruction_group=state.current_instruction_group,
            )

        match = re.match(
            r"^Copy\s+File\s*\"(?P<source_pathname>[^\"]+)\"\s*To\s+File\s*\"(?P<target_pathname>[^\"]+)\"(\s*#.*)?$",
            line,
        )
        if match is not None:
            source_pathname: Pathname = Pathname.create_normalized(match.group("source_pathname"))
            target_pathname = Pathname(match.group("target_pathname"))

            if str(target_pathname).startswith("$HOME"):
                target_pathname = Pathname(str(target_pathname).removeprefix("$HOME"))

                target_pathname = home.appended_with(target_pathname)
            elif str(target_pathname).startswith("$XDG_CONFIG_HOME"):
                target_pathname = Pathname(str(target_pathname).removeprefix("$XDG_CONFIG_HOME"))

                target_pathname = xdg_config_home.appended_with(target_pathname)

            target_pathname = target_pathname.normalized()

            file_copy_instruction = FileCopyInstruction(
                source=File(source_pathname),
                target=File(target_pathname),
            )

            return _NewFileCopyInstruction(
                target_instruction_group=state.current_instruction_group,
                new_file_copy_instruction=file_copy_instruction,
            )

        return _ReadFailure(message="Invalid line in instruction group definition")

    match = re.match(r"^Include\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
    if match is not None:
        source_dir_pathname_to_include: Pathname = source_dir_pathname \
            .appended_with(Pathname(match.group("pathname"))) \
            .normalized()

        included_instructions: list[InstructionGroup] = read_instructions(
            source_dir_pathname_to_include,
            home,
            xdg_config_home,
        )
        for instruction in included_instructions:
            for (i, file_copy_instruction) in enumerate(instruction.file_copy_instructions):
                basename: PathnameComponent | None = source_dir_pathname_to_include.basename()
                assert basename is not None

                instruction.file_copy_instructions[i] = FileCopyInstruction(
                    source=File(
                        Pathname.create_relative_of_component(basename)
                        .appended_with(file_copy_instruction.source.pathname)
                        .normalized()
                    ),
                    target=file_copy_instruction.target,
                )

        return _FileInclude(
            instructions=included_instructions,
        )

    match = re.match(r"^Group\s*\"(?P<name>[^\"]+)\"\s*\{(\s*#.*)?$", line)
    if match is not None:
        name: str = match.group("name")
        return _GroupBegin(
            name=name,
        )

    return _ReadFailure(message="Invalid top-level line")

# endregion


_INSTRUCTIONS_FILE_PATHNAME_COMPONENT: PathnameComponent = PathnameComponent("Instructions.cfg")


def read_instructions(
    source_dir_pathname: Pathname,
    home: Pathname,
    xdg_config_home: Pathname,
) -> list[InstructionGroup]:
    file_pathname: Pathname = source_dir_pathname.appended_with(_INSTRUCTIONS_FILE_PATHNAME_COMPONENT)

    if not fs.exists(file_pathname):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), str(file_pathname))

    if fs.is_directory(file_pathname):
        raise IsADirectoryError(errno.EISDIR, os.strerror(errno.EISDIR), str(file_pathname))

    instructions: list[InstructionGroup] = []

    with open(str(file_pathname), "r", encoding="utf8") as file_io_wrapper:
        lineno: int = 0

        state = _InstructionsReadState(
            current_instruction_group=None,
        )

        for line in file_io_wrapper:
            lineno += 1

            match _read_line(state, line, source_dir_pathname, home, xdg_config_home):
                case None:
                    pass
                case _FileInclude(included_instructions):
                    instructions.extend(included_instructions)
                case _GroupBegin(name):
                    state = _InstructionsReadState(
                        current_instruction_group=InstructionGroup(name, []),
                    )
                case _NewFileCopyInstruction(target_instruction_group, new_file_copy_instruction):
                    target_instruction_group.file_copy_instructions.append(new_file_copy_instruction)
                case _GroupEnd(instruction_group):
                    instructions.append(instruction_group)
                    state = _InstructionsReadState(
                        current_instruction_group=None,
                    )
                case _ReadFailure(message):
                    raise InstructionsReadError(file_pathname, lineno, message)

    return instructions
