.PHONY: all

all:
	swift build
	./.build/debug/curly-cli "http://httpbin.org/headers"
