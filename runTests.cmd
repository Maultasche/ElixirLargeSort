@echo off

echo Running largesort_shared tests
cd largesort_shared
call mix test
cd ..
echo.
echo Running int_gen tests
cd int_gen
call mix test
cd ..
echo.
echo Running int_sort tests
cd int_sort
call mix test
cd ..