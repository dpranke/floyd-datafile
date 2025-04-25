# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest


class Host:
    def __init__(self):
        self.stdin = sys.stdin
        self.stdout = sys.stdout
        self.stderr = sys.stderr

    def chdir(self, *comps):
        return os.chdir(self.join(*comps))

    def getcwd(self):
        return os.getcwd()

    def join(self, *comps):
        return os.path.join(*comps)

    def mkdtemp(self, **kwargs):
        return tempfile.mkdtemp(**kwargs)

    def print(self, msg='', end='\n', file=None):
        file = file or self.stdout
        file.write(str(msg) + end)
        file.flush()

    def rmtree(self, path):
        shutil.rmtree(path, ignore_errors=True)

    def read_text_file(self, path):
        with open(path, 'rb') as fp:
            return fp.read().decode('utf8')

    def write_text_file(self, path, contents):
        with open(path, 'wb') as f:
            f.write(contents.encode('utf8'))


class FakeHost:
    python_interpreter = 'python'

    def __init__(self):
        self.stdin = io.StringIO()
        self.stdout = io.StringIO()
        self.stderr = io.StringIO()
        self.platform = 'linux2'
        self.sep = '/'
        self.dirs = set([])
        self.files = {}
        self.written_files = {}
        self.last_tmpdir = None
        self.current_tmpno = 0
        self.cwd = '/tmp'

    def abspath(self, *comps):
        relpath = self.join(*comps)
        if relpath.startswith('/'):
            return relpath
        return self.join(self.cwd, relpath)

    def chdir(self, *comps):  # pragma: no cover
        path = self.join(*comps)
        if not path.startswith('/'):
            path = self.join(self.cwd, path)
        self.cwd = path

    def dirname(self, path):
        return '/'.join(path.split('/')[:-1])

    def getcwd(self):
        return self.cwd

    def join(self, *comps):  # pragma: no cover
        p = ''
        for c in comps:
            if c in ('', '.'):
                continue
            if c.startswith('/'):
                p = c
            elif p:
                p += '/' + c
            else:
                p = c

        # Handle ./
        p = p.replace('/./', '/')

        # Handle ../
        while '/..' in p:
            comps = p.split('/')
            idx = comps.index('..')
            comps = comps[: idx - 1] + comps[idx + 1 :]
            p = '/'.join(comps)
        return p

    def maybe_mkdir(self, *comps):  # pragma: no cover
        path = self.abspath(self.join(*comps))
        if path not in self.dirs:
            self.dirs.add(path)

    # We use `dir` as an argument name to mirror tempfile.mkdtemp.
    # pylint: disable=redefined-builtin
    def mkdtemp(self, suffix='', prefix='tmp', dir=None, **_kwargs):
        if dir is None:
            dir = self.sep + '__im_tmp'
        else:  # pragma: no cover
            pass
        curno = self.current_tmpno
        self.current_tmpno += 1
        self.last_tmpdir = self.join(dir, f'{prefix}_{curno}_{suffix}')
        self.dirs.add(self.last_tmpdir)
        return self.last_tmpdir

    # pylint: enable=redefined-builtin

    def print(self, msg='', end='\n', file=None):
        file = file or self.stdout
        file.write(msg + end)
        file.flush()

    def read_text_file(self, *comps):
        return self._read(comps)

    def _read(self, comps):
        return self.files[self.abspath(*comps)]

    def remove(self, *comps):
        path = self.abspath(*comps)
        self.files[path] = None
        self.written_files[path] = None

    def rmtree(self, *comps):
        path = self.abspath(*comps)
        for f in self.files:
            if f.startswith(path):
                self.remove(f)
            else:  # pragma: no cover
                pass
        self.dirs.remove(path)

    def write_text_file(self, path, contents):
        self._write(path, contents)

    def _write(self, path, contents):
        full_path = self.abspath(path)
        self.maybe_mkdir(self.dirname(full_path))
        self.files[full_path] = contents
        self.written_files[full_path] = contents


class _BaseTestCase(unittest.TestCase):
    maxDiff = None
    host_fn = None

    def call(self, h, args, stdin):
        raise NotImplementedError

    def check(
        self, args, stdin=None, files=None, returncode=0, out=None, err=None
    ):
        self.assertIsNotNone(self.host_fn, 'self.host_fn is not defined')
        h = self.host_fn()
        orig_wd = h.getcwd()
        tmpdir = None

        try:
            tmpdir = h.mkdtemp()
            h.chdir(tmpdir)
            if files and files.items():
                for path, contents in files.items():
                    h.write_text_file(path, contents)

            actual_ret, actual_out, actual_err = self.call(h, args, stdin)
            if returncode is not None:
                self.assertEqual(returncode, actual_ret)
            if out is not None:
                self.assertMultiLineEqual(out, actual_out)
            if err is not None:
                self.assertMultiLineEqual(err, actual_err)
            return actual_ret, actual_out, actual_err
        finally:
            if tmpdir:
                h.rmtree(tmpdir)
                h.chdir(orig_wd)


class InlineTestCase(_BaseTestCase):
    host_fn = FakeHost
    main = None

    def call(self, host, args, stdin):
        self.assertIsNotNone(self.__class__.main, '__class__.main is not set')
        if stdin:
            host.stdin.write(stdin)
            host.stdin.seek(0)

        try:
            actual_ret = self.__class__.main(args, host)
        except SystemExit as e:
            actual_ret = e.code

        return actual_ret, host.stdout.getvalue(), host.stderr.getvalue()


class HostTestCase(_BaseTestCase):
    host_fn = Host
    outside_venv = False

    def exe_args(self):
        raise NotImplementedError

    def exe_env(self):
        if self.outside_venv and sys.prefix != sys.base_prefix:
            return env
        return None

    def call(self, host, args, stdin):
        del host
        if 'integration' in os.environ.get('TYP_SKIP', ''):
            self.skipTest('skipping integration test by request')

        cmd = self.exe_args() + args
        env = None
        if self.outside_venv and sys.prefix != sys.base_prefix:
            env = os.environ.copy()
            del env['VIRTUAL_ENV']

        with subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            encoding='utf-8',
            env=env,
        ) as proc:
            actual_out, actual_err = proc.communicate(input=stdin)
            actual_ret = proc.returncode
        return actual_ret, actual_out, actual_err


class ModuleTestCase(HostTestCase):
    module = None

    def exe_args(self):
        self.assertIsNotNone(self.module, 'self.module is not set')
        return [sys.executable, '-m', self.module]


class ScriptTestCase(HostTestCase):
    script = None
    outside_venv = False

    def exe_args(self):
        self.assertIsNotNone(self.script, 'self.script is not set')
        if os.path.exists(self.script):
            if self.outside_venv and sys.prefix != sys.base_prefix:
                return [sys._base_executable, self.script]
            return [sys.executable, self.script]
        script = shutil.which(self.script)
        self.assertIsNotNone(
            script, 'Could not find `%s` in PATH' % self.script
        )
        return [script]


if __name__ == '__main__':  # pragma: no cover
    unittest.main()
