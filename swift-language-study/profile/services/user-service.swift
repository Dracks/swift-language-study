import Foundation

class HasLength: ValidatorCheck {
	var length: Int
	var error: String
	init(_ _length: Int) {
		length = _length
		error = "It should have \(_length) characters minimum"
	}

	func check(_ data: String) -> Bool {
		return data.count >= length
	}
}

class CheckLowerCase: ValidatorCheck {

	var error = "It should contain lower case letters"
	func check(_ data: String) -> Bool {
		return data.rangeOfCharacter(from: .lowercaseLetters) != nil
	}
}

class CheckUpperCase: ValidatorCheck {

	var error = "It should contain upper case letters"
	func check(_ data: String) -> Bool {
		return data.rangeOfCharacter(from: .uppercaseLetters) != nil
	}
}

class CheckNumbers: ValidatorCheck {

	var error = "It should contain numbers"
	func check(_ data: String) -> Bool {
		return data.rangeOfCharacter(from: .decimalDigits) != nil
	}
}

class CheckRegex: ValidatorCheck {
	var regex: Regex<AnyRegexOutput>
	var error: String

	init(regex: Regex<AnyRegexOutput>, error: String) {
		self.regex = regex
		self.error = error
	}

	func check(_ data: String) -> Bool {
		if let _ = data.wholeMatch(of: regex) {
			return true
		}
		return false
	}
}

class UserService {
	// var checkPassword: (_ pwd: String) -> [String]
	var emailValidator: Validator<String, String>
	var passwordValidator: Validator<String, String>

	init() {

		passwordValidator = Validator<String, String>(validations: [
			HasLength(8),
			CheckLowerCase(),
			CheckUpperCase(),
			CheckNumbers(),
		])

		emailValidator = Validator(validations: [
			HasLength(4),
			CheckRegex(
				regex: try! Regex("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"),
				error: "Should be a valid e-mail"),
		])
	}

	func checkPassword(_ pwd: String) -> [String] {
		return passwordValidator.validate(pwd)
	}

	func checkEmail(_ email: String) -> [String] {
		return emailValidator.validate(email)
	}

}
