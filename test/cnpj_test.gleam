import cnpj
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn from_parts_valid_checks_and_formatting_test() {
  // 8 digits - base company identifier 
  let base = "12345678"
  // 4 digits - branch company identifier
  let branch = "0001"

  // The remaining 2 digits (check digits) are calculated based on the base/branch identifiers
  let assert Ok(doc) = cnpj.from_parts(base, branch)

  // Usual formatting implemented in to_string()
  cnpj.to_string(doc)
  |> should.equal("12.345.678/0001-95")

  // Unformatted string has a separate implementation since it's less common
  cnpj.to_unformatted_string(doc)
  |> should.equal("12345678000195")
}

pub fn from_parts_base_invalid_length_test() {
  let invalid_length_bases = [
    "",
    "1",
    "1234567",
    "123456789",
  ]

  list.each(invalid_length_bases, fn(invalid_length_base) {
    cnpj.from_parts(invalid_length_base, "0001")
    |> should.be_error
    |> should.equal(cnpj.InvalidLength)
  })
}

pub fn from_parts_base_invalid_characters_test() {
  let invalid_characters_bases = [
    "@1234567",
    "A1234567",
    "a1234567",
    "1234567a",
    "1234567@",
    "/1234567",
    "1234567/",
    ".1234567",
    "1234567.",
    "-1234567",
    "1234567-",
    "*1234567",
    "1234567*",
    "&1234567",
    "1234567&",
    "#1234567",
    "1234567#",
    "😁2345678",
    "1234567😁",
  ]

  list.each(invalid_characters_bases, fn(invalid_characters_base) {
    cnpj.from_parts(invalid_characters_base, "0001")
    |> should.be_error
    |> should.equal(cnpj.InvalidFormat)
  })
}

pub fn from_parts_branch_invalid_length_test() {
  let invalid_length_branches = [
    "",
    "1",
    "000",
    "00012",
  ]

  list.each(invalid_length_branches, fn(invalid_branch) {
    cnpj.from_parts("12345678", invalid_branch)
    |> should.be_error
    |> should.equal(cnpj.InvalidLength)
  })
}

pub fn from_parts_branch_invalid_characters_test() {
  let invalid_characters_branches = [
    "@001",
    "A001",
    "000A",
    "001@",
    "/001",
    "001/",
    ".001",
    "001.",
    "-001",
    "001-",
    "*001",
    "001*",
    "&001",
    "001&",
    "#001",
    "001#",
    "😁001",
    "001😁",
  ]

  list.each(invalid_characters_branches, fn(invalid_characters_branch) {
    cnpj.from_parts("12345678", invalid_characters_branch)
    |> should.be_error
    |> should.equal(cnpj.InvalidFormat)
  })
}

pub fn from_string_parses_formatted_test() {
  cnpj.from_string("12.345.678/0001-95")
  |> should.be_ok
  |> cnpj.to_unformatted_string
  |> should.equal("12345678000195")
}

pub fn from_string_parses_unformatted_test() {
  let assert Ok(doc) = cnpj.from_string("12345678000195")
  cnpj.to_string(doc)
  |> should.equal("12.345.678/0001-95")
}

pub fn from_string_invalid_length_test() {
  let invalid_length_strings = [
    "",
    "1",
    "12",
    "123",
    "1234",
    "12345",
    "123456",
    "1234567",
    "12345678",
    "123456789",
    "1234567890",
    "12345678901",
    "114447770001623",
    "1144477700016234",
    "11444777000162345",
  ]

  list.each(invalid_length_strings, fn(invalid_length_string) {
    cnpj.from_string(invalid_length_string)
    |> should.be_error
    |> should.equal(cnpj.InvalidLength)
  })
}

pub fn from_string_invalid_check_digits_test() {
  let invalid_check_digits_strings = [
    "12.345.678/0001-42",
    "12.345.678/0001-00",
    "12.345.678/0001-52",
    "12.345.678/0001-23",
    "12.345.678/0001-07",
  ]

  list.each(invalid_check_digits_strings, fn(invalid_check_digits_string) {
    cnpj.from_string(invalid_check_digits_string)
    |> should.be_error
    |> should.equal(cnpj.InvalidCheckDigits)
  })
}

pub fn from_string_all_same_digits_is_rejected_test() {
  cnpj.from_string("11.111.111/1111-11")
  |> should.be_error
  |> should.equal(cnpj.AllSameDigits)
}

pub fn from_string_invalid_format_letters_test() {
  cnpj.from_string("11.444.777/0001-6A")
  |> should.be_error
  |> should.equal(cnpj.InvalidFormat)
}

pub fn is_valid_convenience_test() {
  cnpj.is_valid("12.345.678/0001-95")
  |> should.equal(True)

  cnpj.is_valid("12.345.678/0001-96")
  |> should.equal(False)

  cnpj.is_valid("11.111.111/1111-11")
  |> should.equal(False)
}
