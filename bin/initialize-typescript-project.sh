#! /bin/bash

if [[ $# -ne 1 ]]; then
  echo "provide the name of the directory to create a typescript/node project in"
  exit 127
fi

directory=$1
mkdir "$directory"
cd "$directory" || exit
npm create -y

# Install basics
npm install --save-dev typescript ts-node ts-node-dev
# Install support for testing
npm install --save-dev jest ts-jest

# Install linting
npm install --save-dev --save-exact eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Install beautification
npm install --save-dev --save-exact prettier eslint-config-prettier
# Install types
npm install --save-dev @types/node @types/jest

# Add scripts
npx npm-add-script \
  -k "start-dev" \
  -v "npx ts-node-dev --respawn --pretty --transpile-only src/index.ts" \
  --force

npx npm-add-script \
  -k "test" \
  -v "npx jest" \
  --force

npx npm-add-script \
  -k "prettier" \
  -v "npx prettier . --write" \
  --force

npx npm-add-script \
  -k "lint" \
  -v "npx eslint ." \
  --force


mkdir src
mkdir tests
mkdir .vscode

cat << EOF > jest.config.js
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
};
EOF

cat << EOF > tsconfig.json
{
  "compilerOptions": {
    "esModuleInterop": true,
    "module": "commonjs",
    "moduleResolution": "node",
    "noImplicitAny": true,
    "outDir": "dist",
    "sourceMap": true,
    "strict": true,
    "target": "es6"
  },
  "lib": ["es2015"]
}
EOF

cat << EOF > .eslintrc.js
module.exports = {
  env: {
    es2022: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier",
  ],
  ignorePatterns: ["dist", "build"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  plugins: ["@typescript-eslint"],
  rules: {},
};
EOF

cat << EOF > src/main.ts
export function _(input: number[]): number[] {
  return [];
}
EOF

cat << EOF > tests/test.ts
import { describe, expect, test } from "@jest/globals";
import { _ } from "../src/main";

describe("tests should pass", () => {
  test("one", () => {
    const inputOne: number[] = [];
    const expectedOutput: number[] = [];
    const outputOne = _(inputOne);
    expect(outputOne).toEqual(expectedOutput);
  });

  test("two", () => {
    const inputTwo: number[] = [];
    const expectedOutput: number[] = [];
    const outputTwo = _(inputTwo);
    expect(outputTwo).toEqual(expectedOutput);
  });
});
EOF

# cat << EOF > .vscode/settings.json
# {
#     "python.testing.pytestArgs": [
#         "tests"
#     ],
#     "python.testing.unittestEnabled": false,
#     "python.testing.pytestEnabled": true
# }
# EOF