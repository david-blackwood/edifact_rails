# Changelog

## 2.0.0 (18/06/2024)

* Added support for ANSIX12 format.

##### Breaking changes:
* `#una_special_characters` renamed to `#special_characters` (since it can now accept input of any supported format)
* New `UnrecognizedFormat` Error will now be thrown if the format of the input can not be detected.
    * In essence, input must begin now with `UNA` or `UNB` (EDIFACT), `STX` (TRADACOMS), or `ISA` (ANSIX12)

## 1.2.1 (4/06/2024)

* `#una_special_characters` method now also returns decimal notation character, default `.`.
* `#una_special_characters` method can now take no arguments, and will return the default special characters if so.

## 1.2.0 (31/05/2024)

* Added support for UNA segments. Special characters different from the defaults can now be used.
* Added `#una_special_characters` method that returns just the special characters.

## 1.1.1 (4/05/2023)

* Fixed crash caused by running the gem in a production environment.

## 1.1.0 (27/04/2023)

* Added support for TRADACOMS input

## 1.0.0 (26/04/2023)

* Initial release









