# donim

donno in Nim.

## Usage

`dn -h`.

## Develop

```
nimble init donim
cd donim
mkdir tests
# add Nim source files in src/
# and optional test files "test-*.nim" in tests/
nimble test
nimble build -d:release
nimble install
```
