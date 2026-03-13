# System Design

**Architecture Pattern:** Layered + Factory
**Build Systems Supported:** Xcode projects, Swift Packages

---

## Architecture Overview

```
+--------------------------------------------------------------+
|                    User Interface Layer                  |
|              CLI::Runner (Thor Commands)                 |
|           build / spm / init / version / help            |
+---------------------------+----------------------------------+
                            |
                            v
+--------------------------------------------------------------+
|               Commands Layer                             |
|  Build / SPM / Init                                      |
|  - Load configuration or parse CLI args                  |
|  - Validate input parameters                             |
|  - Delegate to orchestrator                              |
+---------------------------+----------------------------------+
                            |
                            v
+--------------------------------------------------------------+
|          Configuration Management Layer                  |
|  Config::Loader -> Schema::Validator -> Defaults          |
|  - YAML/JSON file discovery and parsing                 |
|  - Dry-validation schema enforcement                    |
|  - Default value application                            |
+---------------------------+----------------------------------+
                            |
                            v
+--------------------------------------------------------------+
|            Build Orchestration Layer                     |
|        Builder::Orchestrator                             |
|  - Coordinates Clean -> Archive -> XCFramework            |
|  - Aggregates errors and results                        |
|  - Delegates to specialized builders                    |
+---------+-----------+-----------+-----------+-----------+
        |           |           |           |
        v           v           v           v
    +-------+   +---------+   +----------+   +-----------+
    | Clean |   | Archive |   |XCFramework|   |SPM Builder|
    | Phase |   | Phase   |   | Assembly  |   |           |
    +-------+   +---------+   +----------+   +-----------+
        |           |           |           |
        +-----------+-----------+-----------+------------------+
        |     Platform Abstraction & Tool Integration Layer       |
        |                                                          |
        |  +-----------------+  +----------------------+         |
        |  | Platform::Base  |  | Xcodebuild::Wrapper  |         |
        |  +-----------------+  +----------------------+         |
        |  | IOS             |  | execute_archive      |         |
        |  | IOSSimulator    |  | execute_create_xcfw  |         |
        |  +-----------------+  | execute_clean        |         |
        |                        +----------------------+         |
        |                                                          |
        |  +-----------------+  +----------------------+         |
        |  | Swift::SDK      |  | SPM::Package         |         |
        |  | Swift::Builder  |  | SPM::FrameworkSlice  |         |
        |  |                 |  | SPM::XCFrameworkBldR |         |
        |  +-----------------+  +----------------------+         |
        +-----------+-----------+-----------+------------------+
        |           |           |           |              |
        v           v           v           v              v
    +-----------------------------------------------------+
    |     External Tools (via Open3)               |
    |  xcodebuild  swift  xcrun  libtool  lipo    |
    +-----------------------------------------------------+
```

---

## Layer Responsibilities

    full details on each layer, see [Code-standards](/docs/development/code-standards).
