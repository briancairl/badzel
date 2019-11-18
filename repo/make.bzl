"""
MIT License

Copyright (c) 2019 Brian Cairl

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

make_this_new_http_archive_attrs={
    "url": attr.string(mandatory=True),
    "sha256": attr.string(mandatory=True),
    "make_prefixes": attr.string_list(default=[]),
    "strip_prefix": attr.string(mandatory=True),
    "deps": attr.string_list(default=[]),
    "copts": attr.string_list(default=[]),
    "data_patterns": attr.string_list(default=[]),
    "include_patterns": attr.string_list(default=[]),
    "sources_patterns": attr.string_list(default=[]),
    "include_prefix": attr.string(default=""),
    "strip_include_prefix": attr.string(default=""),
    "downloaded_type": attr.string(default=""),
    "build_timeout": attr.int(default=600),
    "verbose": attr.int(default=0),
}



def make_cc_library(ctx, commands):
    _CC_LIBRARY_BUILD =\
"""
cc_library(
    name = "{name}",
    data = [] if not {data_patterns} else glob([','.join({data_patterns})]),
    hdrs = [] if not {include_patterns} else glob([','.join({include_patterns})]),
    srcs = [] if not {sources_patterns} else glob([','.join({sources_patterns})]),
    strip_include_prefix = "{strip_include_prefix}",
    include_prefix = "{include_prefix}",
    copts = [{copts_concat}],
    deps = [{deps_concat}],
    visibility = [
        "//visibility:public"
    ],
)
"""
    build_path = str(ctx.path('.'))
    print(build_path)

    # Build
    for cmd in commands:
        ctx.execute(
            [cmd] if type(cmd) == type("") else cmd,
            timeout=ctx.attr.build_timeout,
            quiet=False,
            working_directory=build_path
        )

    deps_concat = ""
    for d in ctx.attr.deps :
        deps_concat += ", '%s'" % (d)

    copts_concat = ""
    for d in ctx.attr.copts :
        copts_concat += ", '%s'" % (d)

    # Create bazel build contents
    build_file_content = _CC_LIBRARY_BUILD.format(
        name=ctx.attr.name,
        data_patterns=ctx.attr.data_patterns,
        include_patterns=ctx.attr.include_patterns,
        sources_patterns=ctx.attr.sources_patterns,
        strip_include_prefix=ctx.attr.strip_include_prefix,
        include_prefix=ctx.attr.include_prefix,
        copts_concat=copts_concat,
        deps_concat=deps_concat
    )

    # Create build file
    bash_exe = ctx.os.environ["BAZEL_SH"] if "BAZEL_SH" in ctx.os.environ else "bash"
    ctx.execute([bash_exe, "-c", "rm -f BUILD.bazel"])
    ctx.file("BUILD.bazel", build_file_content)


def _make_this_new_http_archive_impl(ctx):
    # Download + extract archive
    ctx.download_and_extract(
        url=ctx.attr.url,
        sha256=ctx.attr.sha256,
        stripPrefix=ctx.attr.strip_prefix,
        output='',
        type=ctx.attr.downloaded_type, # auto detect compression type
    )

    # Build
    make_cc_library(ctx=ctx, commands=ctx.attr.make_prefixes + ["make"])


make_this_new_http_archive = repository_rule(
    implementation=_make_this_new_http_archive_impl,
    local=True,
    attrs=make_this_new_http_archive_attrs
)
"""
Downloads a Bazel repository as a compressed archive file, builds under make, and makes its
targets available for binding.

It supports the following file extensions: `"zip"`, `"jar"`, `"war"`, `"tar"`,
`"tar.gz"`, `"tgz"`, `"tar.xz"`, and `tar.bz2`.

Requires that cmake and make are installed on the host system.
"""
