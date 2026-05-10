#!/usr/bin/env python
# -*- python -*-
# vim: syntax=python

# Copyright (c) 2026 Michael Federczuk
# SPDX-License-Identifier: MPL-2.0 AND Apache-2.0

import array
import hashlib
import os
import sys
from abc import abstractmethod
from os import DirEntry
from pathlib import Path
from typing import Protocol

BytesLike = bytes | bytearray | array.array | memoryview
"""https://docs.python.org/3.13/glossary.html#term-bytes-like-object"""


class _Hash(Protocol):
	"""https://docs.python.org/3.13/library/hashlib.html#hash-objects"""

	@abstractmethod
	def update(self, data: BytesLike, /) -> None:
		raise NotImplementedError

	@abstractmethod
	def digest(self, /) -> bytes:
		raise NotImplementedError


def _main() -> int:
	if len(sys.argv) <= 1:
		print(f"{sys.argv[0]}: missing arguments: <directory>...", file=sys.stderr)
		return 2

	arg: str
	for arg in sys.argv[1:]:
		digest: bytes
		try:
			digest = _digest_dir_sha1(arg)
		except FileNotFoundError as e:
			print(f"{sys.argv[0]}: no such directory: {e.filename}", file=sys.stderr)
			return 1
		except NotADirectoryError as e:
			print(f"{sys.argv[0]}: not a directory: {e.filename}", file=sys.stderr)
			return 1

		if not arg.endswith("/"):
			arg += "/"

		print(f"{digest.hex()} {arg}")

	return 0


def _digest_dir_sha1(dir_path: Path | str) -> bytes | None:
	hash_object: _Hash = hashlib.sha1()

	_update_hash_with_dir_data_recursively(dir_path, hash_object)

	return hash_object.digest()


def _update_hash_with_dir_data_recursively(dir_path: Path | str, hash_object: _Hash) -> None:
	with os.scandir(dir_path) as iterator:
		entry: DirEntry[str]
		for entry in sorted(iterator, key=lambda unsorted_entry: unsorted_entry.name):
			_update_hash_with_dir_entry_data(entry, hash_object)


def _update_hash_with_dir_entry_data(entry: DirEntry[str], hash_object: _Hash) -> None:
	hash_object.update(entry.name.encode(encoding="utf-8"))

	if entry.is_symlink():
		symlink_contents: str = os.readlink(entry.path)
		hash_object.update(b"symlink")
		hash_object.update(symlink_contents.encode(encoding="utf-8"))
		return

	if entry.is_dir():
		hash_object.update(b"directory")
		_update_hash_with_dir_data_recursively(entry.path, hash_object)
		return

	if entry.is_file():
		hash_object.update(b"regular_file")
		size: int = _update_hash_with_file(entry.path, hash_object)
		hash_object.update(str(size).encode(encoding="utf-8"))
		return

	if entry.is_junction():
		hash_object.update(b"junction")
		return

	hash_object.update(b"unknown")


def _update_hash_with_file(file_path: Path | str, hash_object: _Hash) -> int:
	sum_size: int = 0

	# Adapted from hashlib.file_digest()

	buffer = bytearray(2 ** 18)
	view = memoryview(buffer)

	with open(file_path, mode="rb") as file:
		while True:
			read_size: int = file.readinto(buffer)

			if read_size == 0:
				return sum_size

			hash_object.update(view[:read_size])
			sum_size += read_size


if __name__ == "__main__":
	sys.exit(_main())
