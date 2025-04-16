cmake_minimum_required(VERSION 3.10)
project(CBC)

set(CMAKE_CXX_STANDARD 17)

# 尝试使用pkg-config查找库
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(CBC QUIET cbc)
    pkg_check_modules(CLP QUIET clp)
    pkg_check_modules(COINUTILS QUIET coinutils)
endif()

# 如果pkg-config找不到库，使用手动设置的路径
if(NOT CBC_FOUND OR NOT CLP_FOUND OR NOT COINUTILS_FOUND)
    message(STATUS "Using manual library paths")
    set(CBC_INCLUDE_DIRS /usr/local/include/coin-or)
    set(CLP_INCLUDE_DIRS /usr/local/include/coin-or)
    set(COINUTILS_INCLUDE_DIRS /usr/local/include/coin-or)

    set(CBC_LIBRARIES cbc)
    set(CLP_LIBRARIES clp)
    set(COINUTILS_LIBRARIES coinutils)
endif()

add_executable(CBC main.cpp)

# 链接必要的库
target_include_directories(CBC PUBLIC
    ${CBC_INCLUDE_DIRS}
    ${CLP_INCLUDE_DIRS}
    ${COINUTILS_INCLUDE_DIRS}
)

target_link_libraries(CBC
    ${CBC_LIBRARIES}
    ${CLP_LIBRARIES}
    ${COINUTILS_LIBRARIES}
    openblas
)
