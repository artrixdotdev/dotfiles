#!/usr/bin/env python3

import argparse
import hashlib
import re
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from OpenGL import EGL
from OpenGL import GL


VERTEX_SHADER = """#version 300 es
precision highp float;

const vec2 POSITIONS[3] = vec2[](
    vec2(-1.0, -1.0),
    vec2( 3.0, -1.0),
    vec2(-1.0,  3.0)
);

void main() {
    gl_Position = vec4(POSITIONS[gl_VertexID], 0.0, 1.0);
}
"""


BUILTIN_UNIFORMS = [
    ("iTime", "uniform float iTime;\n"),
    ("iResolution", "uniform vec3 iResolution;\n"),
    ("iMouse", "uniform vec4 iMouse;\n"),
    ("iFrame", "uniform int iFrame;\n"),
    ("iTimeDelta", "uniform float iTimeDelta;\n"),
    ("iFrameRate", "uniform float iFrameRate;\n"),
    ("iDate", "uniform vec4 iDate;\n"),
    ("iSampleRate", "uniform float iSampleRate;\n"),
    ("iChannel0", "uniform sampler2D iChannel0;\n"),
    ("iChannel1", "uniform sampler2D iChannel1;\n"),
    ("iChannel2", "uniform sampler2D iChannel2;\n"),
    ("iChannel3", "uniform sampler2D iChannel3;\n"),
    ("iChannelResolution", "uniform vec3 iChannelResolution[4];\n"),
    ("iChannelTime", "uniform float iChannelTime[4];\n"),
]


def build_fragment_shader(shader_source: str) -> str:
    if shader_source.count("void mainImage") != 1:
        raise ValueError("Only single-pass shaders with exactly one mainImage are supported")

    source = re.sub(r"^\s*#version\s+.+$", "", shader_source, flags=re.MULTILINE)
    source = re.sub(r"\bgl_FragColor\b", "fragColor", source)

    uniform_block = []
    for name, declaration in BUILTIN_UNIFORMS:
        if not re.search(rf"\b(?:uniform|const)\s+\w+(?:\s*\[\d+\])?\s+{re.escape(name)}\b", source):
            uniform_block.append(declaration)

    if not re.search(r"\bout\s+vec4\s+fragColor\s*;", source):
        uniform_block.append("out vec4 fragColor;\n")

    prefix = (
        "#version 300 es\n"
        "precision highp float;\n"
        "precision highp int;\n"
        "#define texture2D texture\n"
        "#define textureCube texture\n"
        + "".join(uniform_block)
        + "\n"
    )
    suffix = ""
    if not re.search(r"\bvoid\s+main\s*\(", source):
        suffix = "\nvoid main() {\n    mainImage(fragColor, gl_FragCoord.xy);\n}\n"
    return prefix + source + suffix


def compile_shader(shader_type: int, source: str) -> int:
    shader = GL.glCreateShader(shader_type)
    GL.glShaderSource(shader, source)
    GL.glCompileShader(shader)
    status = GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS)
    if not status:
        info = GL.glGetShaderInfoLog(shader).decode("utf-8", errors="replace")
        raise RuntimeError(info)
    return shader


def link_program(vertex_source: str, fragment_source: str) -> int:
    vertex = compile_shader(GL.GL_VERTEX_SHADER, vertex_source)
    fragment = compile_shader(GL.GL_FRAGMENT_SHADER, fragment_source)
    program = GL.glCreateProgram()
    GL.glAttachShader(program, vertex)
    GL.glAttachShader(program, fragment)
    GL.glLinkProgram(program)
    status = GL.glGetProgramiv(program, GL.GL_LINK_STATUS)
    GL.glDeleteShader(vertex)
    GL.glDeleteShader(fragment)
    if not status:
        info = GL.glGetProgramInfoLog(program).decode("utf-8", errors="replace")
        raise RuntimeError(info)
    return program


def get_uniform_types(program: int) -> dict[str, int]:
    result: dict[str, int] = {}
    count = GL.glGetProgramiv(program, GL.GL_ACTIVE_UNIFORMS)
    for index in range(count):
        name, _, uniform_type = GL.glGetActiveUniform(program, index)
        if isinstance(name, bytes):
            name = name.decode("utf-8", errors="replace")
        result[name] = uniform_type
    return result


class EglContext:
    def __init__(self):
        self.display = None
        self.context = None

    def __enter__(self):
        # The sync service has no drawable Wayland surface. Mesa's surfaceless
        # EGL platform provides a real off-screen GLES context for rendering
        # previews and DMS theme images. The default display is retained as a
        # fallback for non-Mesa/desktop environments.
        surfaceless_platform = 0x31DD  # EGL_PLATFORM_SURFACELESS_MESA
        try:
            self.display = EGL.eglGetPlatformDisplay(
                surfaceless_platform,
                EGL.EGL_DEFAULT_DISPLAY,
                None,
            )
        except Exception:
            self.display = EGL.EGL_NO_DISPLAY

        if self.display == EGL.EGL_NO_DISPLAY:
            self.display = EGL.eglGetDisplay(EGL.EGL_DEFAULT_DISPLAY)
        if self.display == EGL.EGL_NO_DISPLAY:
            raise RuntimeError("eglGetDisplay failed")

        major, minor = EGL.EGLint(), EGL.EGLint()
        if not EGL.eglInitialize(self.display, major, minor):
            raise RuntimeError("eglInitialize failed")

        if not EGL.eglBindAPI(EGL.EGL_OPENGL_ES_API):
            raise RuntimeError("eglBindAPI(OpenGL ES) failed")

        context_attribs = [
            EGL.EGL_CONTEXT_CLIENT_VERSION, 3,
            EGL.EGL_NONE,
        ]
        self.context = EGL.eglCreateContext(
            self.display,
            None,
            EGL.EGL_NO_CONTEXT,
            context_attribs,
        )
        if self.context == EGL.EGL_NO_CONTEXT:
            raise RuntimeError("eglCreateContext failed")

        if not EGL.eglMakeCurrent(self.display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, self.context):
            raise RuntimeError("eglMakeCurrent failed")

        return self

    def __exit__(self, exc_type, exc, tb):
        if self.display:
            EGL.eglMakeCurrent(
                self.display,
                EGL.EGL_NO_SURFACE,
                EGL.EGL_NO_SURFACE,
                EGL.EGL_NO_CONTEXT,
            )
        if self.context and self.display:
            EGL.eglDestroyContext(self.display, self.context)
        if self.display:
            EGL.eglTerminate(self.display)


def bind_black_textures(program: int):
    pixel = np.zeros((1, 1, 4), dtype=np.uint8)
    for unit in range(4):
        texture = GL.glGenTextures(1)
        GL.glActiveTexture(GL.GL_TEXTURE0 + unit)
        GL.glBindTexture(GL.GL_TEXTURE_2D, texture)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_EDGE)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_EDGE)
        GL.glTexImage2D(
            GL.GL_TEXTURE_2D,
            0,
            GL.GL_RGBA8,
            1,
            1,
            0,
            GL.GL_RGBA,
            GL.GL_UNSIGNED_BYTE,
            pixel,
        )
        location = GL.glGetUniformLocation(program, f"iChannel{unit}")
        if location >= 0:
            GL.glUniform1i(location, unit)


def set_uniform(program: int, uniform_types: dict[str, int], name: str, *values):
    location = GL.glGetUniformLocation(program, name)
    if location < 0:
        return

    uniform_type = uniform_types.get(name)
    if uniform_type == GL.GL_FLOAT:
        GL.glUniform1f(location, float(values[0]))
    elif uniform_type == GL.GL_FLOAT_VEC2:
        GL.glUniform2f(location, float(values[0]), float(values[1]))
    elif uniform_type == GL.GL_FLOAT_VEC3:
        GL.glUniform3f(location, float(values[0]), float(values[1]), float(values[2]))
    elif uniform_type == GL.GL_FLOAT_VEC4:
        GL.glUniform4f(location, float(values[0]), float(values[1]), float(values[2]), float(values[3]))
    elif uniform_type in (GL.GL_INT, GL.GL_SAMPLER_2D):
        GL.glUniform1i(location, int(values[0]))
    else:
        if len(values) == 1:
            GL.glUniform1f(location, float(values[0]))
        elif len(values) == 2:
            GL.glUniform2f(location, float(values[0]), float(values[1]))
        elif len(values) == 3:
            GL.glUniform3f(location, float(values[0]), float(values[1]), float(values[2]))
        elif len(values) == 4:
            GL.glUniform4f(location, float(values[0]), float(values[1]), float(values[2]), float(values[3]))


def render_shader(shader_path: Path, output_path: Path, width: int, height: int, shader_time: float):
    source = shader_path.read_text(encoding="utf-8", errors="replace")
    fragment = build_fragment_shader(source)

    with EglContext():
        framebuffer = GL.glGenFramebuffers(1)
        GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, framebuffer)

        color = GL.glGenTextures(1)
        GL.glBindTexture(GL.GL_TEXTURE_2D, color)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_S, GL.GL_CLAMP_TO_EDGE)
        GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_WRAP_T, GL.GL_CLAMP_TO_EDGE)
        GL.glTexImage2D(
            GL.GL_TEXTURE_2D,
            0,
            GL.GL_RGBA8,
            width,
            height,
            0,
            GL.GL_RGBA,
            GL.GL_UNSIGNED_BYTE,
            None,
        )
        GL.glFramebufferTexture2D(
            GL.GL_FRAMEBUFFER,
            GL.GL_COLOR_ATTACHMENT0,
            GL.GL_TEXTURE_2D,
            color,
            0,
        )

        status = GL.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER)
        if status != GL.GL_FRAMEBUFFER_COMPLETE:
            raise RuntimeError(f"framebuffer incomplete: 0x{status:x}")

        GL.glViewport(0, 0, width, height)
        GL.glDisable(GL.GL_BLEND)
        GL.glDisable(GL.GL_DEPTH_TEST)
        program = link_program(VERTEX_SHADER, fragment)
        vao = GL.glGenVertexArrays(1)
        GL.glBindVertexArray(vao)
        GL.glUseProgram(program)

        uniform_types = get_uniform_types(program)
        bind_black_textures(program)
        set_uniform(program, uniform_types, "iTime", shader_time)
        set_uniform(program, uniform_types, "iTimeDelta", 1.0 / 60.0)
        set_uniform(program, uniform_types, "iFrameRate", 60.0)
        set_uniform(program, uniform_types, "iFrame", 0)
        set_uniform(program, uniform_types, "iResolution", width, height, 1.0)
        set_uniform(program, uniform_types, "iMouse", 0.0, 0.0, 0.0, 0.0)
        set_uniform(program, uniform_types, "iDate", 2026.0, 1.0, 1.0, 0.0)
        set_uniform(program, uniform_types, "iSampleRate", 44100.0)

        channel_res = GL.glGetUniformLocation(program, "iChannelResolution")
        if channel_res >= 0:
            GL.glUniform3fv(channel_res, 4, np.zeros((4, 3), dtype=np.float32))

        channel_time = GL.glGetUniformLocation(program, "iChannelTime")
        if channel_time >= 0:
            GL.glUniform1fv(channel_time, 4, np.zeros((4,), dtype=np.float32))

        GL.glClearColor(0.0, 0.0, 0.0, 1.0)
        GL.glClear(GL.GL_COLOR_BUFFER_BIT)
        GL.glDrawArrays(GL.GL_TRIANGLES, 0, 3)
        GL.glFinish()

        pixels = np.empty((height, width, 4), dtype=np.uint8)
        GL.glPixelStorei(GL.GL_PACK_ALIGNMENT, 1)
        GL.glReadPixels(0, 0, width, height, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, pixels)

        image = Image.fromarray(np.flipud(pixels), mode="RGBA")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(output_path)

        GL.glDeleteVertexArrays(1, [vao])
        GL.glDeleteProgram(program)
        GL.glDeleteTextures([color])
        GL.glDeleteFramebuffers(1, [framebuffer])


def cache_key(shader_path: Path, width: int, height: int, shader_time: float) -> str:
    digest = hashlib.sha256()
    # Bump when the rendering backend changes. This prevents frames produced by
    # the old/default-display EGL path from surviving a renderer fix.
    digest.update(b"neowall-renderer-v2-surfaceless-egl\0")
    digest.update(str(shader_path.resolve()).encode("utf-8"))
    digest.update(str(shader_path.stat().st_mtime_ns).encode("utf-8"))
    digest.update(f"{width}x{height}@{shader_time:.3f}".encode("utf-8"))
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--shader", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--time", type=float, default=15.0)
    parser.add_argument("--speed", type=float, default=1.0)
    parser.add_argument("--cache-dir")
    args = parser.parse_args()

    shader_path = Path(args.shader).expanduser().resolve()
    output_path = Path(args.output).expanduser()
    shader_time = args.time * args.speed

    if not shader_path.exists():
        raise SystemExit(f"shader not found: {shader_path}")

    if args.cache_dir:
        cache_dir = Path(args.cache_dir).expanduser()
        cache_dir.mkdir(parents=True, exist_ok=True)
        cached = cache_dir / f"{cache_key(shader_path, args.width, args.height, shader_time)}.png"
        if cached.exists():
            output_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(cached, output_path)
            print(cached)
            return 0
    else:
        cached = None

    try:
        render_shader(shader_path, output_path, args.width, args.height, shader_time)
    except Exception as exc:
        raise SystemExit(f"render failed: {exc}")

    if cached is not None:
        shutil.copy2(output_path, cached)
        print(cached)

    return 0


if __name__ == "__main__":
    sys.exit(main())
