.PHONY: default

default: run

run:
	dart main.dart

dep_install:
	pub get
