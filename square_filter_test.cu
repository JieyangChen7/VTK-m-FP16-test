#include <vtkm/Types.h>
#include <vtkm/cont/DataSet.h>
#include <vtkm/cont/DataSetBuilderUniform.h>
#include <vtkm/worklet/Invoker.h>
#include <vtkm/cont/VariantArrayHandle.h>
#include <vtkm/worklet/WorkletMapField.h>
#include <vtkm/worklet/DispatcherMapField.h>
#include <vtkm/cont/DataSetFieldAdd.h>
#include <vtkm/filter/FilterField.h>
#include <vtkm/cont/ArrayHandle.h>
#include <iostream>
#include <vtkm/filter/internal/CreateResult.h> 
#include <vtkm/cont/Initialize.h>
#include <string>
#include <iomanip>
#include <stdlib.h> 
#include <vtkm/cont/Field.h>
#include "square_filter_fp16.h"
#include "square_filter_fp16_2.h"
#include "square_filter_fp32.h"
#include "square_filter_fp64.h"
#include <chrono> 
#define E 0.1


int main(int argc, char *argv[]) {
  vtkm::cont::InitializeOptions options =vtkm::cont::InitializeOptions::AddHelp;  
  vtkm::cont::Initialize(argc, argv, options);

  int n = atoi(argv[1]);

  vtkm::cont::DataSet inputDataSet, outputDataSet;
  vtkm::cont::DataSetBuilderUniform dataSetBuilder;
  vtkm::cont::DataSetFieldAdd dsf;

  vtkm::Id3 dims(n, n, n);
  vtkm::Id3 org(0, 0, 0);
  vtkm::Id3 spc(1, 1, 1);

  vtkm::Int64 N = n * n * n;

  std::vector<float> init_data(N);
  for (vtkm::Int64 i = 0; i < N; i++)
    init_data[i] = 1.0;//((float) rand() / (RAND_MAX)); 

#if defined FP16
  std::cout << "Running in FP16" << std::endl;
  std::vector<vtkm::Float16> data(N);
  vtkm::cont::ArrayHandle<vtkm::Float16> fieldData;
  vtkm::filter::FilterFieldSquareFP16 filter;
  vtkm::filter::PolicyFP16DataSet policy;
  vtkm::cont::ArrayHandle<vtkm::Float16> output;
  for (vtkm::Int64 i = 0; i < N; i++)
    data[i] = (float)init_data[i];
#elif defined FP16_2
  std::cout << "Running in FP16_2" << std::endl;
  std::vector<vtkm::Float16_2> data(N);
  vtkm::cont::ArrayHandle<vtkm::Float16_2> fieldData;
  vtkm::filter::FilterFieldSquareFP16_2 filter;
  vtkm::filter::PolicyFP16_2DataSet policy;
  vtkm::cont::ArrayHandle<vtkm::Float16_2> output;
  for (int i = 0; i < N; i++)
    data[i] = vtkm::Float16_2((float)init_data[i], (float)init_data[i]);
#elif defined FP32
  std::cout << "Running in FP32" << std::endl;
  std::vector<vtkm::Float32> data(N);
  vtkm::cont::ArrayHandle<vtkm::Float32> fieldData;
  vtkm::filter::FilterFieldSquareFP32 filter;
  vtkm::filter::PolicyFP32DataSet policy;
  vtkm::cont::ArrayHandle<vtkm::Float32> output;
  for (int i = 0; i < N; i++)
    data[i] = (float)init_data[i];
#elif defined FP64
  std::cout << "Running in FP64" << std::endl;
  std::vector<vtkm::Float64> data(N);
  vtkm::cont::ArrayHandle<vtkm::Float64> fieldData;
  vtkm::filter::FilterFieldSquareFP64 filter;
  vtkm::filter::PolicyFP64DataSet policy;
  vtkm::cont::ArrayHandle<vtkm::Float64> output;
  for (int i = 0; i < N; i++)
    data[i] = (double)init_data[i];
#endif

  fieldData = vtkm::cont::make_ArrayHandle(data);

  std::string fieldName = "test_field";
  inputDataSet = dataSetBuilder.Create(dims, org, spc);      
  dsf.AddPointField(inputDataSet, fieldName, fieldData);

  filter.SetActiveField(fieldName);
  auto start = std::chrono::high_resolution_clock::now();
  fieldData.PrepareForInPlace(vtkm::cont::DeviceAdapterTagCuda());
  auto finish = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double> elapsed = finish - start;
  std::cout << "Elapsed time: " << elapsed.count() << " s\n";
   
  outputDataSet = filter.Execute(inputDataSet, policy);
  outputDataSet = filter.Execute(inputDataSet, policy);
  outputDataSet = filter.Execute(inputDataSet, policy);
  
  //outputDataSet = fp16_filter.Execute(inputDataSet);
  start = std::chrono::high_resolution_clock::now();
  outputDataSet = filter.Execute(inputDataSet, policy);
  finish = std::chrono::high_resolution_clock::now();
  elapsed = finish - start;
  std::cout << "Elapsed time: " << elapsed.count() << " s\n";

  //std::cout << "Gflops: " << ((double)N/1e-9)/elapsed.count() << " s\n";
#if defined FP16_2
  std::cout << "Gflops: " << ((double)N*2/1e9)/elapsed.count() << " s\n";
#else
  std::cout << "Gflops: " << ((double)N/1e9)/elapsed.count() << "\n";
#endif
/*
  vtkm::cont::Field f = outputDataSet.GetField(fieldName+"_squared");
  vtkm::cont::VariantArrayHandle vah = f.GetData();
    
  vah.CopyTo(output);
  //std::cout << "Output: ";
  bool isCurrect = true;
  for (vtkm::Int64 i = 0; i < N; i++) {
    //std::cout << output.GetPortalConstControl().Get(i) << ", ";
#if defined FP16   
    if (fabs(i*i - output.GetPortalConstControl().Get(i).to_float()) > E)
#elif defined FP16_2
    if (fabs((float)i*i - output.GetPortalConstControl().Get(i).to_float_low()) > E ||
        fabs((float)i*i - output.GetPortalConstControl().Get(i).to_float_high()) > E)
#elif defined FP32
    if (fabs((float)i*i - output.GetPortalConstControl().Get(i)) > E)
#elif defined FP64
    if (fabs((double)i*i - output.GetPortalConstControl().Get(i)) > E)
#endif

    {
      std::cout << std::setprecision(10) << std::fixed;
      std::cout << "i = " << init_data[i] << std::endl;
      std::cout << "(float)i*i = " << (float)init_data[i]*init_data[i] << std::endl;
      std::cout << "PF = " << output.GetPortalConstControl().Get(i).to_float() << std::endl;
      isCurrect = false;
    }
  }
  if (isCurrect) std::cout << "Passed" << std::endl;
  else std::cout << "Failed" << std::endl;
  //std::cout << isCurrect ? "Passed":"Failed" << std::endl;
*/

}
