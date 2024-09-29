package helpers

func CheckAndReplaceEmptyString(a *string, b string, onlyReplaceWhenEmpty bool) {
	if IsEmptyOrWhitespace(b) {
		return
	}

	if IsEmptyOrWhitespace(*a) || !onlyReplaceWhenEmpty {
		*a = b
	}
}

func CheckAndReplaceEmptyInt(a *int, b int, onlyReplaceWhenEmpty bool) {
	if b == 0 {
		return
	}

	if *a == 0 || !onlyReplaceWhenEmpty {
		*a = b
	}
}
