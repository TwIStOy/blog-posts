+++
title = "在 CLion 中配置 gtest"
date = 2016-11-13
slug = "gtest-in-clion"
[taxonomies]
tags = [
  "unittest",
  "cLion",
  "tips",
  "gtest",
]
+++

最近在学习 googletest 这个用于 C++ 的单元测试框架的时候，遇到了一个问题。就是希望可以在 CLion 中配置好一个制定项目的测试，然后由 CLion 运行并且给出一个结果。
结果当然是成功了的，这篇文章主要就记录一下整个配置的过程，配置过程整体很简单，主要就是写 CMakeLists.txt 的过程（因为 CLion 使用 CMakeLists 管理整个 C++ 的项目）。

# 项目目录结构
```
+ project_home
  + ext // external library
    + gtest // google test framework
	  - CMakeLists.txt
  + include // project headers
  + src // project source files
  + test // test files
  - CMakeLists.txt
```

这里假定我们把 gtest 放在 `ext` 这个目录下。我们不需要手动的从 github 上下载 gtest，CMake 可以替我们做到这个部分。具体的命令在后面会写到。
test 目录就是用于存放单元测试文件的地方，这部分的 cpp 文件是不需要写 main 的，在链接的时候，会把 main 函数链接上去。

# ext/gtest/CMakeLists.txt
这部分的 CMakeLists.txt 会作为一个子文件夹在整个项目的 CMakeLists.txt 被使用。所以，这里是一个单独的 project。

```
cmake_minimum_required(VERSION 3.6)
project(gtest_builder)
include(ExternalProject)

set(GTEST_FORCE_SHARED_CRT ON)
set(GTEST_DISABLE_PTHREADS OFF)

ExternalProject_Add(googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    CMAKE_ARGS -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG:PATH=DebugLibs
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE:PATH=ReleaseLibs
    -DCMAKE_CXX_FLAGS=${MSVC_COMPILER_DEFS}
    -Dgtest_force_shared_crt=${GTEST_FORCE_SHARED_CRT}
    -Dgtest_disable_pthreads=${GTEST_DISABLE_PTHREADS}
    -DBUILD_GTEST=ON
    PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
    # Disable install step
    INSTALL_COMMAND ""
    )

# Specify include dir
ExternalProject_Get_Property(googletest source_dir)
set(GTEST_INCLUDE_DIRS ${source_dir}/googletest/include PARENT_SCOPE)

# Specify MainTest's link libraries
ExternalProject_Get_Property(googletest binary_dir)
set(GTEST_LIBS_DIR ${binary_dir}/googlemock/gtest PARENT_SCOPE)
```

这里用到了 CMake 的一个模块 `ExternalProject`，文档在这里：[传送门](https://cmake.org/cmake/help/v3.7/module/ExternalProject.html)。
最后把下载好的 googletest 的头文件目录和编译好的链接库的目录返回给项目的 CMakeLists.txt。

# CMakeLists.txt

```
cmake_minimum_required(VERSION 3.6)
set(PROJECT_NAME_STR gtest_usage)
project(${PROJECT_NAME_STR})

find_package(Threads REQUIRED)

add_definitions(-Wall -std=c++11 -Wno-deprecated -pthread)

set(COMMON_INCLUDES  ${PROJECT_SOURCE_DIR}/include)
set(EXT_PROJECTS_DIR ${PROJECT_SOURCE_DIR}/ext)

add_subdirectory(${EXT_PROJECTS_DIR}/gtest)

enable_testing()

set(PROJECT_TEST_NAME ${PROJECT_NAME_STR}_test)
include_directories(${GTEST_INCLUDE_DIRS} ${COMMON_INCLUDES})

file(GLOB TEST_SRC_FILES ${PROJECT_SOURCE_DIR}/test/*.cpp)
add_executable(${PROJECT_TEST_NAME} ${TEST_SRC_FILES})
add_dependencies(${PROJECT_TEST_NAME} googletest)

if(NOT WIN32 OR MINGW)
  target_link_libraries(${PROJECT_TEST_NAME}
      ${GTEST_LIBS_DIR}/libgtest.a
      ${GTEST_LIBS_DIR}/libgtest_main.a
      )
else()
  target_link_libraries(${PROJECT_TEST_NAME}
      debug ${GTEST_LIBS_DIR}/DebugLibs/${CMAKE_FIND_LIBRARY_PREFIXES}gtest${CMAKE_FIND_LIBRARY_SUFFIXES}
      optimized ${GTEST_LIBS_DIR}/ReleaseLibs/${CMAKE_FIND_LIBRARY_PREFIXES}gtest${CMAKE_FIND_LIBRARY_SUFFIXES}
      )
  target_link_libraries(${PROJECT_TEST_NAME}
      debug ${GTEST_LIBS_DIR}/DebugLibs/${CMAKE_FIND_LIBRARY_PREFIXES}gtest_main${CMAKE_FIND_LIBRARY_SUFFIXES}
      optimized ${GTEST_LIBS_DIR}/ReleaseLibs/${CMAKE_FIND_LIBRARY_PREFIXES}gtest_main${CMAKE_FIND_LIBRARY_SUFFIXES}
      )
endif()

target_link_libraries(${PROJECT_TEST_NAME} ${CMAKE_THREAD_LIBS_INIT})
add_test(test1 ${PROJECT_TEST_NAME})
```

这里的前面和配置一个正常的项目没什么不同的，都是配置头文件位置，配置链接库位置。唯一的区别是最后不是 `add_executable` 而是 `add_test`。

到这里应给整个项目都配置好了，然后就可以在 CLion 的右上角找到。这样的部分：![](http://7vijdo.com1.z0.glb.clouddn.com/image/autoupload/gtest-in-clion-1.jpg)

CLion 可以识别出来这个是使用的 gtest 框架。然后就可以成功的运行啦！CLion 会在下面给出单元测试的报告，包括了每个 test case 的运行时间和结果。

快去试一试吧~

--------------

参考链接：

- https://github.com/snikulov/google-test-examples
- https://github.com/google/googletest