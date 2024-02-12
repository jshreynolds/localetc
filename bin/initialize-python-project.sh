#! /bin/bash

if [[ $# -ne 1 ]]; then
  echo "Provide a project name/directory to create"
  exit 127
fi

directory=lc$1
poetry new "$directory"
cd "$directory" || exit
mkdir .vscode
poetry add --group dev pytest
touch tests/test_it.py

cat << EOF > "$directory"/__init__.py
from typing import List

EOF

cat << EOF > tests/test_it.py
from $directory import Solution

sln = Solution()

def test_solution():
  pass

EOF

cat << EOF > .vscode/settings.json
{
    "python.testing.pytestArgs": [
        "tests"
    ],
    "python.testing.unittestEnabled": false,
    "python.testing.pytestEnabled": true
}
EOF