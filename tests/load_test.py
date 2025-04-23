# Copyright 2025 Dirk Pranke. All rights reserved.
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

import unittest

from floyd_datafile import loads


class LoadTest(unittest.TestCase):
    def check(self, s, obj):
        self.assertEqual(loads(s), obj)

    def test_true(self):
        self.check('true', True)

    def test_false(self):
        self.check('false', False)

    def test_null(self):
        self.check('null', None)

    def test_number(self):
        self.check('4', 4)
        # self.check('4_1', 41)
        # self.check('4.1', 4.1)
        # self.check('4e2', 400)
        # self.check('4.1e2', 410)
        # self.check('0b11', 3)
        # self.check('0xa0', 160)
        # self.check('0xa0_b0', 41136)
        # self.check('0o12', 10)
        # self.check('-4', -4)
        # self.check('+4', +4)

    def test_array(self):
        self.check('[]', [])
        self.check('[1]', [1])
        self.check('[foo]', ['foo'])
        self.check('["foo"]', ['foo'])
        self.check('[1 2]', [1, 2])
        self.check('[1, 2]', [1, 2])
        # self.check('[1, 2,]', [1, 2])

    def test_object(self):
        self.check('{}', {})
        self.check('{foo: bar}', {'foo': 'bar'})
        self.check('{foo: bar baz: quux}', {'foo': 'bar', 'baz': 'quux'})
        # self.check('{f: 1, g: 2}', {'f': 1, 'g': 2})
        self.check('{"foo": 1}', {'foo': 1})

    def test_str(self):
        self.check('"foo"', 'foo')
        self.check("'foo'", 'foo')
        self.check('`foo`', 'foo')
        self.check('"""foo"""', 'foo')
        self.check("'''foo'''", 'foo')
        # self.check('```foo```', 'foo')
        # self.check("L'='foo'='", 'foo')
        # self.check("L'=='foo'=='", 'foo')

    def test_bare_word(self):
        self.check('foo', 'foo')
        self.check('@foo', '@foo')


if __name__ == '__main__':
    unittest.main()
