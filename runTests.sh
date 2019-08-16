#!/bin/bash

echo Running largesort_shared tests
cd largesort_shared
mix test
cd ..
echo
echo Running int_gen tests
cd int_gen
mix test
cd ..
echo
echo Running int_sort tests
cd int_sort
mix test
cd ..