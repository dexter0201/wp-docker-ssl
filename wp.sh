#!/bin/bash

sudo `which docker` exec -u www-data $1 wp $@
