# PledgeProof Terraform Automation

.PHONY: zip-lambda

# Rebuild Lambda code.zip from handler.py (run before pushing changes to handler.py)
zip-lambda:
	@cd lambda && zip -j code.zip code/handler.py
	@echo "Done. lambda/code.zip updated."
