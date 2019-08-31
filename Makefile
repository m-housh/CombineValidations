documentation:
	@jazzy \
		-x USE_SWIFT_RESPONSE_FILE=NO \
		--no-hide-documentation-coverage \
		--theme fullwidth \
		--output ./docs \
		--author Michael Housh \
		--title CombineValidations \
		--clean
	@rm -rf build
