# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from __future__ import annotations

from dataclasses import dataclass
from typing import ClassVar, final


def _squeeze(base_str: str, char: str) -> str:
    if len(char) != 1:
        raise ValueError("Value to squeeze must be a single character (string with length of 1)")

    resulting_str: str = base_str

    while f"{char}{char}" in resulting_str:
        resulting_str = resulting_str.replace(f"{char}{char}", char)

    return resulting_str


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
    def create_relative_of_component(component: PathnameComponent) -> Pathname:
        """
        Return a relative pathname that has a single component and no trailing component separator.
        """

        return Pathname(str(component))

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

    def appended_with(self: Pathname, *suffixes: Pathname | PathnameComponent) -> Pathname:
        """
        Return this pathname, appended with all given suffixes.

        Between all items (which are this pathname + all suffixes), a component separator is inserted if neither
        the left item has a trailing separator nor the right item has a leading separator, though none of the items will
        be normalized; repeating component separators are retained.

        This operation is sometimes also referred to as "joining" pathnames together, though this term was consciously
        not chosen because the behavior of `os.path.join` is slightly different than that of this function's.
        """

        resulting_pathname_str: str = str(self)

        for suffix in suffixes:
            if isinstance(suffix, PathnameComponent):
                suffix = Pathname.create_relative_of_component(suffix)

            resulting_pathname_str = resulting_pathname_str.removesuffix(PathnameComponent.separator)
            resulting_pathname_str += PathnameComponent.separator
            resulting_pathname_str += str(suffix).removeprefix(PathnameComponent.separator)

        return Pathname(resulting_pathname_str)

    def normalized(self: Pathname) -> Pathname:
        """
        Return a normalized form of this pathname.
        A normalized pathname retains the path resolution behavior of the original pathname.

        Normalization is done by squeezing all repeating occurrences of the component separator to a single one and
        removing all `.` components.

        If the resulting pathname after the normalization would be empty (which will never happen if
        the original pathname is absolute), then a relative pathname with just a single `.` component and no trailing
        component separator is returned.

        If the previous paragraph is not the case and the original pathname has a trailing `.` component, then
        the returned pathname will have a trailing component separator.

        Note that `..` components are NOT removed. This is because doing so would change the path resolution behavior of
        the pathname if the component directly preceding the `..` component is a symbolic link.
        """

        normalized_pathname_str: str = str(self)

        normalized_pathname_str = _squeeze(normalized_pathname_str, PathnameComponent.separator)

        # removing all non-leading and -trailing '.' components
        while f"{PathnameComponent.separator}.{PathnameComponent.separator}" in normalized_pathname_str:
            normalized_pathname_str = normalized_pathname_str.replace(
                f"{PathnameComponent.separator}.{PathnameComponent.separator}",
                PathnameComponent.separator,
            )

        normalized_pathname_str = normalized_pathname_str.removeprefix(f".{PathnameComponent.separator}")

        # removing trailing '.' component (trailing component separator is retained)
        if normalized_pathname_str.endswith(f"{PathnameComponent.separator}."):
            normalized_pathname_str = normalized_pathname_str[0:-1]

        if normalized_pathname_str == "":
            normalized_pathname_str = "."

        return Pathname(normalized_pathname_str)

    def __str__(self: Pathname) -> str:
        """
        Return `str(self)`; the underlying string value of this pathname.
        """

        return self._value
