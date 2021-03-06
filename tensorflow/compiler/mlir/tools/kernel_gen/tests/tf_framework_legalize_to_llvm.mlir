// RUN: kernel-gen-opt %s -tf-kernel-to-llvm -split-input-file | FileCheck %s

// CHECK: llvm.func @_mlir_ciface_tf_alloc_raw
// CHECK-SAME:  (!llvm.ptr<i8>, !llvm.i64) -> !llvm.ptr<i8>

// CHECK-LABEL: llvm.func @alloc_raw(
// CHECK-SAME:    [[TF_CTX:%.*]]: !llvm.ptr<i8>,
// CHECK-SAME:    [[SIZE_0:%.*]]: !llvm.i64,
// CHECK-SAME:    [[SIZE_2:%.*]]: !llvm.i64) -> [[DESC_TY:!.*]] {
func @alloc_raw(%ctx: !tf_framework.op_kernel_context,
                %size_0 : index , %size_2 : index) -> memref<?x10x?xf32> {
  %buf = tf_framework.alloc_raw(%ctx, %size_0, %size_2) : memref<?x10x?xf32>
  std.return %buf : memref<?x10x?xf32>
}
// Compute number of elements.
// CHECK: [[SIZE_1:%.*]] = llvm.mlir.constant(10 : index) : !llvm.i64
// CHECK: [[NUM_ELEM_0:%.*]] = llvm.mul [[SIZE_0]], [[SIZE_1]] : !llvm.i64
// CHECK: [[NUM_ELEM_1:%.*]] = llvm.mul [[NUM_ELEM_0]], [[SIZE_2]] : !llvm.i64

// Compute the size of an individual element.
// CHECK: [[NULL:%.*]] = llvm.mlir.null : !llvm.ptr<float>
// CHECK: [[C1:%.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK: [[GEP:%.*]] = llvm.getelementptr [[NULL]]{{\[}}[[C1]]]
// CHECK-SAME:            (!llvm.ptr<float>, !llvm.i64) -> !llvm.ptr<float>
// CHECK: [[SIZE_OF_FLOAT:%.*]] = llvm.ptrtoint [[GEP]]
// CHECK-SAME:            !llvm.ptr<float> to !llvm.i64

// Allocate memory.
// CHECK: [[NUM_BYTES:%.*]] = llvm.mul [[NUM_ELEM_1]], [[SIZE_OF_FLOAT]]
// CHECK: [[BYTES_PTR:%.*]] = llvm.call @{{.*}}([[TF_CTX]], [[NUM_BYTES]])
// CHECK-SAME:                  (!llvm.ptr<i8>, !llvm.i64) -> !llvm.ptr<i8>

// Build memref descriptor.
// CHECK: [[DESC_0:%.*]] = llvm.mlir.undef : [[DESC_TY]]

// Set pointers and offset.
// CHECK: [[FLOAT_PTR:%.*]] = llvm.bitcast [[BYTES_PTR]]
// CHECK-SAME:                  !llvm.ptr<i8> to !llvm.ptr<float>
// CHECK: [[DESC_1:%.*]] = llvm.insertvalue [[FLOAT_PTR]], [[DESC_0]][0]
// CHECK: [[DESC_2:%.*]] = llvm.insertvalue [[FLOAT_PTR]], [[DESC_1]][1]
// CHECK: [[C0:%.*]] = llvm.mlir.constant(0 : index) : !llvm.i64
// CHECK: [[DESC_3:%.*]] = llvm.insertvalue [[C0]], [[DESC_2]][2] : [[DESC_TY]]

// Set sizes and strides.
// CHECK: [[STRIDE_2:%.*]] = llvm.mlir.constant(1 : index) : !llvm.i64
// CHECK: [[DESC_4:%.*]] = llvm.insertvalue [[SIZE_2]], [[DESC_3]][3, 2]
// CHECK: [[DESC_5:%.*]] = llvm.insertvalue [[STRIDE_2]], [[DESC_4]][4, 2]
// CHECK: [[STRIDE_1:%.*]] = llvm.mul [[STRIDE_2]], [[SIZE_2]] : !llvm.i64
// CHECK: [[DESC_6:%.*]] = llvm.insertvalue [[SIZE_1]], [[DESC_5]][3, 1]
// CHECK: [[DESC_7:%.*]] = llvm.insertvalue [[STRIDE_1]], [[DESC_6]][4, 1]
// CHECK: [[STRIDE_0:%.*]] = llvm.mul [[STRIDE_1]], [[SIZE_1]] : !llvm.i64
// CHECK: [[DESC_8:%.*]] = llvm.insertvalue [[SIZE_0]], [[DESC_7]][3, 0]
// CHECK: [[DESC_9:%.*]] = llvm.insertvalue [[STRIDE_0]], [[DESC_8]][4, 0]
// CHECK: llvm.return [[DESC_9]] : [[DESC_TY]]

// -----

// CHECK: llvm.func @_mlir_ciface_tf_dealloc_raw(!llvm.ptr<i8>)

// CHECK-LABEL: llvm.func @dealloc_raw(
// CHECK-SAME:    [[TF_CTX:%.*]]: !llvm.ptr<i8>,
func @dealloc_raw(%ctx: !tf_framework.op_kernel_context,
                  %memref : memref<?x10xf32>) {
  tf_framework.dealloc_raw(%ctx, %memref) : memref<?x10xf32>
  return
}
// Extract allocated ptr from the memref descriptor.
// CHECK: %{{.*}} = llvm.mlir.undef : [[DESC_TY:!.*]]
// CHECK: [[FLOAT_PTR:%.*]] = llvm.extractvalue %{{.*}}[0] : [[DESC_TY]]
// CHECK-NEXT: [[VOID_PTR:%.*]] = llvm.bitcast [[FLOAT_PTR]]
// CHECK-SAME:                   !llvm.ptr<float> to !llvm.ptr<i8>

// Deallocate.
// CHECK: llvm.call @_mlir_ciface_tf_dealloc_raw(
// CHECK-SAME: [[TF_CTX]], [[VOID_PTR]]) : (!llvm.ptr<i8>, !llvm.ptr<i8>) -> ()
