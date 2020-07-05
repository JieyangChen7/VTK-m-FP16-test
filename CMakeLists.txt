cmake_minimum_required(VERSION 3.3...3.12 FATAL_ERROR)
project(VTKmDemo CXX)

SET(VTKm_DIR /ccs/home/jieyang/opt/vtkm-dev-fp16/lib/cmake/vtkm-1.4)
find_package(VTKm REQUIRED)

#add_executable(vtkm_fp16_test vtkm_fp16_test.cu)
#add_executable(vtkm_fp16_2_test vtkm_fp16_2_test.cu)

#target_link_libraries(vtkm_fp16_test PRIVATE vtkm_cont vtkm_filter vtkm_rendering)
#target_link_libraries(vtkm_fp16_2_test PRIVATE vtkm_cont vtkm_filter vtkm_rendering)

add_executable(square_filter_test_fp16 square_filter_test.cu)
target_link_libraries(square_filter_test_fp16 PRIVATE vtkm_cont vtkm_filter vtkm_rendering)
set_target_properties(square_filter_test_fp16 PROPERTIES COMPILE_FLAGS "-DFP16")

add_executable(square_filter_test_fp16_2 square_filter_test.cu)
target_link_libraries(square_filter_test_fp16_2 PRIVATE vtkm_cont vtkm_filter vtkm_rendering)
set_target_properties(square_filter_test_fp16_2 PROPERTIES COMPILE_FLAGS "-DFP16_2")

add_executable(square_filter_test_fp32 square_filter_test.cu)
target_link_libraries(square_filter_test_fp32 PRIVATE vtkm_cont vtkm_filter vtkm_rendering)
set_target_properties(square_filter_test_fp32 PROPERTIES COMPILE_FLAGS "-DFP32")

add_executable(square_filter_test_fp64 square_filter_test.cu)
target_link_libraries(square_filter_test_fp64 PRIVATE vtkm_cont vtkm_filter vtkm_rendering)
set_target_properties(square_filter_test_fp64 PROPERTIES COMPILE_FLAGS "-DFP64")
