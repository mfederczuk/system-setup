# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from dataclasses import dataclass
import os
import errno
import re


@dataclass
class InstructionFile:

    desc: str
    source: str
    target: str

    def __init__(self, desc: str, source: str, target: str):
        self.desc = desc
        self.source = source
        self.target = target


@dataclass
class Instruction:

    name: str
    files: list[InstructionFile]

    def __init__(self, name: str, files: list[InstructionFile]):
        self.name = name
        self.files = files.copy()


class InstructionsReadError(Exception):

    pathname: str
    lineno: int
    msg: str

    def __init__(self, pathname: str, lineno: int, msg: str):
        super().__init__(pathname, lineno, msg)

        self.pathname = pathname
        self.lineno = lineno
        self.msg = msg


def read_instructions(source_dir_pathname: str, HOME: str, XDG_CONFIG_HOME: str) -> list[Instruction]:
    file_pathname: str = os.path.join(source_dir_pathname, "Instructions.cfg")

    if not os.path.exists(file_pathname):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), file_pathname)

    if os.path.isdir(file_pathname):
        raise IsADirectoryError(errno.EISDIR, os.strerror(errno.EISDIR), file_pathname)

    instructions: list[Instruction] = []

    with open(file_pathname, "r") as f:
        lineno: int = 0

        current_instruction_with_current_file: tuple[Instruction, InstructionFile | None] | None = None

        for line in f:
            lineno += 1

            line = line.strip()

            if line == "" or line.startswith("#"):
                continue

            match: re.Match | None = None

            if current_instruction_with_current_file != None and current_instruction_with_current_file[1] != None:
                current_instruction: Instruction = current_instruction_with_current_file[0]
                current_instruction_file: InstructionFile = current_instruction_with_current_file[1]

                match = re.match(r"^\)(\s*#.*)?$", line)
                if match != None:
                    if current_instruction_file.source == "":
                        raise InstructionsReadError(file_pathname, lineno, "File definition is missing a source")

                    if current_instruction_file.target == "":
                        raise InstructionsReadError(file_pathname, lineno, "File definition is missing a target")

                    current_instruction.files.append(current_instruction_file)
                    current_instruction_with_current_file = (current_instruction, None)
                    continue

                match = re.match(r"^Source\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
                if match != None:
                    source_pathname: str = match.group("pathname")

                    if os.path.isabs(source_pathname):
                        raise InstructionsReadError(file_pathname, lineno, "Source pathname must be relative")

                    current_instruction_file.source = source_pathname

                    continue

                match = re.match(r"^Target\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
                if match != None:
                    target_pathname: str = match.group("pathname")

                    if target_pathname.startswith("$HOME"):
                        target_pathname = os.path.join(
                            HOME,
                            os.path.relpath(target_pathname.removeprefix("$HOME"), os.path.abspath(os.sep)),
                        )
                    elif target_pathname.startswith("$XDG_CONFIG_HOME"):
                        target_pathname = os.path.join(
                            XDG_CONFIG_HOME,
                            os.path.relpath(target_pathname.removeprefix("$XDG_CONFIG_HOME"), os.path.abspath(os.sep)),
                        )

                    if not os.path.isabs(target_pathname):
                        raise InstructionsReadError(file_pathname, lineno, "Target pathname must be absolute")

                    current_instruction_file.target = target_pathname

                    continue

                raise InstructionsReadError(file_pathname, lineno, "Invalid line in instruction file definition")

            if current_instruction_with_current_file != None:
                current_instruction: Instruction = current_instruction_with_current_file[0]

                match = re.match(r"^\)(\s*#.*)?$", line)
                if match != None:
                    instructions.append(current_instruction)
                    current_instruction_with_current_file = None
                    continue

                match = re.match(r"^File\s*\"(?P<desc>[^\"]+)\"\s*\((\s*#.*)?$", line)
                if match != None:
                    desc: str = match.group("desc")
                    current_instruction_with_current_file = (current_instruction, InstructionFile(desc, "", ""))
                    continue

                raise InstructionsReadError(file_pathname, lineno, "Invalid line in instruction definition")

            match = re.match(r"^Include\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
            if match != None:
                source_dir_pathname_to_include: str = os.path.join(source_dir_pathname, match.group("pathname"))

                included_instructions: list[Instruction] = read_instructions(
                    source_dir_pathname_to_include,
                    HOME,
                    XDG_CONFIG_HOME,
                )
                for instruction in included_instructions:
                    for i in range(0, len(instruction.files)):
                        file: InstructionFile = instruction.files[i]

                        instruction.files[i] = InstructionFile(
                            file.desc,
                            source=os.path.join(os.path.basename(source_dir_pathname_to_include), file.source),
                            target=file.target,
                        )

                instructions.extend(included_instructions)

                continue

            match = re.match(r"^Instruction\s*\"(?P<name>[^\"]+)\"\s*\((\s*#.*)?$", line)
            if match != None:
                name: str = match.group("name")
                current_instruction_with_current_file = (Instruction(name, []), None)
                continue

            raise InstructionsReadError(file_pathname, lineno, "Invalid top-level line")

    return instructions
