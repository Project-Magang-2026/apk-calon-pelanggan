cmake_minimum_required(VERSION 3.10.2)
project(ftth_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
    ftth_engine
    SHARED
    ftth_engine.cpp
)
