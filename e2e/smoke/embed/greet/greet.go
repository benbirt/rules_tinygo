// Package greet is a local dependency of the embed smoke test.
package greet

import "github.com/google/uuid"

// Greeting returns a greeting that proves a third-party dependency linked.
func Greeting() string {
	return "hello from " + uuid.NameSpaceDNS.String()
}
