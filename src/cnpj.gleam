//// A module for creating, parsing, and validating Brazilian CNPJ numbers.
////
//// A CNPJ is a 14-digit number with the format `XX.XXX.XXX/YYYY-ZZ`, where:
//// - `XXXXXXXX` is the base registration number.
//// - `YYYY` is the branch identifier.
//// - `ZZ` are two check digits calculated from the preceding 12 digits.
////
//// This module provides a safe way to construct valid CNPJ objects and
//// format them as strings.

import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

/// A type representing a valid, structured CNPJ.
/// It can only be created via the functions in this module, ensuring that
/// any instance of this type is mathematically correct.
pub opaque type Cnpj {
  Cnpj(base: String, branch: String, check_digits: String)
}

pub fn error_to_string(e: CnpjError) -> String {
  case e {
    InvalidLength -> "Invalid length"
    InvalidFormat -> "Invalid format"
    InvalidCheckDigits -> "Invalid check digits"
    AllSameDigits -> "All same digits"
  }
}

/// A type for errors that can occur during CNPJ creation or parsing.
pub type CnpjError {
  /// The input string has an invalid length (not 14 digits when cleaned).
  InvalidLength
  /// The input contains non-digit characters where digits are expected.
  InvalidFormat
  /// The check digits do not match the calculated ones.
  InvalidCheckDigits
  /// The CNPJ consists of all the same digit, which is considered invalid.
  AllSameDigits
}

// The weights used to calculate the first and second check digits.
const first_digit_weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

const second_digit_weights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

/// Creates a `Cnpj` from its core components: the base and branch numbers.
///
/// This function acts as a builder. It validates the parts, then automatically
/// calculates the correct two check digits to form a valid CNPJ.
///
/// # Arguments
/// - `base`: The first 8 digits of the CNPJ.
/// - `branch`: The 4-digit branch identifier (e.g., "0001" for the main office).
///
/// # Returns
/// A `Result` containing the new `Cnpj` on success, or a `CnpjError` if the
/// input parts have an invalid length or format.
///
/// # Example
/// ```gleam
/// > from_parts("11444777", "0001")
/// Ok(Cnpj("11444777", "0001", "61"))
/// ```
///
/// # Example (Invalid Length)
/// ```gleam
/// > from_parts("123", "0001")
/// Error(InvalidLength)
/// ```
pub fn from_parts(base: String, branch: String) -> Result(Cnpj, CnpjError) {
  case string.length(base) == 8 && string.length(branch) == 4 {
    False -> Error(InvalidLength)
    True -> {
      let twelve_digits = base <> branch
      case string_to_int_list(twelve_digits) {
        Ok(digits) -> {
          let first_digit = calculate_check_digit(digits, first_digit_weights)
          let second_digit =
            calculate_check_digit(
              list.append(digits, [first_digit]),
              second_digit_weights,
            )

          let check_digits =
            int.to_string(first_digit) <> int.to_string(second_digit)

          Ok(Cnpj(base: base, branch: branch, check_digits: check_digits))
        }
        Error(_) -> Error(InvalidFormat)
      }
    }
  }
}

/// Parses a string into a `Cnpj` type.
///
/// The function cleans the input string (removing '.', '/', '-') and then
/// validates its length, format, and check digits.
///
/// # Arguments
/// - `cnpj_string`: A string, which can be formatted (e.g., "11.444.777/0001-61")
///   or unformatted (e.g., "11444777000161").
///
/// # Returns
/// A `Result` containing the `Cnpj` on success, or a `CnpjError` if the
/// string is not a valid CNPJ.
///
/// # Example
/// ```gleam
/// > from_string("11.444.777/0001-61")
/// Ok(Cnpj("11444777", "0001", "61"))
/// ```
///
/// # Example (Invalid Check Digits)
/// ```gleam
/// > from_string("11.444.777/0001-11")
/// Error(InvalidCheckDigits)
/// ```
pub fn from_string(cnpj_string: String) -> Result(Cnpj, CnpjError) {
  let cleaned = clean(cnpj_string)

  case string.length(cleaned) == 14 {
    False -> Error(InvalidLength)
    True ->
      case is_all_same_digits(cleaned) {
        True -> Error(AllSameDigits)
        False ->
          case string_to_int_list(cleaned) {
            Ok(digits) -> {
              let first_12 = list.take(digits, 12)
              let provided_checks = list.drop(digits, 12)

              let calculated_first =
                calculate_check_digit(first_12, first_digit_weights)
              let calculated_second =
                calculate_check_digit(
                  list.append(first_12, [calculated_first]),
                  second_digit_weights,
                )

              let calculated = [calculated_first, calculated_second]

              case calculated == provided_checks {
                True ->
                  Ok(Cnpj(
                    base: string.slice(cleaned, 0, 8),
                    branch: string.slice(cleaned, 8, 4),
                    check_digits: string.slice(cleaned, 12, 2),
                  ))
                False -> Error(InvalidCheckDigits)
              }
            }
            Error(_) -> Error(InvalidFormat)
          }
      }
  }
}

/// Checks if a given string represents a valid CNPJ.
///
/// This is a convenience function that returns `True` if `from_string` succeeds
/// and `False` otherwise.
///
/// # Example
/// ```gleam
/// > is_valid("11.444.777/0001-61")
/// True
///
/// > is_valid("11.111.111/1111-11")
/// False // Invalid due to all same digits
/// ```
pub fn is_valid(cnpj_string: String) -> Bool {
  result.is_ok(from_string(cnpj_string))
}

/// Formats a `Cnpj` into the standard `XX.XXX.XXX/YYYY-ZZ` string format.
///
/// # Example
/// ```gleam
/// let my_cnpj = from_parts("11444777", "0001") |> result.unwrap(or: panic)
/// > to_string(my_cnpj)
/// "11.444.777/0001-61"
/// ```
pub fn to_string(cnpj: Cnpj) -> String {
  let base1 = string.slice(cnpj.base, 0, 2)
  let base2 = string.slice(cnpj.base, 2, 3)
  let base3 = string.slice(cnpj.base, 5, 3)

  base1
  <> "."
  <> base2
  <> "."
  <> base3
  <> "/"
  <> cnpj.branch
  <> "-"
  <> cnpj.check_digits
}

/// Returns the raw, unformatted 14-digit string from a `Cnpj` type.
///
/// # Example
/// ```gleam
/// let my_cnpj = from_parts("11444777", "0001") |> result.unwrap(or: panic)
/// > to_unformatted_string(my_cnpj)
/// "11444777000161"
/// ```
pub fn to_unformatted_string(cnpj: Cnpj) -> String {
  cnpj.base <> cnpj.branch <> cnpj.check_digits
}

//
// PRIVATE HELPERS
//

/// Removes formatting characters from a CNPJ string.
fn clean(value: String) -> String {
  // A simple way to remove chars without regex for this specific case.
  value
  |> string.replace(".", "")
  |> string.replace("/", "")
  |> string.replace("-", "")
}

/// Checks if a string consists of only one repeating digit.
fn is_all_same_digits(value: String) -> Bool {
  let graphemes = string.to_graphemes(value)
  case graphemes {
    [] -> False
    [first, ..rest] -> list.all(rest, fn(g) { g == first })
  }
}

/// Converts a string of digits into a list of integers.
fn string_to_int_list(s: String) -> Result(List(Int), Nil) {
  s
  |> string.to_graphemes
  |> list.try_map(int.parse)
}

/// Calculates a single check digit based on a list of digits and weights.
/// This implements the core modulus 11 algorithm for CNPJ.
fn calculate_check_digit(digits: List(Int), weights: List(Int)) -> Int {
  let sum =
    list.map2(digits, weights, fn(d, w) { d * w })
    |> int.sum

  let remainder = sum % 11

  case remainder < 2 {
    True -> 0
    False -> 11 - remainder
  }
}
