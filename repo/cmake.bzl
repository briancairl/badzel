"""
MIT License

Copyright (c) 2018 Brian Cairl

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

load(":make.bzl", "make_this_new_http_archive_attrs", "make_cc_library")


def _merge_attrs(lhs, rhs):
    u = {}
    u.update(lhs)
    u.update(rhs)
    return u


def _cmake_this_new_http_archive_impl(ctx):
    # Download + extract archive
    ctx.download_and_extract(
        url=ctx.attr.url,
        sha256=ctx.attr.sha256,
        stripPrefix=ctx.attr.strip_prefix,
        output='',
        type=ctx.attr.downloaded_type, # auto detect compression type
    )

    build_path = str(ctx.path('.'))

    # Build
    commands = [["cmake", build_path] + ctx.attr.cmake_options, "make"]
    make_cc_library(ctx=ctx, commands=commands)


cmake_this_new_http_archive = repository_rule(
    implementation=_cmake_this_new_http_archive_impl,
    local=True,
    attrs=_merge_attrs(
        make_this_new_http_archive_attrs,
        {"cmake_options": attr.string_list(default=["-DCMAKE_BUILD_TYPE=Release", "-DBUILD_SHARED_LIBS:bool=ON"]),}
    )
)
"""
Downloads a Bazel repository as a compressed archive file, decompresses it,
configures build with CMake, builds under make, and makes its targets available for binding.

It supports the following file extensions: `"zip"`, `"jar"`, `"war"`, `"tar"`,
`"tar.gz"`, `"tgz"`, `"tar.xz"`, and `tar.bz2`.

Requires that cmake and make are installed on the host system.
"""
