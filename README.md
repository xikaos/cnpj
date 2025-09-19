# cnpj

[![Package Version](https://img.shields.io/hexpm/v/cnpj)](https://hex.pm/packages/cnpj)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cnpj/)

A tiny Gleam library for creating, parsing, and validating Brazilian CNPJ numbers.

- **Create** valid CNPJ values from base and branch parts (check digits auto-calculated)
- **Parse** formatted or unformatted strings safely into an opaque `Cnpj` type
- **Validate** using the official modulus 11 algorithm and reject all-same-digit inputs
- **Format** as `XX.XXX.XXX/YYYY-ZZ` or as a 14-digit unformatted string

## Install

```sh
gleam add cnpj@1
```

## Quick start

```gleam
import cnpj
import gleam/result

// Parse from a formatted string
let parsed = cnpj.from_string("12.345.678/0001-95")
case parsed {
  Ok(doc) -> {
    // Pretty format
    cnpj.to_string(doc)               // "12.345.678/0001-95"
    // Raw 14 digits
    cnpj.to_unformatted_string(doc)   // "12345678000195"
  }
  Error(err) -> {
    // Convert error to a human-readable message if needed
    cnpj.error_to_string(err)
  }
}

// Quick validity check
cnpj.is_valid("12.345.678/0001-95")   // True
cnpj.is_valid("11.111.111/1111-11")   // False

// Build from parts (check digits are computed for you)
let built = cnpj.from_parts("12345678", "0001")
case built {
  Ok(doc) -> cnpj.to_string(doc)               // "12.345.678/0001-95"
  Error(_) -> Nil
}
```

## API

- `from_string(cnpj_string: String) -> Result(Cnpj, CnpjError)`
  - Accepts formatted (e.g. `"11.444.777/0001-61"`) or unformatted (`"11444777000161"`).
- `from_parts(base: String, branch: String) -> Result(Cnpj, CnpjError)`
  - Validates an 8-digit base and a 4-digit branch, then computes check digits.
- `is_valid(cnpj_string: String) -> Bool`
  - Convenience wrapper around `from_string`.
- `to_string(cnpj: Cnpj) -> String`
  - Formats as `XX.XXX.XXX/YYYY-ZZ`.
- `to_unformatted_string(cnpj: Cnpj) -> String`
  - Returns the raw 14-digit string.
- `error_to_string(e: CnpjError) -> String`
  - Maps errors like `InvalidLength`, `InvalidFormat`, `InvalidCheckDigits`, `AllSameDigits` to messages.

See full docs on HexDocs: <https://hexdocs.pm/cnpj>.

## Development

- Run tests

```sh
gleam test
```

- Format code

```sh
gleam format
```

- Build documentation locally

```sh
gleam docs build
```

## Notes

- The `Cnpj` type is opaque. Construct values via the provided functions to ensure validity.
- Inputs with all identical digits (e.g. `"11.111.111/1111-11"`) are rejected.
