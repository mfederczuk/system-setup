# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from __future__ import annotations

from dataclasses import dataclass
from abc import ABC
from typing import ClassVar, Generator, final


def _str_sub(base_str: str, str_range: range) -> str:
    return base_str[str_range.start:str_range.stop]


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


# @dataclass(frozen=True)
# @final
# class _NextPathnameComponentInfo:

#     component: PathnameComponent | None
#     has_trailing_separator: bool
#     continuing_index: int

# def _find_next_component(pathname_str: str, begin_index: int) -> _NextPathnameComponentInfo:
#     current_index: int = begin_index

#     while current_index < len(pathname_str) and pathname_str[current_index] == PathnameComponent.separator:
#         current_index += 1

#     if current_index >= len(pathname_str):
#         return _NextPathnameComponentInfo(
#             component=None,
#             has_trailing_separator=
#         )


def _find_next_component_range(pathname_str: str, begin_index: int) -> range | None:
    current_index: int = begin_index

    while current_index < len(pathname_str) and pathname_str[current_index] == PathnameComponent.separator:
        current_index += 1

    if current_index >= len(pathname_str):
        return None

    component_begin_index: int = current_index

    component_end_index: int = pathname_str.find(PathnameComponent.separator, current_index)

    if component_end_index < 0:
        component_end_index = len(pathname_str)

    if component_end_index - component_begin_index <= 0:
        return None

    return range(component_begin_index, component_end_index)


@dataclass(frozen=True)
@final
class PathnameAnalysis:

    @dataclass(frozen=True)
    @final
    class Root:

        separator_count: int
        next_element: PathnameAnalysis.Component | None

    @dataclass(frozen=True)
    @final
    class Component:

        prev_element: PathnameAnalysis.Root | PathnameAnalysis.ComponentSeparation
        value: PathnameComponent
        next_element: PathnameAnalysis.ComponentSeparation | PathnameAnalysis.TrailingSeparation

    @dataclass(frozen=True)
    @final
    class ComponentSeparation:

        prev_element: PathnameAnalysis.Component
        separator_count: int
        next_element: PathnameAnalysis.Component

    @dataclass(frozen=True)
    @final
    class TrailingSeparation:

        prev_element: PathnameAnalysis.Component
        separator_count: int

    first_element: Root | Component
    last_element: Root | Component | TrailingSeparation


@dataclass(frozen=True)
@final
class PathnameAnalysisNew:

    @dataclass(frozen=True)
    @final
    class Component:

        prev_element: PathnameAnalysis.ComponentSeparation | None
        value: PathnameComponent
        next_element: PathnameAnalysisNew.ComponentSeparation | None

    @dataclass(frozen=True)
    @final
    class ComponentSeparation:

        prev_element: PathnameAnalysisNew.Component | None
        separator_count: int
        next_element: PathnameAnalysisNew.Component | None

        def __post_init__(self: PathnameAnalysisNew.ComponentSeparation) -> None:
            if self.separator_count <= 0:
                raise ValueError("Separator count must be a positive integer")

    first_element: ComponentSeparation | Component
    last_element: ComponentSeparation | Component

    def __iter__(self: PathnameAnalysisNew) -> Generator[Component | ComponentSeparation, None, None]:
        current_element: PathnameAnalysisNew.Component | PathnameAnalysisNew.ComponentSeparation | None = \
            self.first_element

        while current_element is not None:
            yield current_element
            current_element = current_element.next_element


@dataclass(frozen=True)
@final
class PathnameAnalysisNewNew:

    @dataclass(frozen=True)
    @final
    class Component:

        prev_element: PathnameAnalysisNewNew.Root | None | PathnameAnalysisNewNew.MiddleSeparation
        value: PathnameComponent
        next_element: PathnameAnalysisNewNew.MiddleSeparation | None | PathnameAnalysisNewNew.TrailingSeparation

        def __str__(self: PathnameAnalysisNewNew.Component) -> str:
            return str(self.value)

    @dataclass(frozen=True)
    class ComponentSeparation(ABC):

        prev_element: PathnameAnalysisNewNew.Component | None
        separator_count: int
        next_element: PathnameAnalysisNewNew.Component | None

        def __post_init__(self: PathnameAnalysisNewNew.ComponentSeparation) -> None:
            if self.separator_count <= 0:
                raise ValueError("Separator count must be a positive integer")

        def __str__(self: PathnameAnalysisNewNew.ComponentSeparation) -> str:
            return PathnameComponent.separator * self.separator_count

    @dataclass(frozen=True)
    @final
    class Root(ComponentSeparation):

        prev_element: None

    @dataclass(frozen=True)
    @final
    class MiddleSeparation(ComponentSeparation):
        pass

    @dataclass(frozen=True)
    @final
    class TrailingSeparation(ComponentSeparation):

        prev_element: PathnameAnalysisNewNew.Component
        separator_count: int
        next_element: None

    first_element: Root | Component
    last_element: Root | Component | TrailingSeparation

    def __iter__(self: PathnameAnalysisNewNew) -> Generator[Root | Component | MiddleSeparation | TrailingSeparation, None, None]:
        current_element: PathnameAnalysisNewNew.Root | PathnameAnalysisNewNew.Component | PathnameAnalysisNewNew.MiddleSeparation | PathnameAnalysisNewNew.TrailingSeparation | None = \
            self.first_element

        while current_element is not None:
            yield current_element
            current_element = current_element.next_element

@dataclass(frozen=True)
@final
class PathnamePrefixMatch:

    prefix: Pathname
    suffix: Pathname | None


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

    def analyze_new_new(self: Pathname) -> PathnameAnalysisNewNew:
        pass

    def analyze_new(self: Pathname) -> PathnameAnalysisNew:
        pass

    def analyze(self: Pathname) -> PathnameAnalysis:
        elements: list[PathnameAnalysis.ComponentSeparation | PathnameComponent] = []

        is_prev_ch_separator: bool = False

        current_component = \
            PartialPathnameComponentInfo(
                has_leading_separator=False,
                component_str="",
                has_trailing_separator=False,
            )

        for ch in str(self):
            pass

        return components

    def match_prefix_new(self: Pathname, prefix: Pathname) -> PathnamePrefixMatch | None:
        prefix_pathname_str: str = str(prefix)
        prefix_pathname_str_i: int = 0

        self_pathname_str: str = str(self)
        self_pathname_str_i: int = 0

        while prefix_pathname_str_i < len(prefix_pathname_str) and self_pathname_str_i < len(self_pathname_str):
            next_prefix_component_has_leading_separator: bool = False

            while prefix_pathname_str[prefix_pathname_str_i] == PathnameComponent.separator:
                next_prefix_component_has_leading_separator = True
                prefix_pathname_str_i += 1

            next_prefix_component_end_i: int = \
                prefix_pathname_str.find(
                    PathnameComponent.separator,
                    prefix_pathname_str_i,
                )

            if next_prefix_component_end_i < 0:

    def match_prefix(self: Pathname, prefix: Pathname) -> PathnamePrefixMatch | None:
        """
        Try to match the prefix pathname at the beginning of this pathname; return a `PathnamePrefixMatch` object if it
        does, `None` otherwise.

        In the returned `PathnamePrefixMatch` object, the field `prefix` will be equivalent to the matched prefix
        pathname and the field `suffix` will be the rest of this pathname, or `None` if the.

        The code
        ```
        PathnamePrefixMatch.prefix.appended_with(PathnamePrefixMatch.suffix)
        ```
        will yield a pathname that is equivalent to the original (this) pathname.
        """

        if self.is_absolute() != prefix.is_absolute():
            return None

        prefix_end_i: int = 0

        prefix_pathname_str: str = str(prefix)
        prefix_pathname_str_i: int = 0

        self_pathname_str: str = str(self)
        self_pathname_str_i: int = 0

        while prefix_pathname_str_i < len(prefix_pathname_str) and self_pathname_str_i < len(self_pathname_str):
            # region next prefix component

            next_prefix_component_range: range | None = _find_next_component_range(
                prefix_pathname_str,
                prefix_pathname_str_i,
            )

            prefix_pathname_str_i = \
                next_prefix_component_range.stop \
                if next_prefix_component_range is not None \
                else len(prefix_pathname_str)

            next_prefix_component_has_trailing_separator: bool = (prefix_pathname_str_i + 1) < len(prefix_pathname_str)

            # endregion

            # region next self component

            next_self_component_range: range | None = _find_next_component_range(
                self_pathname_str,
                self_pathname_str_i,
            )

            self_pathname_str_i = \
                next_self_component_range.stop \
                if next_self_component_range is not None \
                else len(self_pathname_str)

            next_self_component_has_trailing_separator: bool = (self_pathname_str_i + 1) < len(self_pathname_str)

            # endregion

            if next_prefix_component_range is None:
                # end of prefix; successfully matched
                break

            if next_self_component_range is None:
                # component missing in this pathname; failed to match
                return None

            next_prefix_component = PathnameComponent(_str_sub(prefix_pathname_str, next_prefix_component_range))
            next_self_component = PathnameComponent(_str_sub(self_pathname_str, next_self_component_range))

            if next_self_component != next_prefix_component:
                # prefix's and this' pathname component different; failed to match
                return None

            if next_prefix_component_has_trailing_separator and not next_self_component_has_trailing_separator:
                # missing trailing component separator in this pathname; failed to match
                return None

        suffix: Pathname | None = None

        if prefix_end_i > 0:
            suffix = Pathname(self_pathname_str[prefix_end_i:])

        return PathnamePrefixMatch(
            prefix=Pathname(self_pathname_str[0:prefix_end_i]),
            suffix=suffix,
        )

    def startswith(self: Pathname, prefix: Pathname) -> bool:
        """
        Return whether or not this pathname starts with the prefix pathname.

        This pathname starts with the prefix pathname if all of the following conditions are true:

        * The "absoluteness" of both pathnames are the same. i.e.: either both pathnames are absolute or
          both parameters are relative

        * Excluding all `.` components (for both pathnames), the leading components of this pathname matches all
          components of the prefix pathname, both in component value and in the order they appear in.
          Note that this means if the prefix pathname is effectively just `.` will always match this pathname (provided
          it is also relative).

        * If the prefix pathname has either a trailing component separator or a trailing `.` component, then
          this pathname's component that matched the prefix pathname's last non-`.` component must be followed by
          a separator itself.

        Note that the way these conditions are laid out, both pathnames are effectively normalized before they are
        compared.
        A call like
        ```
        Pathname("/foo/./bar//baz").startswith(Pathname("/foo//bar/"))
        ```
        will return `True`.
        """

        if self.is_absolute() != prefix.is_absolute():
            return False

        prefix_pathname_str: str = str(prefix)
        prefix_pathname_str_i: int = 0

        self_pathname_str: str = str(self)
        self_pathname_str_i: int = 0

        while True:
            current_prefix_component: PathnameComponent | None = None
            current_prefix_component_has_trailing_separator: bool = False

            while prefix_pathname_str_i < len(prefix_pathname_str):
                prefix_char: str = prefix_pathname_str[prefix_pathname_str_i]
                prefix_pathname_str_i += 1

                if prefix_char == PathnameComponent.separator and current_prefix_component is not None:
                    if current_prefix_component == PathnameComponent("."):
                        current_prefix_component = None
                        continue

                    current_prefix_component_has_trailing_separator = True
                    break

                if prefix_char != PathnameComponent.separator:
                    current_prefix_component_str: str = ""

                    if current_prefix_component is not None:
                        current_prefix_component_str = str(current_prefix_component)

                    current_prefix_component_str += prefix_char
                    current_prefix_component = PathnameComponent(current_prefix_component_str)

            if current_prefix_component == PathnameComponent("."):
                current_prefix_component = None

            if current_prefix_component is None:
                return True

            current_self_component: PathnameComponent | None = None
            current_self_component_has_trailing_separator: bool = False

            while self_pathname_str_i < len(self_pathname_str):
                self_char: str = self_pathname_str[self_pathname_str_i]
                self_pathname_str_i += 1

                if self_char == PathnameComponent.separator and current_self_component is not None:
                    if current_self_component == PathnameComponent("."):
                        current_self_component = None
                        continue

                    current_self_component_has_trailing_separator = True
                    break

                if self_char != PathnameComponent.separator:
                    current_self_component_str: str = ""

                    if current_self_component is not None:
                        current_self_component_str = str(current_self_component)

                    current_self_component_str += self_char
                    current_self_component = PathnameComponent(current_self_component_str)

            if current_self_component == PathnameComponent("."):
                current_prefix_component = None

            if current_self_component is None:
                return False

            if current_prefix_component != current_self_component:
                return False

            if current_prefix_component_has_trailing_separator and not current_self_component_has_trailing_separator:
                return False

    # def replaceprefix(self, prefix: "Pathname", substitution: "Pathname") -> "Pathname":
    #     self_normalized: Pathname = self.normalized()
    #     prefix_normalized: Pathname = prefix.normalized()

    #     if not (self_normalized.value + "/").startswith(prefix_normalized.value + "/"):
    #         return self

    #     return Pathname(substitution.value + self_normalized.value[len(prefix_normalized.value):])

    def basename(self: Pathname) -> PathnameComponent | None:
        """
        Return the last component (a.k.a.: "basename" or "filename") of this pathname as an instance of
        `PathnameComponent`.
        If this pathname contains no components (i.e.: it is the root pathname), then `None` is returned.
        """

        pathname_str: str = str(self)
        i: int = len(pathname_str) - 1

        while i >= 0 and pathname_str[i] == PathnameComponent.separator:
            i -= 1

        if i < 0:
            return None

        end_i: int = i

        while i >= 0 and pathname_str[i] != PathnameComponent.separator:
            i -= 1

        return PathnameComponent(pathname_str[i + 1:end_i + 1])

    def dirname(self: Pathname) -> Pathname:
        """
        Return this pathname without the last component and no trailing component separator.

        If this pathname is relative and contains only one component, then a relative pathname with just a single `.`
        component and no trailing component separator is returned

        If this pathname contains no components (i.e.: it is the root pathname), then it is returned with no
        modifications.
        """

        analysis: PathnameAnalysisNewNew = self.analyze_new_new()

        if isinstance(analysis.last_element, PathnameAnalysisNewNew.Root):
            return self

        last_component: PathnameAnalysisNewNew.Component

        if isinstance(analysis.last_element, PathnameAnalysisNewNew.Component):
            last_component = analysis.last_element
        else:
            assert isinstance(analysis.last_element, PathnameAnalysisNewNew.TrailingSeparation)
            last_component = analysis.last_element.prev_element

        element = last_component.prev_element

        if element is None:
            return Pathname(".")

        if isinstance(element, PathnameAnalysisNewNew.Root):
            element

        if isinstance(element, PathnameAnalysisNewNew.MiddleSeparation):
            element = element.prev_element

        pathname_str: str = str(self)
        i: int = len(pathname_str) - 1

        while i >= 0 and pathname_str[i] == PathnameComponent.separator:
            i -= 1

        if i < 0:
            return self

        while i >= 0 and pathname_str[i] != PathnameComponent.separator:
            i -= 1

        if i < 0:
            return Pathname(".")

        while i >= 1 and pathname_str[i] == PathnameComponent.separator:
            i -= 1

        return Pathname(pathname_str[0:i + 1])

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

    # def relative_to(self, base_pathname: "Pathname") -> "Pathname":
    #     return Pathname(os.path.relpath(self.value, base_pathname.value))

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

        normalized_pathname_str: str = ""

        for element in self.analyze_new_new():
            if isinstance(element, PathnameAnalysisNewNew.Component):
                normalized_pathname_str += str(element.value)

            if isinstance(element, PathnameAnalysisNewNew.ComponentSeparation):
                normalized_pathname_str += PathnameComponent.separator

        return Pathname(normalized_pathname_str)

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
