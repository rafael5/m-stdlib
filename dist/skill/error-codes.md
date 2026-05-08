# m-stdlib — error codes

m-stdlib v0.5.0; 43 error codes across 14 modules.

Inverted index over the manifest's `@raises` arrays. Every
`,U-STDxxx-NAME,` code an m-stdlib label sets via `set $ecode=`
is listed with the labels that raise it. For an `$ETRAP` handler
that needs to disambiguate sources, this is the lookup table.

## `STDARGS`

- **`U-STDARGS-MISSING-POSITIONAL`** — raised by: `parse`
- **`U-STDARGS-MISSING-VALUE`** — raised by: `parse`
- **`U-STDARGS-UNKNOWN-ACTION`** — raised by: `addflag`
- **`U-STDARGS-UNKNOWN-FLAG`** — raised by: `parse`
- **`U-STDARGS-UNKNOWN-SUBCOMMAND`** — raised by: `parse`

## `STDCOMPRESS`

- **`U-STDCOMPRESS-BAD-LEVEL`** — raised by: `gzip`, `deflate`, `zstdCompress`
- **`U-STDCOMPRESS-CALLOUT-MISSING`** — raised by: `gzip`, `gunzip`, `deflate`, `inflate`, `zstdCompress`, `zstdDecompress`
- **`U-STDCOMPRESS-LIBZ-FAIL`** — raised by: `gzip`, `gunzip`, `deflate`, `inflate`
- **`U-STDCOMPRESS-LIBZSTD-FAIL`** — raised by: `zstdCompress`, `zstdDecompress`

## `STDCRYPTO`

- **`U-STDCRYPTO-CALLOUT-MISSING`** — raised by: `sha256`, `sha384`, `sha512`, `sha256Bytes`, `sha384Bytes`, `sha512Bytes`, `hmacSha256`, `hmacSha384`, `hmacSha512`, `hmacSha256Bytes`, `hmacSha384Bytes`, `hmacSha512Bytes`
- **`U-STDCRYPTO-DIGEST-FAIL`** — raised by: `sha256`, `sha384`, `sha512`, `sha256Bytes`, `sha384Bytes`, `sha512Bytes`
- **`U-STDCRYPTO-HMAC-FAIL`** — raised by: `hmacSha256`, `hmacSha384`, `hmacSha512`, `hmacSha256Bytes`, `hmacSha384Bytes`, `hmacSha512Bytes`

## `STDCSPRNG`

- **`U-STDCSPRNG-BAD-COUNT`** — raised by: `bytes`, `hex`, `base64`, `token`
- **`U-STDCSPRNG-BAD-RANGE`** — raised by: `int`
- **`U-STDCSPRNG-OPEN-FAIL`** — raised by: `bytes`

## `STDCSV`

- **`U-STDCSV-OPEN-FAIL`** — raised by: `parseFile`, `writeFile`

## `STDDATE`

- **`U-STDDATE-BAD-DUR`** — raised by: `add`
- **`U-STDDATE-BAD-HOROLOG`** — raised by: `fromh`, `strftime`, `add`
- **`U-STDDATE-BAD-ISO`** — raised by: `toh`, `strptime`

## `STDENV`

- **`U-STDFS-OPEN-FAIL`** — raised by: `parseFile`, `readFile`, `writeFile`, `append`, `readLines`, `writeLines`, `writeBytes`, `appendBytes`, `readBytes`, `save`, `asserts`

## `STDFIX`

- **`U-STDFIX-EMPTY-TAG`** — raised by: `with`, `register`
- **`U-STDFIX-UNREGISTERED-TAG`** — raised by: `invoke`

## `STDFMT`

- **`U-STDFMT-MISSING-ARG`** — raised by: `f`, `fn`
- **`U-STDFMT-UNCLOSED-BRACE`** — raised by: `f`, `fn`
- **`U-STDFMT-UNESCAPED-RBRACE`** — raised by: `f`, `fn`
- **`U-STDFMT-UNKNOWN-TYPE`** — raised by: `f`, `fn`

## `STDFS`

- **`U-STDFS-NOT-WIRED`** — raised by: `writeBytes`, `appendBytes`, `readBytes`
- **`U-STDFS-READ-TRUNCATED`** — raised by: `readBytes`
- **`U-STDFS-REMOVE-FAIL`** — raised by: `remove`

## `STDJSON`

- **`U-STDJSON-ENCODE`** — raised by: `encode`, `writeFile`
- **`U-STDJSON-PARSE`** — raised by: `parse`, `parseFile`

## `STDLOG`

- **`U-STDLOG-INVALID-FORMAT`** — raised by: `FORMAT`
- **`U-STDLOG-INVALID-LEVEL`** — raised by: `LEVEL`
- **`U-STDLOG-INVALID-SINK`** — raised by: `SINK`

## `STDREGEX`

- **`U-STDREGEX-BAD-PATTERN`** — raised by: `compile`
- **`U-STDREGEX-NO-MATCH`** — raised by: `groups`
- **`U-STDREGEX-UNSUPPORTED`** — raised by: `compile`

## `STDSEED`

- **`U-STDSEED-FILE-NOT-FOUND`** — raised by: `load`, `validate`
- **`U-STDSEED-FILER-ERROR`** — raised by: `load`, `loadJson`
- **`U-STDSEED-INVALID-JSON`** — raised by: `loadJson`
- **`U-STDSEED-INVALID-MANIFEST`** — raised by: `loadJson`
- **`U-STDSEED-MISSING-FIELD`** — raised by: `load`, `validate`
- **`U-STDSEED-MISSING-FILE`** — raised by: `load`, `validate`, `loadJson`

