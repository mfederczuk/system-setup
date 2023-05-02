# Copyright (c) 2023 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

from dataclasses import dataclass


@dataclass(frozen=True)
class Pathname:

    value: str

    def __post_init__(self):
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
