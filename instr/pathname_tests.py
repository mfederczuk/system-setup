# SPDX-License-Identifier: CC0-1.0

from pathname import Pathname, PathnameComponent

# region PathnameComponent

# region __init__

try:
    PathnameComponent("")
    assert False
except ValueError:
    pass

try:
    PathnameComponent("foo\0bar")
    assert False
except ValueError:
    pass

try:
    PathnameComponent(f"foo{PathnameComponent.separator}bar")
    assert False
except ValueError:
    pass

# endregion

# region __eq__

assert PathnameComponent("foobar") == PathnameComponent("foobar")
assert PathnameComponent("component with spaces") == PathnameComponent("component with spaces")

# endregion

# region __str__

assert str(PathnameComponent("foo")) == "foo"

assert str(PathnameComponent("yee haw, 'pardner")) == "yee haw, 'pardner"

# endregion

# endregion

# region Pathname

# region __init__

try:
    Pathname("")
    assert False
except ValueError:
    pass

try:
    Pathname("foo/\0bar")
    assert False
except ValueError:
    pass

# endregion

# region __eq__

assert Pathname("foo/bar") == Pathname("foo/bar")
assert Pathname("/x") == Pathname("/x")

assert Pathname("a//b/c//") == Pathname("a//b/c//")
assert Pathname("z/./x") == Pathname("z/./x")

assert Pathname("foo//bar") != Pathname("foo/bar")
assert Pathname("///./x//") != Pathname("/x/")

# endregion

# region __str__

assert str(Pathname("foo")) == "foo"

assert str(Pathname("/yee/.//haw///")) == "/yee/.//haw///"

# endregion

# region is_{absolute,relative}

assert Pathname("/foo/bar").is_absolute()
assert not Pathname("x/y/z").is_absolute()

assert Pathname("abc").is_relative()
assert not Pathname("/a/b/c").is_relative()

# endregion

# region startswith

assert Pathname("foo/bar").startswith(Pathname("foo"))
assert Pathname("foo/").startswith(Pathname("foo"))
assert Pathname("foo").startswith(Pathname("foo"))
assert not Pathname("foo-bar").startswith(Pathname("foo"))
assert not Pathname("/foo").startswith(Pathname("foo"))
assert not Pathname("bar/foo").startswith(Pathname("foo"))

assert Pathname("/bar/baz").startswith(Pathname("/bar"))
assert Pathname("/bar").startswith(Pathname("/bar"))
assert Pathname("/bar/bar/bar").startswith(Pathname("/bar"))
assert not Pathname("bar").startswith(Pathname("/bar"))
assert not Pathname("/bar_x").startswith(Pathname("/bar"))
assert not Pathname("bar/").startswith(Pathname("/bar"))

assert Pathname("baz/").startswith(Pathname("baz/"))
assert Pathname("baz/yeehaw").startswith(Pathname("baz/"))
assert not Pathname("/baz").startswith(Pathname("baz/"))
assert not Pathname("/baz/").startswith(Pathname("baz/"))

assert Pathname("yee/haw").startswith(Pathname("yee/haw"))
assert Pathname("yee/haw/x").startswith(Pathname("yee/haw"))
assert not Pathname("/yee/haw").startswith(Pathname("yee/haw"))

assert Pathname("foo/x/asd").startswith(Pathname("foo///./x//asd"))
assert Pathname("foo/./x/asd").startswith(Pathname("foo///./x//asd"))

assert Pathname("x/").startswith(Pathname("x/."))
assert not Pathname("x").startswith(Pathname("x/."))

assert Pathname(".").startswith(Pathname("."))
assert Pathname("x").startswith(Pathname("."))
assert Pathname("./asd/").startswith(Pathname("."))
assert not Pathname("/").startswith(Pathname("."))
assert not Pathname("/./foo/bar").startswith(Pathname("."))

# assert Pathname("")

# endregion

# region basename

assert Pathname("foo").basename() == PathnameComponent("foo")
assert Pathname("/foo/").basename() == PathnameComponent("foo")
assert Pathname("/foo/.").basename() == PathnameComponent(".")
assert Pathname("/foo/.//").basename() == PathnameComponent(".")
assert Pathname("//.//").basename() == PathnameComponent(".")
assert Pathname("///").basename() is None

# endregion

# region dirname

assert Pathname("foo/bar").dirname() == Pathname("foo")
assert Pathname("//foo/bar//").dirname() == Pathname("//foo")
assert Pathname("foo/./bar").dirname() == Pathname("foo/.")

assert Pathname("foo").dirname() == Pathname(".")
assert Pathname("bar/").dirname() == Pathname(".")

assert Pathname("/").dirname() == Pathname("/")
assert Pathname("///").dirname() == Pathname("///")

# endregion

# region appended_with

assert Pathname("yee").appended_with(PathnameComponent("haw")) == Pathname("yee/haw")
assert Pathname("x").appended_with(PathnameComponent("y"), PathnameComponent("z")) == Pathname("x/y/z")
assert Pathname("asd/").appended_with(PathnameComponent("abc")) == Pathname("asd/abc")
assert Pathname("///a/b//").appended_with(PathnameComponent("c")) == Pathname("///a/b//c")

assert Pathname("foo").appended_with(Pathname("bar")) == Pathname("foo/bar")
assert Pathname("foo/bar/").appended_with(Pathname("yee"), Pathname("haw/a")) == Pathname("foo/bar/yee/haw/a")
assert Pathname("./").appended_with(Pathname("/x")) == Pathname("./x")
assert Pathname("bar//").appended_with(Pathname("/baz")) == Pathname("bar//baz")
assert Pathname("foo////").appended_with(Pathname("///x")) == Pathname("foo//////x")

# endregion

# region normalized

assert Pathname("x//y/z").normalized() == Pathname("x/y/z")
assert Pathname("///foo//bar/baz///").normalized() == Pathname("/foo/bar/baz/")
assert Pathname("////////////////////").normalized() == Pathname("/")

assert Pathname("/./a/b").normalized() == Pathname("/a/b")
assert Pathname("no/one/./expects/././the/spanish/./inquisition").normalized() == \
    Pathname("no/one/expects/the/spanish/inquisition")

assert Pathname("./././.").normalized() == Pathname(".")
assert Pathname(".///.//././/").normalized() == Pathname(".")
assert Pathname("/././/.///").normalized() == Pathname("/")

assert Pathname("foo/bar/.").normalized() == Pathname("foo/bar/")
assert Pathname("/z/y/./z/./.").normalized() == Pathname("/z/y/z/")

assert Pathname("yee/../haw").normalized() == Pathname("yee/../haw")
assert Pathname("/foo///..//../bar//").normalized() == Pathname("/foo/../../bar/")

# endregion

# region create_relative_of_component

assert Pathname.create_relative_of_component(PathnameComponent("foo")) == Pathname("foo")

assert Pathname.create_relative_of_component(PathnameComponent("yee haw")) == Pathname("yee haw")

# endregion

# region create_normalized

assert Pathname.create_normalized("x//y/z") == Pathname("x/y/z")
assert Pathname.create_normalized("///foo//bar/baz///") == Pathname("/foo/bar/baz/")
assert Pathname.create_normalized("////////////////////") == Pathname("/")

assert Pathname.create_normalized("/./a/b") == Pathname("/a/b")
assert Pathname.create_normalized("no/one/./expects/././the/spanish/./inquisition") == \
    Pathname("no/one/expects/the/spanish/inquisition")

assert Pathname.create_normalized("./././.") == Pathname(".")
assert Pathname.create_normalized(".///.//././/") == Pathname(".")
assert Pathname.create_normalized("/././/.///") == Pathname("/")

assert Pathname.create_normalized("foo/bar/.") == Pathname("foo/bar/")
assert Pathname.create_normalized("/z/y/./z/./.") == Pathname("/z/y/z/")

assert Pathname.create_normalized("yee/../haw") == Pathname("yee/../haw")
assert Pathname.create_normalized("/foo///..//../bar//") == Pathname("/foo/../../bar/")

# endregion

# endregion
