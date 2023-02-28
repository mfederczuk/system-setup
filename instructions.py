# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from dataclasses import dataclass
import os
import errno
import re


def require_arg_of_type(arg_name: str, actual_value: any, expected_type: type):
    if type(arg_name) != str:
        raise TypeError(f"Argument 'arg_name' must be of type {str.__name__}")

    if type(expected_type) != type:
        raise TypeError(f"Argument 'expected_type' must be of type {type.__name__}")

    if type(actual_value) == expected_type:
        return

    raise TypeError(f"Argument '{arg_name}' must be of type {expected_type.__name__}")


def require_arg_of_list_type(arg_name: str, actual_value: any, expected_item_type: type):
    require_arg_of_type("expected_item_type", expected_item_type, type)

    require_arg_of_type(arg_name, actual_value, list)

    for i in range(0, len(actual_value)):
        item: any = actual_value[i]

        if type(item) == expected_item_type:
            continue

        msg: str = (f"Item at index {i} of {list.__name__} argument '{arg_name}'" +
                    f"must be of type {expected_item_type.__name__}")
        raise ValueError(msg)


@dataclass
class FileCopyInstruction:

    source: str
    target: str

    def __init__(self, source: str, target: str):
        require_arg_of_type("source", source, str)
        require_arg_of_type("target", target, str)

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


def read_instructions(source_dir_pathname: str, HOME: str, XDG_CONFIG_HOME: str) -> list[InstructionGroup]:
    require_arg_of_type("source_dir_pathname", source_dir_pathname, str)
    require_arg_of_type("HOME", HOME, str)
    require_arg_of_type("XDG_CONFIG_HOME", XDG_CONFIG_HOME, str)

    file_pathname: str = os.path.join(source_dir_pathname, "Instructions.cfg")

    if not os.path.exists(file_pathname):
        raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), file_pathname)

    if os.path.isdir(file_pathname):
        raise IsADirectoryError(errno.EISDIR, os.strerror(errno.EISDIR), file_pathname)

    instructions: list[InstructionGroup] = []

    with open(file_pathname, "r") as f:
        lineno: int = 0

        @dataclass
        class ReadState:

            instruction_group: InstructionGroup
            file_copy_instruction: FileCopyInstruction | None

            def __init__(self, instruction_group: FileCopyInstruction) -> None:
                self.instruction_group = instruction_group
                self.file_copy_instruction = None

        current_state: ReadState | None = None

        for line in f:
            lineno += 1

            line = line.strip()

            if line == "" or line.startswith("#"):
                continue

            match: re.Match | None = None

            if current_state != None and current_state.file_copy_instruction != None:
                current_instruction_group: InstructionGroup = current_state.instruction_group
                current_file_copy_instruction: FileCopyInstruction = current_state.file_copy_instruction

                match = re.match(r"^\)(\s*#.*)?$", line)
                if match != None:
                    if current_file_copy_instruction.source == "":
                        raise InstructionsReadError(file_pathname, lineno, "File definition is missing a source")

                    if current_file_copy_instruction.target == "":
                        raise InstructionsReadError(file_pathname, lineno, "File definition is missing a target")

                    current_instruction_group.file_copy_instructions.append(current_file_copy_instruction)
                    current_state.file_copy_instruction = None
                    continue

                match = re.match(r"^Source\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
                if match != None:
                    source_pathname: str = match.group("pathname")

                    if os.path.isabs(source_pathname):
                        raise InstructionsReadError(file_pathname, lineno, "Source pathname must be relative")

                    current_file_copy_instruction.source = source_pathname

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

                    current_file_copy_instruction.target = target_pathname

                    continue

                raise InstructionsReadError(file_pathname, lineno, "Invalid line in instruction file definition")

            if current_state != None:
                current_instruction_group: InstructionGroup = current_state.instruction_group

                match = re.match(r"^\}(\s*#.*)?$", line)
                if match != None:
                    instructions.append(current_instruction_group)
                    current_state = None
                    continue

                match = re.match(r"^File\s*\((\s*#.*)?$", line)
                if match != None:
                    current_state.file_copy_instruction = FileCopyInstruction("", "")
                    continue

                raise InstructionsReadError(file_pathname, lineno, "Invalid line in instruction definition")

            match = re.match(r"^Include\s*\"(?P<pathname>[^\"]+)\"(\s*#.*)?$", line)
            if match != None:
                source_dir_pathname_to_include: str = os.path.join(source_dir_pathname, match.group("pathname"))

                included_instructions: list[InstructionGroup] = read_instructions(
                    source_dir_pathname_to_include,
                    HOME,
                    XDG_CONFIG_HOME,
                )
                for instruction in included_instructions:
                    for i in range(0, len(instruction.file_copy_instructions)):
                        file: FileCopyInstruction = instruction.file_copy_instructions[i]

                        instruction.file_copy_instructions[i] = FileCopyInstruction(
                            source=os.path.join(os.path.basename(source_dir_pathname_to_include), file.source),
                            target=file.target,
                        )

                instructions.extend(included_instructions)

                continue

            match = re.match(r"^Group\s*\"(?P<name>[^\"]+)\"\s*\{(\s*#.*)?$", line)
            if match != None:
                name: str = match.group("name")
                current_state = ReadState(InstructionGroup(name, []))
                continue

            raise InstructionsReadError(file_pathname, lineno, "Invalid top-level line")

    return instructions
