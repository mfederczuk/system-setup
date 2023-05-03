# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from __future__ import annotations

from dataclasses import dataclass
from typing import ClassVar, final


@dataclass(frozen=True)
@final
class PathnameComponent:
    """
    Represents a valid abstract POSIX filesystem pathname component.
    """

    separator: ClassVar[str] = "/"

    _value: str

    def __post_init__(self: PathnameComponent) -> None:
        if self._value == "":
            raise ValueError("Pathname component must not be empty")

        if "\0" in self._value:
            raise ValueError("Pathname component must not contain any NUL characters")

        if PathnameComponent.separator in self._value:
            raise ValueError("Pathname component must not contain any component separator")

    def __str__(self: PathnameComponent) -> str:
        """
        Return `str(self)`; the underlying string value of this pathname.
        """

        return self._value


@dataclass(frozen=True)
@final
class Pathname:
    """
    Represents a valid abstract POSIX filesystem pathname.
    "Abstract" because no method of this class ever queries the filesystem.
    """

    _value: str

    def __post_init__(self: Pathname):
        if self._value == "":
            raise ValueError("Pathname must not be empty")

        if "\0" in self._value:
            raise ValueError("Pathname must not contain any NUL characters")

    @staticmethod
    def create_normalized(value: str) -> Pathname:
        """
        Return a normalized pathname of the given string.

        This is a convenience function for `Pathname(value).normalized()`.
        """

        return Pathname(value).normalized()

    def is_absolute(self: Pathname) -> bool:
        """
        Return whether or not this pathname is absolute.

        This is the inverse operation of `self.is_relative()`.
        """

        return str(self).startswith(PathnameComponent.separator)

    def is_relative(self: Pathname) -> bool:
        """
        Return whether or not this pathname is relative.

        This is the inverse operation of `self.is_absolute()`.
        """

        return not self.is_absolute()

    def normalized(self: Pathname) -> Pathname:
        # note: not using `os.path.normpath()` because it also removes '..' components, which is wrong; it changes the
        #       behavior of the path resolution

        normalied_value: str = self._value

        while "/./" in normalied_value:
            normalied_value = normalied_value.replace("/./", "/")

        while "//" in normalied_value:
            normalied_value = normalied_value.replace("//", "/")

        if normalied_value.startswith("./") and len(self._value) > 2:
            normalied_value = normalied_value.removeprefix("./")

        if normalied_value.endswith("/."):
            normalied_value = normalied_value.removesuffix(".")

        return Pathname(normalied_value)

    def __str__(self: Pathname) -> str:
        """
        Return `str(self)`; the underlying string value of this pathname.
        """

        return self._value
