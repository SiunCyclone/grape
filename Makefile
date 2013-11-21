docs:
	rdmd $(HOME)/.dub/packages/linkdoc-master/app.d \
		--import=~/.dub/packages/derelict-master/import/

.PHONY: docs

