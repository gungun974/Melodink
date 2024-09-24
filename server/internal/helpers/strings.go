package helpers

import "strings"

func IsEmptyOrWhitespace(s string) bool {
	return len(strings.TrimSpace(s)) == 0
}

func RemoveEmptyStrings(input []string) []string {
	result := make([]string, 0, len(input))
	for _, str := range input {
		if !IsEmptyOrWhitespace(str) {
			result = append(result, str)
		}
	}
	return result
}
