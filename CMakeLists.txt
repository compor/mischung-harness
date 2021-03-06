# cmake file

cmake_minimum_required(VERSION 3.0)

project(mischung-1.0.0 C CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")
include(Harness-Utils)
include(Harness-Version)
include(InstallPipelineLLVMIR)
include(CheckIncludeFile)

get_version(MISCHUNG_VERSION)
message(STATUS "mischung harness version: ${MISCHUNG_VERSION}")

message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")

#
# project options
#

option(HARNESS_USE_LLVM "use LLVM bitcode processing tools" OFF)

set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)

set(HARNESS_INPUT_DIR $ENV{HARNESS_INPUT_DIR})

set(HARNESS_REPORT_DIR $ENV{HARNESS_REPORT_DIR})

if(NOT HARNESS_REPORT_DIR)
  set(HARNESS_REPORT_DIR "${CMAKE_BINARY_DIR}/reports/")
  file(MAKE_DIRECTORY ${HARNESS_REPORT_DIR})
endif()

set(HARNESS_BMK_SOURCE_SUBDIR "src")

set(HARNESS_LLVMIR_CMAKE_FRAGMENT_FILES "")
set(HARNESS_END_CMAKE_FRAGMENT_FILES "")

set(HARNESS_BUILD_TREE_SCRIPTS_SRC_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/utils/scripts/build_tree/")

set(HARNESS_BUILD_TREE_SCRIPTS_DEST_DIR "${CMAKE_CURRENT_BINARY_DIR}/scripts/")

set(HARNESS_INSTALL_TREE_SCRIPTS_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/utils/scripts/install_tree/")

set(HARNESS_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/config")

# add_definitions()

check_include_file(getopt.h HAVE_GETOPT_H)

if(HAVE_GETOPT_H)
  add_definitions(-DHAVE_GETOPT_H)
endif()

include_directories(${CMAKE_BINARY_DIR})

# project options checks and processing

if(HARNESS_USE_LLVM)
  find_package(LLVM REQUIRED CONFIG)

  if(LLVM_FOUND)
    set(LLVM_LIB_DIR ${LLVM_TOOLS_BINARY_DIR}/../lib/)

    list(APPEND CMAKE_MODULE_PATH
                "${CMAKE_CURRENT_SOURCE_DIR}/cmake/llvm-ir-cmake-utils/cmake/")

    include(LLVMIRUtil RESULT_VARIABLE LLVM_IR_UTIL_FOUND)
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${HARNESS_CMAKE_BINARY_FRAGMENT_DIR}")

set(HARNESS_CMAKE_FRAGMENT_FILES "")

if(LLVM_IR_UTIL_FOUND)
  list(
    APPEND CMAKE_MODULE_PATH
           "${CMAKE_CURRENT_SOURCE_DIR}/cmake/llvm-ir-cmake-pipelines/cmake/")
  include(LLVMIRPipelines)

  set(FRAGMENT_FILE "main_fragment")

  llvmir_pipelines_setup(DEPENDS BMK_PROJECT_NAME OUTPUT_FILE ${FRAGMENT_FILE})

  # check if there are any pipelines configured
  if(LLVMIR_PIPELINES_TO_INCLUDE)
    list(APPEND HARNESS_CMAKE_FRAGMENT_FILES "${FRAGMENT_FILE}")
  endif()
endif()

#
# project user options
#

# project user options checks and processing

if(NOT HARNESS_BMK_CONFIG_FILE)
  message(
    FATAL_ERROR "Benchmark config file HARNESS_BMK_CONFIG_FILE is not set")
elseif(NOT EXISTS ${HARNESS_BMK_CONFIG_FILE})
  message(
    FATAL_ERROR
      "Benchmark config file does not exist: ${HARNESS_BMK_CONFIG_FILE}")
endif()

#
# configuration
#

set(CMAKE_INSTALL_MESSAGE "LAZY")

file(STRINGS ${HARNESS_BMK_CONFIG_FILE} BENCHMARKS)

foreach(BMK ${BENCHMARKS})
  message(STATUS "adding subdir: ${BMK}")
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/programs/${BMK}/)
endforeach()

# installation

install(DIRECTORY ${HARNESS_CONFIG_DIR} DESTINATION .)
install(DIRECTORY ${HARNESS_INSTALL_TREE_SCRIPTS_DIR} DESTINATION scripts)

add_custom_target(
  install-build-scripts ALL
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          ${HARNESS_BUILD_TREE_SCRIPTS_SRC_DIR}
          ${HARNESS_BUILD_TREE_SCRIPTS_DEST_DIR}
  COMMENT "copying build-tree related scripts")
