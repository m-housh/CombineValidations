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

mergeAndPush:
	@git checkout master
	@git merge develop master
	@git push
	@git checkout develop
