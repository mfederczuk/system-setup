# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from __future__ import annotations

import re
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import NoReturn, Self, final

from instr import proc
from instr.pathname import Pathname


class ExitStatus(ABC):

    def get_usage(self: Self) -> str | None:
        return None

    @abstractmethod
    def get_message(self: Self) -> str:
        raise NotImplementedError("Abstract method is not implemented")

    @abstractmethod
    def get_code(self: Self) -> int:
        raise NotImplementedError("Abstract method is not implemented")

    # convenience methods

    def _create_usage_with_prefix(self: ExitStatus, prefix: str) -> str | None:
        usage: str | None = self.get_usage()

        if usage is None:
            return None

        usage_with_prefix: str = prefix

        if len(usage_with_prefix) > 0:
            usage_with_prefix += " "

        usage_with_prefix += usage

        return usage_with_prefix

    def print_usage_to_stderr(self: ExitStatus, prefix: str = ""):
        usage: str | None = self._create_usage_with_prefix(prefix)

        if usage is None:
            return

        print("usage: " + usage, file=proc.stderr)

    def _create_message_with_prefixes(self: ExitStatus, *prefixes: str) -> str:
        message_with_prefixes: str = ""

        for prefix in prefixes:
            message_with_prefixes += f"{prefix}: "

        message_with_prefixes += self.get_message()

        return message_with_prefixes

    def print_message_to_stderr(self: ExitStatus, *prefixes: str):
        print(self._create_message_with_prefixes(*prefixes), file=proc.stderr)

    def exit_with_code(self: ExitStatus) -> NoReturn:
        proc.exit(self.get_code())

    def is_not_success(self: ExitStatus) -> bool:
        return self.get_code() != 0

    def is_feedback(self: ExitStatus) -> bool:
        return self.get_code() in range(32, 48)

    def is_failure(self: ExitStatus) -> bool:
        return self.get_code() != 0 and not self.is_feedback()

    def die(self: ExitStatus, message_prefixes: list[str], usage_prefix: str) -> NoReturn:
        if self.is_failure():
            message: str = self._create_message_with_prefixes(*message_prefixes)
            usage: str | None = self._create_usage_with_prefix(usage_prefix)

            out_str: str = message

            if usage is not None:
                out_str += f"\nusage: {usage}"

            print(out_str, file=proc.stderr)

        self.exit_with_code()

    def die_with_argv0(self: ExitStatus) -> NoReturn:
        argv0: str = proc.argv[0]
        self.die(message_prefixes=[argv0], usage_prefix=argv0)


@dataclass(frozen=True)
@final
class SuccessExitStatus(ExitStatus):

    def get_code(self: SuccessExitStatus) -> int:
        return 0

    def get_message(self: SuccessExitStatus) -> str:
        return "success"


@dataclass(frozen=True)
@final
class MissingArgumentExitStatus(ExitStatus):

    usage: str

    is_multiple_args: bool
    arguments: str

    def __post_init__(self: MissingArgumentExitStatus):
        if len(self.arguments) == 0:
            raise ValueError("Arguments string must not be empty")

    def get_usage(self: MissingArgumentExitStatus) -> str:
        return self.usage

    def get_message(self: MissingArgumentExitStatus) -> str:
        if not self.is_multiple_args:
            return f"missing argument: {self.arguments}"

        return f"missing arguments: {self.arguments}"

    def get_code(self: MissingArgumentExitStatus) -> int:
        return 3


@dataclass(frozen=True)
@final
class TooManyArgumentsExitStatus(ExitStatus):

    usage: str

    excessive_arguments_count: int

    def __post_init__(self: TooManyArgumentsExitStatus):
        if self.excessive_arguments_count <= 0:
            raise ValueError("Excessive arguments count must be greater than 0")

    def get_usage(self: TooManyArgumentsExitStatus) -> str:
        return self.usage

    def get_message(self: TooManyArgumentsExitStatus) -> str:
        return f"too many arguments: {self.excessive_arguments_count}"

    def get_code(self: TooManyArgumentsExitStatus) -> int:
        return 4


@dataclass(frozen=True)
@final
class UnknownCommandExitStatus(ExitStatus):

    usage: str

    command_name: str

    def __post_init__(self: UnknownCommandExitStatus):
        if self.command_name == "":
            raise ValueError("Command name must not be empty")

    def get_usage(self: UnknownCommandExitStatus) -> str:
        return self.usage

    def get_message(self: UnknownCommandExitStatus) -> str:
        return f"{self.command_name}: unknown command"

    def get_code(self: UnknownCommandExitStatus) -> int:
        return 8


@dataclass(frozen=True)
@final
class EmptyArgumentExitStatus(ExitStatus):

    usage: str

    argument_nr: int | None

    def __post_init__(self: EmptyArgumentExitStatus):
        if self.argument_nr is not None and self.argument_nr < 0:
            raise ValueError("Argument nr must be greater 1 or greater")

    def get_usage(self: EmptyArgumentExitStatus) -> str:
        return self.usage

    def get_message(self: EmptyArgumentExitStatus) -> str:
        if self.argument_nr is None:
            return "argument must not be empty"

        return f"argument {self.argument_nr}: must not be empty"

    def get_code(self: EmptyArgumentExitStatus) -> int:
        return 9


@dataclass(frozen=True)
@final
class NoSuchItemtypeExitStatus(ExitStatus):

    item: str
    itemtype: str

    def __post_init__(self: NoSuchItemtypeExitStatus):
        if self.item == "":
            raise ValueError("Item must not be empty")

        if self.itemtype == "":
            raise ValueError("Itemtype must not be empty")

    def get_message(self: NoSuchItemtypeExitStatus) -> str:
        return f"{self.item}: no such {self.itemtype}"

    def get_code(self: NoSuchItemtypeExitStatus) -> int:
        return 24


@dataclass(frozen=True)
@final
class WrongItemtypeExitStatus(ExitStatus):

    item: str
    itemtype: str

    def __post_init__(self: WrongItemtypeExitStatus):
        if self.item == "":
            raise ValueError("Item must not be empty")

        if self.itemtype == "":
            raise ValueError("Itemtype must not be empty")

    def get_message(self: WrongItemtypeExitStatus) -> str:
        article: str = "a"
        if re.match(r"^[aeiou]", self.itemtype, flags=re.RegexFlag.IGNORECASE) is not None:
            article = "an"

        return f"{self.item}: not {article} {self.itemtype}"

    def get_code(self: WrongItemtypeExitStatus) -> int:
        return 26


# region custom exit statuses


@dataclass(frozen=True)
@final
class AbortedExitStatus(ExitStatus):

    def get_code(self: AbortedExitStatus) -> int:
        return 32

    def get_message(self: AbortedExitStatus) -> str:
        return "aborted"


@dataclass(frozen=True)
@final
class EnvironmentalVariableUnsetOrEmptyExitStatus(ExitStatus):

    variable_name: str

    def __post_init__(self: EnvironmentalVariableUnsetOrEmptyExitStatus):
        if self.variable_name == "":
            raise ValueError("Variable name must not be empty")

    def get_code(self: EnvironmentalVariableUnsetOrEmptyExitStatus) -> int:
        return 48

    def get_message(self: EnvironmentalVariableUnsetOrEmptyExitStatus) -> str:
        return f"{self.variable_name} environment variable must not be unset nor empty"


@dataclass(frozen=True)
@final
class EnvironmentVariableIsRelativePathnameExitStatus(ExitStatus):

    variable_name: str

    def __post_init__(self: EnvironmentVariableIsRelativePathnameExitStatus):
        if self.variable_name == "":
            raise ValueError("Variable name must not be empty")

    def get_code(self: EnvironmentVariableIsRelativePathnameExitStatus) -> int:
        return 49

    def get_message(self: EnvironmentVariableIsRelativePathnameExitStatus) -> str:
        return f"{self.variable_name} environment variable must be an absolute pathname"


@dataclass(frozen=True)
@final
class InstructionsSyntaxExitStatus(ExitStatus):

    file_pathname: Pathname
    lineno: int
    error_message: str

    def __post_init__(self: InstructionsSyntaxExitStatus):
        if self.lineno < 1:
            raise ValueError("Line number must not be less than 1")

        if self.error_message == "":
            raise ValueError("Error message must not be empty")

    def get_code(self: InstructionsSyntaxExitStatus) -> int:
        return 50

    def get_message(self: InstructionsSyntaxExitStatus) -> str:
        return f"{self.file_pathname}:{self.lineno}: {self.error_message}"


# endregion
