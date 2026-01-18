import SwiftUI
import AppKit
import Combine

// --- Logic / Model ---

class InstallerViewModel: ObservableObject {
    @Published var disc1Path: String = ""
    @Published var disc2Path: String = ""
    @Published var isSingleDisc: Bool = false
    @Published var convertFMV: Bool = true
    
    @Published var isInstalling: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = "Ready"
    @Published var errorMessage: String? = nil
    @Published var isComplete: Bool = false
    @Published var showSuccess: Bool = false
    @Published var showDebug: Bool = false // Debug overlay toggle
    
    // App State
    @Published var isGameInstalled: Bool = false
    @Published var activeTab: String = "launcher" // launcher, install, fmv
    
    init() {
        checkInstallation()
        loadConfig()
    }
    
    // Config: Language
    @Published var selectedLanguage: Int = 0
    let languages = [
        0: "English",
        1: "Italian",
        2: "German",
        3: "French",
        4: "Spanish",
        5: "Ukrainian"
    ]
    
    func loadConfig() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let configPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("data/config.ini").path
        
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return }
        
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("languageId") {
                let parts = trimmed.components(separatedBy: "=")
                if parts.count >= 2 {
                    let valuePart = parts[1].components(separatedBy: "#")[0].trimmingCharacters(in: .whitespaces)
                    if let val = Int(valuePart) {
                        DispatchQueue.main.async {
                            self.selectedLanguage = val
                        }
                    }
                }
            }
        }
    }
    
    func saveConfig() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let configPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("data/config.ini").path
        
        guard var content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return }
        
        var newLines: [String] = []
        let lines = content.components(separatedBy: "\n")
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("languageId") {
                newLines.append("languageId=\(selectedLanguage)                # 0 = ENGLISH; 1 = ITALIAN; 2 = GERMAN; 3 = FRENCH; 4 = SPANISH; 5 = UKRAINIAN")
            } else {
                newLines.append(line)
            }
        }
        
        content = newLines.joined(separator: "\n")
        try? content.write(toFile: configPath, atomically: true, encoding: .utf8)
        print("Config saved: Language ID \(selectedLanguage)")
    }
    
    @Published var debugInfo: String = ""
    @Published var logText: String = ""
    
    func appendLog(_ message: String) {
        DispatchQueue.main.async {
            self.logText += message + "\n"
            // Keep log size manageable
            if self.logText.count > 10000 {
                self.logText = String(self.logText.suffix(10000))
            }
        }
    }

    func checkInstallation() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let gameDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("data/DRIVER2").path
        
        // Check for FRONTEND.BIN (extracted from disc)
        let frontendFile = URL(fileURLWithPath: gameDir).appendingPathComponent("FRONTEND.BIN").path
        let hasFrontend = FileManager.default.fileExists(atPath: frontendFile)
        
        // Also check for at least one level file to ensure full installation
        let levelFile = URL(fileURLWithPath: gameDir).appendingPathComponent("LEVELS/NY.D2L").path
        let hasLevel = FileManager.default.fileExists(atPath: levelFile)
        
        isGameInstalled = hasFrontend && hasLevel
        
        if !isGameInstalled {
            activeTab = "install"
            debugInfo = "Check failed.\nPath: \(gameDir)\nFrontend found: \(hasFrontend)"
        } else {
            activeTab = "launcher"
            debugInfo = "Installed. Path: \(gameDir)"
        }
    }
    
    func startInstall() {
        guard !disc1Path.isEmpty else {
            errorMessage = "Please select Disc 1."
            return
        }
        
        isInstalling = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting installation..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.runInstallation()
        }
    }
    
    func startFMVConversion() {
        isInstalling = true
        progress = 0.0
        errorMessage = nil
        statusMessage = "Starting FMV conversion..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let resourcePath = Bundle.main.resourcePath ?? ""
            let dataDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("data").path
            let installDir = URL(fileURLWithPath: dataDir).appendingPathComponent("install").path
            let gameDir = URL(fileURLWithPath: dataDir).appendingPathComponent("DRIVER2").path
            let jpsxdecPath = URL(fileURLWithPath: installDir).appendingPathComponent("jpsxdec.jar").path
            
            self.convertFMVs(gameDir: gameDir, jpsxdecPath: jpsxdecPath, dataDir: dataDir)
            
            DispatchQueue.main.async {
                self.statusMessage = "FMV Conversion Complete!"
                self.progress = 1.0
                self.isInstalling = false
                self.showSuccess = true
            }
        }
    }
    
    func manualCleanup() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let dataDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("data").path
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.statusMessage = "Cleaning up unnecessary files..."
                self.isInstalling = true
                self.progress = 0.5
            }
            
            self.cleanupAfterConversion(dataDir: dataDir)
            
            DispatchQueue.main.async {
                self.statusMessage = "Cleanup Complete!"
                self.progress = 1.0
                self.isInstalling = false
                self.showSuccess = true
            }
        }
    }
    
    func resetInstallation() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let gameDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("data/DRIVER2").path
        
        // Load GitHub files list (base assets that should NOT be deleted)
        let githubFilesPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("github_files.txt").path
        var githubFiles = Set<String>()
        
        if let content = try? String(contentsOfFile: githubFilesPath, encoding: .utf8) {
            githubFiles = Set(content.components(separatedBy: "\n").filter { !$0.isEmpty })
            print("Loaded \(githubFiles.count) GitHub base files")
        } else {
            print("Warning: Could not load GitHub file list, aborting reset")
            DispatchQueue.main.async {
                self.errorMessage = "Reset failed: Could not load GitHub file list."
            }
            return
        }
        
        // Recursively find all files in DRIVER2 directory
        guard let enumerator = FileManager.default.enumerator(atPath: gameDir) else {
            print("Failed to enumerate DRIVER2 directory")
            return
        }
        
        var deletedCount = 0
        var deletedSize: Int64 = 0
        
        for case let file as String in enumerator {
            let fullPath = URL(fileURLWithPath: gameDir).appendingPathComponent(file).path
            
            // Skip directories
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory), isDirectory.boolValue {
                continue
            }
            
            // Normalize the file path for comparison (relative to DRIVER2)
            let relativePath = "DRIVER2/" + file
            
            // Check if file is in GitHub base assets
            if !githubFiles.contains(relativePath) {
                // File is not in GitHub base assets, it was extracted - delete it
                do {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                       let size = attrs[.size] as? Int64 {
                        deletedSize += size
                    }
                    try FileManager.default.removeItem(atPath: fullPath)
                    print("Deleted extracted file: \(file)")
                    deletedCount += 1
                } catch {
                    print("Failed to delete \(file): \(error)")
                }
            }
        }
        
        let sizeMB = Double(deletedSize) / 1024.0 / 1024.0
        print("Reset complete: deleted \(deletedCount) files (\(String(format: "%.1f", sizeMB)) MB)")
        
        DispatchQueue.main.async {
            self.isGameInstalled = false
            self.activeTab = "install"
            self.statusMessage = String(format: "Reset complete. Deleted %d files (%.1f MB)", deletedCount, sizeMB)
            self.logText = ""
            self.errorMessage = nil
            self.isInstalling = false
            self.progress = 0.0
        }
        
        // Touch the app bundle to force Finder to update size
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/usr/bin/touch"
        task.arguments = [bundlePath]
        try? task.run()
    }
    
    private func runInstallation() {
        let resourcePath = Bundle.main.resourcePath ?? ""
        let dataDir = URL(fileURLWithPath: resourcePath).appendingPathComponent("data").path
        let installDir = URL(fileURLWithPath: dataDir).appendingPathComponent("install").path
        let gameDir = URL(fileURLWithPath: dataDir).appendingPathComponent("DRIVER2").path
        let jpsxdecPath = URL(fileURLWithPath: installDir).appendingPathComponent("jpsxdec.jar").path
        
        // 1. Extract Disc 1
        DispatchQueue.main.async { self.appendLog("Starting Disc 1 extraction...") }
        if !extractDisc(isoPath: disc1Path, name: "Disc 1", jpsxdecPath: jpsxdecPath, outputDir: dataDir) {
            // Error message is already set, keep isInstalling = true to show error screen
            return
        }
        DispatchQueue.main.async { self.appendLog("Disc 1 extraction finished.") }
        
        // 2. Extract Disc 2
        if !isSingleDisc && !disc2Path.isEmpty {
            if !extractDisc(isoPath: disc2Path, name: "Disc 2", jpsxdecPath: jpsxdecPath, outputDir: dataDir) {
                // Error message is already set
                return
            }
        }
        
        // 3. FMV & XA
        DispatchQueue.main.async { self.appendLog("Checking FMV conversion settings: Enabled = \(self.convertFMV)") }
        if convertFMV {
            DispatchQueue.main.async { self.appendLog("Starting FMV conversion...") }
            if !convertFMVs(gameDir: gameDir, jpsxdecPath: jpsxdecPath, dataDir: dataDir) {
                // Error message is already set
                return
            }
            DispatchQueue.main.async { self.appendLog("FMV conversion finished.") }
            
            DispatchQueue.main.async { self.appendLog("Starting XA audio conversion...") }
            if !convertXA(gameDir: gameDir, jpsxdecPath: jpsxdecPath, dataDir: dataDir) {
                // Error message is already set
                return
            }
            DispatchQueue.main.async { self.appendLog("XA conversion finished.") }
            
            // Cleanup unnecessary files after conversion
            DispatchQueue.main.async { self.appendLog("Cleaning up unnecessary files...") }
            cleanupAfterConversion(dataDir: dataDir)
            DispatchQueue.main.async { self.appendLog("Cleanup finished.") }
        }
        
        DispatchQueue.main.async {
            self.statusMessage = "Installation Complete!"
            self.progress = 1.0
            self.isComplete = true
            self.isInstalling = false
            self.isGameInstalled = true
            self.activeTab = "launcher"
        }
    }
    
    private func extractDisc(isoPath: String, name: String, jpsxdecPath: String, outputDir: String) -> Bool {
        DispatchQueue.main.async { self.statusMessage = "Indexing \(name)..." }
        
        let indexFile = URL(fileURLWithPath: outputDir).appendingPathComponent("disc_index.idx").path
        
        // Build Index
        if !runJavaCommand(args: ["-jar", jpsxdecPath, "-f", isoPath, "-x", indexFile], parseProgress: true) {
            DispatchQueue.main.async { self.errorMessage = "Failed to index \(name). Is it a valid PSX disc image?" }
            return false
        }
        
        DispatchQueue.main.async { self.statusMessage = "Extracting \(name)..." }
        
        // Extract Files
        DispatchQueue.main.async { self.appendLog("Running jpsxdec extraction command...") }
        if !runJavaCommand(args: ["-jar", jpsxdecPath, "-x", indexFile, "-dir", outputDir, "-a", "file"], parseProgress: true) {
             DispatchQueue.main.async { self.errorMessage = "Failed to extract \(name)." }
             return false
        }
        
        try? FileManager.default.removeItem(atPath: indexFile)
        return true
    }
    
    private func convertFMVs(gameDir: String, jpsxdecPath: String, dataDir: String) -> Bool {
        let fmvDir = "FMV"
        let absoluteFmvDir = URL(fileURLWithPath: gameDir).appendingPathComponent(fmvDir).path
        
        guard FileManager.default.fileExists(atPath: absoluteFmvDir) else {
            print("FMV directory not found: \(absoluteFmvDir)")
            DispatchQueue.main.async { self.appendLog("FMV directory not found. Skipping.") }
            return true
        }
        
        // Find all .STR files recursively
        var strFiles: [String] = []
        if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: absoluteFmvDir), includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == "str" {
                    strFiles.append(fileURL.path)
                }
            }
        }
        
        if strFiles.isEmpty {
            print("No .STR files found.")
            DispatchQueue.main.async { self.appendLog("No .STR files found. Skipping.") }
            return true
        }
        
        DispatchQueue.main.async { self.statusMessage = "Converting \(strFiles.count) FMVs (parallel)..." }
        
        // Use parallel processing for faster conversion
        let totalFiles = strFiles.count
        let processedCount = NSLock()
        var successCount = 0
        
        // Determine optimal thread count (use 75% of available cores to avoid overload)
        let maxThreads = max(1, Int(Double(ProcessInfo.processInfo.activeProcessorCount) * 0.75))
        
        DispatchQueue.main.async {
            self.appendLog("Using \(maxThreads) parallel threads for conversion")
        }
        
        // Process files in parallel
        DispatchQueue.concurrentPerform(iterations: totalFiles) { index in
            let strPath = strFiles[index]
            let fileName = URL(fileURLWithPath: strPath).lastPathComponent
            
            // Thread-safe progress update
            processedCount.lock()
            let currentIndex = index + 1
            processedCount.unlock()
            
            DispatchQueue.main.async {
                self.appendLog("Processing \(fileName) (\(currentIndex)/\(totalFiles))...")
                self.progress = Double(currentIndex) / Double(totalFiles)
            }
            
            let indexFile = URL(fileURLWithPath: strPath).deletingPathExtension().appendingPathExtension("idx").path
            
            // 1. Index
            if !runJavaCommand(args: ["-jar", jpsxdecPath, "-f", strPath, "-x", indexFile]) {
                print("Failed to index \(fileName)")
                return
            }
            
            // 2. Convert Video
            let sourceDir = URL(fileURLWithPath: strPath).deletingLastPathComponent().path
            if !runJavaCommand(args: ["-jar", jpsxdecPath, "-x", indexFile, "-a", "video", "-quality", "psx", "-vf", "avi:mjpg", "-up", "Lanczos3", "-dir", sourceDir]) {
                print("Failed to convert video for \(fileName)")
            }
            
            // 3. Convert Audio
            if !runJavaCommand(args: ["-jar", jpsxdecPath, "-x", indexFile, "-a", "audio", "-quality", "psx", "-af", "wav", "-dir", sourceDir]) {
                print("Failed to convert audio for \(fileName)")
            }
            
            
            // Cleanup index and original STR file
            try? FileManager.default.removeItem(atPath: indexFile)
            try? FileManager.default.removeItem(atPath: strPath)
            
            // Cleanup redundant WAV files (audio is already in AVI)
            let baseName = URL(fileURLWithPath: strPath).deletingPathExtension().lastPathComponent
            if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: sourceDir), includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    let fileName = fileURL.lastPathComponent
                    // Delete WAV files that match the STR base name pattern (e.g., RENDER0.STR[0.0].wav)
                    if fileURL.pathExtension.lowercased() == "wav" && fileName.hasPrefix(baseName) {
                        try? FileManager.default.removeItem(at: fileURL)
                        print("Deleted redundant WAV: \(fileName)")
                    }
                }
            }
            
            successCount += 1
        }
        
        DispatchQueue.main.async { self.appendLog("FMV conversion complete. Processed \(successCount)/\(strFiles.count) files.") }
        return true
    }
    
    private func convertXA(gameDir: String, jpsxdecPath: String, dataDir: String) -> Bool {
        let xaDir = "XA"
        let absoluteXaDir = URL(fileURLWithPath: gameDir).appendingPathComponent(xaDir).path
        
        guard FileManager.default.fileExists(atPath: absoluteXaDir) else {
            print("XA directory not found: \(absoluteXaDir)")
            DispatchQueue.main.async { self.appendLog("XA directory not found. Skipping.") }
            return true
        }
        
        // Find all .XA files recursively
        var xaFiles: [String] = []
        if let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: absoluteXaDir), includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == "xa" {
                    xaFiles.append(fileURL.path)
                }
            }
        }
        
        if xaFiles.isEmpty {
            print("No .XA files found.")
            DispatchQueue.main.async { self.appendLog("No .XA files found. Skipping.") }
            return true
        }
        
        DispatchQueue.main.async { self.statusMessage = "Converting \(xaFiles.count) XA files..." }
        
        var successCount = 0
        
        for (index, xaPath) in xaFiles.enumerated() {
            let fileName = URL(fileURLWithPath: xaPath).lastPathComponent
            DispatchQueue.main.async {
                self.appendLog("Processing \(fileName) (\(index + 1)/\(xaFiles.count))...")
            }
            
            let indexFile = URL(fileURLWithPath: xaPath).deletingPathExtension().appendingPathExtension("idx").path
            
            // 1. Index
            if !runJavaCommand(args: ["-jar", jpsxdecPath, "-f", xaPath, "-x", indexFile]) {
                print("Failed to index \(fileName)")
                continue
            }
            
            // 2. Convert Audio
            let sourceDir = URL(fileURLWithPath: xaPath).deletingLastPathComponent().path
            if !runJavaCommand(args: ["-jar", jpsxdecPath, "-x", indexFile, "-a", "audio", "-quality", "psx", "-af", "wav", "-dir", sourceDir]) {
                print("Failed to convert audio for \(fileName)")
            }
            
            // Cleanup index and original XA file
            try? FileManager.default.removeItem(atPath: indexFile)
            try? FileManager.default.removeItem(atPath: xaPath)
            successCount += 1
        }
        
        DispatchQueue.main.async { self.appendLog("XA conversion complete. Processed \(successCount)/\(xaFiles.count) files.") }
        return true
    }
    
    private func cleanupAfterConversion(dataDir: String) {
        var deletedCount = 0
        var deletedSize: Int64 = 0
        
        // Files to delete (patterns)
        let filesToDelete = [
            // Conversion scripts
            "_convert_cd_fmv_xa.sh",
            "_convert_cd_fmv_xa.bat",
            "install/conv.sh",
            "install/conv.bat",
            // Config files (keep config.ini for game)
            "install/jpsxdec.ini",
            "cutscene_recorder.ini",
            // Disc images (if any remain in install)
            "install/*.bin",
            "install/*.iso",
            "install/*.cue",
            // PSX executables (not needed after extraction)
            "install/SLUS_*.61",
            "install/SLUS_*.18",
            "install/SYSTEM.CNF",
            "install/all",
            // Log files
            "REDRIVER2.log",
            "index.log",
            // Temporary index files (should be cleaned already, but just in case)
            "DRIVER2/*.idx",
            "DRIVER2/FMV/*.idx",
            "DRIVER2/XA/*.idx"
        ]
        
        for pattern in filesToDelete {
            let fullPath = URL(fileURLWithPath: dataDir).appendingPathComponent(pattern).path
            
            // Handle wildcards
            if pattern.contains("*") {
                let dir = URL(fileURLWithPath: fullPath).deletingLastPathComponent().path
                let filePattern = URL(fileURLWithPath: fullPath).lastPathComponent
                
                if let enumerator = FileManager.default.enumerator(atPath: dir) {
                    for case let file as String in enumerator {
                        if file.range(of: filePattern.replacingOccurrences(of: "*", with: ".*"), options: .regularExpression) != nil {
                            let filePath = URL(fileURLWithPath: dir).appendingPathComponent(file).path
                            if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                               let size = attrs[.size] as? Int64 {
                                deletedSize += size
                            }
                            try? FileManager.default.removeItem(atPath: filePath)
                            deletedCount += 1
                            print("Deleted: \(file)")
                        }
                    }
                }
            } else {
                // Direct file deletion
                if FileManager.default.fileExists(atPath: fullPath) {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                       let size = attrs[.size] as? Int64 {
                        deletedSize += size
                    }
                    try? FileManager.default.removeItem(atPath: fullPath)
                    deletedCount += 1
                    print("Deleted: \(pattern)")
                }
            }
        }
        
        let sizeMB = Double(deletedSize) / 1024.0 / 1024.0
        print("Cleanup: deleted \(deletedCount) files (\(String(format: "%.1f", sizeMB)) MB)")
        DispatchQueue.main.async {
            self.appendLog("Cleanup: deleted \(deletedCount) files (\(String(format: "%.1f", sizeMB)) MB)")
        }
        
        // Touch the app bundle to force Finder to update size
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/usr/bin/touch"
        task.arguments = [bundlePath]
        try? task.run()
    }
    
    private func checkJava() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["java"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func runJavaCommand(args: [String], parseProgress: Bool = false) -> Bool {
        // Use system java
        let javaPath = "/usr/bin/java"
        
        guard FileManager.default.fileExists(atPath: javaPath) else {
            DispatchQueue.main.async {
                self.errorMessage = "Java not found! Please install Java 11+ to convert videos."
                self.statusMessage = "Missing Java Runtime"
                
                let alert = NSAlert()
                alert.messageText = "Java Runtime Missing"
                alert.informativeText = "To convert FMV videos, you need to install Java (JDK 11 or newer).\n\nWould you like to open the download page?"
                alert.addButton(withTitle: "Download Java")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: "https://www.oracle.com/java/technologies/downloads/") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            return false
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: javaPath)
        task.arguments = args
        // DO NOT set currentDirectoryURL - let it use default
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        do {
            try task.run()
            
            if parseProgress {
                let outHandle = pipe.fileHandleForReading
                outHandle.readabilityHandler = { pipe in
                    let data = pipe.availableData
                    guard !data.isEmpty else { return }
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.appendLog(output)
                            if output.contains("]") || output.contains("%") || output.contains("Saving #") || output.contains("Item complete") {
                                if self.progress < 0.95 { self.progress += 0.002 }
                            }
                        }
                    }
                }
                
                let errHandle = errorPipe.fileHandleForReading
                errHandle.readabilityHandler = { pipe in
                    let data = pipe.availableData
                    guard !data.isEmpty else { return }
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.appendLog("STDERR: \(output)")
                        }
                    }
                }
            }
            
            task.waitUntilExit()
            
            // Cleanup handlers
            if parseProgress {
                pipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                DispatchQueue.main.async { self.appendLog("Process finished with status: \(task.terminationStatus)") }
            }
            
            if task.terminationStatus != 0 {
                // If we were parsing progress, we already logged stderr. 
                // If not, we need to read it now.
                if !parseProgress {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    print("Java command failed: \(errorOutput)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Java Error: \(errorOutput)"
                    }
                } else {
                     // Just set error message generic, details are in log
                     DispatchQueue.main.async {
                        self.errorMessage = "Java command failed (see log for details)."
                    }
                }
                return false
            }
            
            return true
        } catch {
            print("Failed to run java: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Launch Error: \(error.localizedDescription)"
            }
            return false
        }
    }
}

// --- UI ---

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewModel = InstallerViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check installation status first
        viewModel.checkInstallation()
        
        // Check if Option key is pressed to force show launcher
        let isOptionPressed = NSEvent.modifierFlags.contains(.option)
        
        if viewModel.isGameInstalled && !isOptionPressed {
            // Auto-launch game
            launchGame()
            return
        }

        let contentView = MainView(viewModel: viewModel)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.title = "REDRIVER2 Launcher"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)
        
        setupMenu()
    }
    
    func launchGame() {
        let bundleUrl = Bundle.main.bundleURL
        let executableUrl = bundleUrl.appendingPathComponent("Contents/MacOS/REDRIVER2")
        
        guard FileManager.default.fileExists(atPath: executableUrl.path) else {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Could not find REDRIVER2 executable at:\n\(executableUrl.path)"
            alert.runModal()
            NSApplication.shared.terminate(nil)
            return
        }
        
        let task = Process()
        task.executableURL = executableUrl
        task.arguments = []
        
        // Set working directory to data folder so game can find DRIVER2
        let dataUrl = bundleUrl.appendingPathComponent("Contents/Resources/data")
        task.currentDirectoryURL = dataUrl
        
        do {
            try task.run()
            NSApplication.shared.terminate(nil)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error Launching Game"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            // Show launcher if launch fails?
            viewModel.isGameInstalled = false
            applicationDidFinishLaunching(Notification(name: Notification.Name("Restart")))
        }
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit REDRIVER2 Launcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Tools Menu
        let toolsMenuItem = NSMenuItem()
        toolsMenuItem.title = "Options"
        mainMenu.addItem(toolsMenuItem)
        let toolsMenu = NSMenu(title: "Options")
        toolsMenuItem.submenu = toolsMenu
        
        toolsMenu.addItem(withTitle: "Re-extract Discs...", action: #selector(reinstall), keyEquivalent: "r")
        toolsMenu.addItem(withTitle: "Convert FMVs...", action: #selector(convertFMV), keyEquivalent: "f")
        toolsMenu.addItem(withTitle: "Cleanup Unnecessary Files...", action: #selector(cleanupFiles), keyEquivalent: "c")
        toolsMenu.addItem(NSMenuItem.separator())
        toolsMenu.addItem(withTitle: "Toggle Debug Inspector", action: #selector(toggleDebug), keyEquivalent: "d")
        toolsMenu.addItem(NSMenuItem.separator())
        toolsMenu.addItem(withTitle: "Reset Installation", action: #selector(resetApp), keyEquivalent: "R")
        
        NSApp.mainMenu = mainMenu
    }
    
    func ensureWindowSize() {
        guard let window = window else { return }
        
        let targetSize = NSSize(width: 500, height: 380)
        
        // Only resize if significantly different
        if abs(window.frame.width - targetSize.width) > 1 || abs(window.frame.height - targetSize.height) > 1 {
            var frame = window.frame
            frame.origin.y += frame.size.height // anchor top-left
            frame.origin.y -= targetSize.height
            frame.size = targetSize
            
            window.setFrame(frame, display: true, animate: true)
        }
        window.center()
    }
    
    @objc func toggleDebug() {
        viewModel.showDebug.toggle()
    }
    
    @objc func reinstall() {
        viewModel.activeTab = "install"
        viewModel.isGameInstalled = false // Force UI update
        ensureWindowSize()
    }
    
    @objc func convertFMV() {
        viewModel.startFMVConversion()
        ensureWindowSize()
    }
    
    @objc func cleanupFiles() {
        viewModel.manualCleanup()
        ensureWindowSize()
    }
    
    @objc func resetApp() {
        let alert = NSAlert()
        alert.messageText = "Reset Installation?"
        alert.informativeText = "This will delete extracted files and reset the launcher to the installation screen. Are you sure?"
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.resetInstallation()
            ensureWindowSize()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct MainView: View {
    @ObservedObject var viewModel: InstallerViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isInstalling {
                ProgressScreen(viewModel: viewModel)
            } else {
                if viewModel.activeTab == "install" {
                    InstallScreen(viewModel: viewModel)
                } else {
                    LauncherScreen(viewModel: viewModel)
                }
            }
            
            if viewModel.showDebug {
                DebugView(viewModel: viewModel)
            }
        }
        .padding(20)
        .alert(isPresented: $viewModel.showSuccess) {
            Alert(title: Text("Success"), message: Text(viewModel.statusMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct LauncherScreen: View {
    @ObservedObject var viewModel: InstallerViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("REDRIVER2")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("Ready to Play")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Language:")
                    Picker("", selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.languages.keys.sorted(), id: \.self) { key in
                            Text(viewModel.languages[key] ?? "Unknown").tag(key)
                        }
                    }
                    .frame(width: 140)
                    .onChange(of: viewModel.selectedLanguage) { _ in
                        viewModel.saveConfig()
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
            
            Button(action: {
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.launchGame()
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Game")
                        .fontWeight(.bold)
                }
                .frame(minWidth: 150)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Use 'Options' menu to re-install or convert FMVs.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
    }
}

struct ProgressScreen: View {
    @ObservedObject var viewModel: InstallerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView(value: viewModel.progress > 0 ? viewModel.progress : nil) {
                Text(viewModel.statusMessage)
                    .font(.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            .padding()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Back") {
                    viewModel.isInstalling = false
                    viewModel.errorMessage = nil
                }
            }
            
            // Log View
            VStack(alignment: .leading) {
                Text("Log:")
                    .font(.caption)
                    .fontWeight(.bold)
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.logText)
                            .font(.system(size: 10, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(5)
                            .id("logBottom")
                    }
                    .frame(height: 150)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(5)
                    .onChange(of: viewModel.logText) { _ in
                        withAnimation {
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

struct InstallScreen: View {
    @ObservedObject var viewModel: InstallerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Install REDRIVER2")
                        .font(.headline)
                    Text("Please provide the original PlayStation game discs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 10)

            // Disc 1
            VStack(alignment: .leading, spacing: 5) {
                Text("Driver 2 - Disc 1 (ISO/BIN)")
                    .font(.caption)
                    .fontWeight(.bold)
                HStack {
                    TextField("Select Disc 1 image...", text: $viewModel.disc1Path)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Browse...") {
                        selectFile { path in viewModel.disc1Path = path }
                    }
                }
            }

            // Single Disc Toggle
            Toggle("I have a single merged disc image", isOn: $viewModel.isSingleDisc)
                .toggleStyle(CheckboxToggleStyle())
                .font(.callout)

            // Disc 2
            VStack(alignment: .leading, spacing: 5) {
                Text("Driver 2 - Disc 2 (ISO/BIN)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.isSingleDisc ? .secondary : .primary)
                HStack {
                    TextField("Select Disc 2 image...", text: $viewModel.disc2Path)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isSingleDisc)
                    Button("Browse...") {
                        selectFile { path in viewModel.disc2Path = path }
                    }
                    .disabled(viewModel.isSingleDisc)
                }
            }
            .opacity(viewModel.isSingleDisc ? 0.5 : 1.0)

            Divider()

            // FMV Option
            HStack(alignment: .top) {
                Toggle("Convert FMV Cutscenes", isOn: $viewModel.convertFMV)
                    .toggleStyle(CheckboxToggleStyle())
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("Required for in-game videos.\nTakes ~2-5 mins.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: {
                    viewModel.startInstall()
                }) {
                    Text("Install")
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(isInstallEnabled ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isInstallEnabled)
            }
        }
    }
    
    var isInstallEnabled: Bool {
        // Disc 1 is always required
        guard !viewModel.disc1Path.isEmpty else { return false }
        
        // If not single disc, Disc 2 is also required
        if !viewModel.isSingleDisc && viewModel.disc2Path.isEmpty {
            return false
        }
        
        return true
    }

    func selectFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.data] 
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url.path)
            }
        }
    }
}

struct DebugView: View {
    @ObservedObject var viewModel: InstallerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("DEBUG INSPECTOR").font(.headline).foregroundColor(.green)
            Group {
                Text("isInstalling: \(String(describing: viewModel.isInstalling))")
                Text("activeTab: \(viewModel.activeTab)")
                Text("isGameInstalled: \(String(describing: viewModel.isGameInstalled))")
                Text("progress: \(String(format: "%.2f", viewModel.progress))")
                Text("status: \(viewModel.statusMessage)")
            }
            Group {
                Text("error: \(viewModel.errorMessage ?? "nil")")
                Text("disc1: \(viewModel.disc1Path)")
                Text("convertFMV: \(String(describing: viewModel.convertFMV))")
            }
            Divider()
            ScrollView {
                Text(viewModel.logText)
                    .font(.system(size: 8, design: .monospaced))
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .font(.system(size: 10, design: .monospaced))
        .frame(width: 300)
        .cornerRadius(10)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

// Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
