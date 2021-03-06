#!/usr/bin/env bash

PRJ_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
SRC_DIR=${1:-$PRJ_ROOT_DIR}
INSTALL_PREFIX=${2:-../install/}

BMK_CONFIG_FILE="${SRC_DIR}/config/suite_all.txt"

#

C_FLAGS=""
C_FLAGS="${C_FLAGS} -Wall"
C_FLAGS="${C_FLAGS} -g -gline-tables-only"
C_FLAGS="${C_FLAGS} -O1 -Xclang -disable-llvm-passes"
C_FLAGS="${C_FLAGS} -mcmodel=medium"
C_FLAGS="${C_FLAGS} -fno-unroll-loops -fno-vectorize -fno-slp-vectorize"
C_FLAGS="${C_FLAGS} -fsave-optimization-record"
#C_FLAGS="${C_FLAGS} -fdiagnostics-show-hotness"

#LINKER_FLAGS="-Wl,-L$(llvm-config --libdir) -Wl,-rpath=$(llvm-config --libdir)"
#LINKER_FLAGS="${LINKER_FLAGS} -lc++ -lc++abi"

#

PIPELINES="genbc;linkbc;loopc14n;binarybc"
COMPOUND_PIPELINES="group1"
GROUP1_PIPELINE="genbc;linkbc;loopc14n;binarybc"

cmake \
  -GNinja \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_POLICY_DEFAULT_CMP0056=NEW \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=On \
  -DLLVM_DIR="$(llvm-config --prefix)/share/llvm/cmake/" \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="${C_FLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DHARNESS_USE_LLVM=On \
  -DHARNESS_BMK_CONFIG_FILE="${BMK_CONFIG_FILE}" \
  -DLLVMIR_PIPELINES_TO_INCLUDE="${PIPELINES}" \
  -DLLVMIR_PIPELINES_COMPOUND="${COMPOUND_PIPELINES}" \
  -DLLVMIR_PIPELINES_COMPOUND_GROUP1="${GROUP1_PIPELINE}" \
  "${SRC_DIR}"

