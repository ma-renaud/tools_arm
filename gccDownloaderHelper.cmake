set(allowableCompilerVersion 8.2.1 9.2.1 10.2.1)

if(NOT COMPILER_VERSION_REQUIRED)
    if(NOT "${PROJECT_NAME}" STREQUAL "CMAKE_TRY_COMPILE")
        message(STATUS "No specific version required. ")
        message(AUTHOR_WARNING "please set variable COMPILER_WANTED_VERSION with one of this choice: ${allowableCompilerVersion}")

        #try to get the last item in the list
        list(LENGTH allowableCompilerVersion outLength)
        math(EXPR lastIndex "${outLength}-1")
        list(GET allowableCompilerVersion ${lastIndex} latestVersion)
        #---
        SET(COMPILER_WANTED_VERSION "${latestVersion}")
    else()
        set(Skip_Download ON)
    endif()
elseif(COMPILER_VERSION_REQUIRED IN_LIST allowableCompilerVersion)
    SET(COMPILER_WANTED_VERSION "${COMPILER_VERSION_REQUIRED}")
else()
    message(FATAL_ERROR "This version of ${TOOLCHAIN_PREFIX}gcc:${COMPILER_WANTED_VERSION} is not currently supported.")
endif()

if(NOT DEFINED Skip_Download)
    #set some variable
    if(8.2.1 VERSION_EQUAL COMPILER_WANTED_VERSION)
        SET(COMPILER_MD5_APPLE 4c0d86df0244df22bc783f83df886db9)
        SET(COMPILER_MD5_WIN32 9b1cfb7539af11b0badfaa960679ea6f)
        SET(COMPILER_MD5_UNIX  f55f90d483ddb3bcf4dae5882c2094cd)
        set(COMPILER_EXTRA_SUBFOLDER "/gcc-${TOOLCHAIN_PREFIX}8-2018-q4-major")
    elseif(9.2.1 VERSION_EQUAL COMPILER_WANTED_VERSION)
        SET(COMPILER_MD5_APPLE 241b64f0578db2cf146034fc5bcee3d4)
        SET(COMPILER_MD5_WIN32 82525522fefbde0b7811263ee8172b10)
        SET(COMPILER_MD5_UNIX  fe0029de4f4ec43cf7008944e34ff8cc)
        set(COMPILER_EXTRA_SUBFOLDER "/gcc-${TOOLCHAIN_PREFIX}9-2019-q4-major")
    elseif(10.2.1 VERSION_EQUAL COMPILER_WANTED_VERSION)
        SET(COMPILER_MD5_APPLE e588d21be5a0cc9caa60938d2422b058)
        SET(COMPILER_MD5_WIN32 381f46929398da4c5ca3cefac1f9613b)
        SET(COMPILER_MD5_UNIX  8312c4c91799885f222f663fc81f9a31)
        set(COMPILER_EXTRA_SUBFOLDER "/gcc-${TOOLCHAIN_PREFIX}10-2020-q4-major")
    endif()
    string(REPLACE "." "-" COMPILER_BUILD_NAME ${COMPILER_WANTED_VERSION})

    SET(COMPILER_EXTRACTED_RESULT_FOLDER "gcc-${TOOLCHAIN_PREFIX}${COMPILER_BUILD_NAME}")

    SET(COMPILER_BASE_PATH "Tools/Compilers/${TOOLCHAIN_PREFIX}gcc/${COMPILER_WANTED_VERSION}")
    if(APPLE)
        SET(COMPILER_FILE_NAME "${COMPILER_EXTRACTED_RESULT_FOLDER}-mac.tar.bz2")
        SET(COMPILER_MD5 ${COMPILER_MD5_APPLE})
        SET(COMPILER_BASE_PATH "${CMAKE_SOURCE_DIR}/${COMPILER_BASE_PATH}")
    elseif(WIN32)
        UNSET(COMPILER_EXTRA_SUBFOLDER)
        SET(COMPILER_FILE_NAME "${COMPILER_EXTRACTED_RESULT_FOLDER}-win.zip")
        SET(COMPILER_MD5 ${COMPILER_MD5_WIN32})
        SET(COMPILER_BASE_PATH "$ENV{APPDATA}/${COMPILER_BASE_PATH}")
    elseif(UNIX)
        SET(COMPILER_FILE_NAME "${COMPILER_EXTRACTED_RESULT_FOLDER}-linux.tar.bz2")
        SET(COMPILER_MD5 ${COMPILER_MD5_UNIX})
        SET(COMPILER_BASE_PATH "$ENV{HOME}/${COMPILER_BASE_PATH}")
    endif()
    SET(MY_COMPILER_PATH "${COMPILER_BASE_PATH}${COMPILER_EXTRA_SUBFOLDER}/bin")

    if(APPLE OR UNIX)
        SET( ENV{PATH} "${MY_COMPILER_PATH}:$ENV{PATH}" )
    elseif (WIN32)
        SET( ENV{PATH} "${MY_COMPILER_PATH};$ENV{PATH}" )
    endif()
endif()

if(MINGW OR CYGWIN OR WIN32)
    set(UTIL_SEARCH_CMD where)
    message(STATUS "search command where")
elseif(UNIX OR APPLE)
    set(UTIL_SEARCH_CMD which)
    message(STATUS "search command which")
endif()
#---
# Check if the gcc it can find the binUtils and if the version is correct
execute_process(
        COMMAND ${UTIL_SEARCH_CMD} ${TOOLCHAIN_PREFIX}gcc
        OUTPUT_VARIABLE BINUTILS_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
        COMMAND ${TOOLCHAIN_PREFIX}gcc -dumpversion
        OUTPUT_VARIABLE MY_COMPILER_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

MESSAGE(STATUS "BinUtilsPath = " ${BINUTILS_PATH})
MESSAGE(STATUS "Wanted compiler version ${COMPILER_WANTED_VERSION} and found version = " ${MY_COMPILER_VERSION})
#---
if(NOT DEFINED  Skip_Download)
    if(BINUTILS_PATH STREQUAL "" OR NOT ${MY_COMPILER_VERSION} VERSION_EQUAL  ${COMPILER_WANTED_VERSION})
        message(STATUS "Compiler not found. downloading the correct version")

        SET(GCC_URL "https://github.com/ma-renaud/tools_arm/releases/download/${COMPILER_WANTED_VERSION}/${COMPILER_FILE_NAME}")

        message(STATUS "${GCC_URL}")
        file(DOWNLOAD ${GCC_URL}
                "${CMAKE_SOURCE_DIR}/${COMPILER_FILE_NAME}"
                EXPECTED_MD5;${COMPILER_MD5}
                SHOW_PROGRESS
                STATUS status)

        list(GET status 0 status_result)
        if(status_result EQUAL 0)
            message(STATUS "Creating folders...")
            file(MAKE_DIRECTORY ${COMPILER_BASE_PATH})

            message(STATUS "Extracting the compiler")
            execute_process(
                    COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/${COMPILER_FILE_NAME}
                    WORKING_DIRECTORY ${COMPILER_BASE_PATH}
            )
        endif()
        file(REMOVE ${CMAKE_SOURCE_DIR}/${COMPILER_FILE_NAME})
    else()
        message(STATUS "Compiler found with correct version. No need to install a new one")
    endif()
endif()
