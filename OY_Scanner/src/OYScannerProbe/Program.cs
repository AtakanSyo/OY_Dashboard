using System.Collections.Concurrent;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace OYScannerProbe;

internal static class Program
{
    internal static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = false,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private static readonly CancellationTokenSource Shutdown = new();

    public static async Task<int> Main(string[] args)
    {
        Console.CancelKeyPress += (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            Shutdown.Cancel();
        };

        var options = ProbeOptions.FromArgs(args);
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            Console.Error.WriteLine("OYScannerProbe sadece Windows uzerinde calisir.");
            return 2;
        }

        var configPath = ProbeConfig.ResolveConfigPath(options.ConfigPath);
        var config = ProbeConfig.Load(configPath);
        config.ApplyOverrides(options);

        var runId = DateTimeOffset.Now.ToString("yyyyMMdd-HHmmss");
        var outputRoot = Path.GetFullPath(config.OutputDirectory);
        var runDirectory = Path.Combine(outputRoot, $"run-{runId}");
        Directory.CreateDirectory(runDirectory);

        using var log = new ProbeLog(runDirectory);
        log.Event("probe.start", new
        {
            runId,
            machine = Environment.MachineName,
            user = Environment.UserName,
            os = Environment.OSVersion.ToString(),
            processArchitecture = RuntimeInformation.ProcessArchitecture.ToString(),
            configPath,
            config
        });

        Console.WriteLine("OY Scanner Probe basladi.");
        Console.WriteLine($"Log klasoru: {runDirectory}");
        Console.WriteLine("Bitirmek icin Ctrl+C.");

        using var watchers = new FileWatchHub(config, log);
        watchers.Start();

        var tasks = new List<Task>
        {
            SnapshotLoop.RunAsync(config, log, Shutdown.Token)
        };

        if (options.DurationMinutes is > 0)
        {
            tasks.Add(Task.Run(async () =>
            {
                await Task.Delay(TimeSpan.FromMinutes(options.DurationMinutes.Value), Shutdown.Token);
                Shutdown.Cancel();
            }));
        }

        try
        {
            await Task.WhenAny(tasks);
        }
        catch (OperationCanceledException)
        {
            // Normal shutdown.
        }
        finally
        {
            Shutdown.Cancel();
            log.Event("probe.stop", new { stoppedAt = DateTimeOffset.Now });
            Console.WriteLine("OY Scanner Probe durdu.");
        }

        return 0;
    }
}

internal sealed class ProbeOptions
{
    public string ConfigPath { get; private init; } = "probe.config.json";
    public List<string> ExtraWatchPaths { get; } = [];
    public int? DurationMinutes { get; private init; }
    public string? OutputDirectory { get; private init; }

    public static ProbeOptions FromArgs(string[] args)
    {
        var options = new ProbeOptions();

        for (var i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            string? NextValue()
            {
                if (i + 1 >= args.Length)
                {
                    throw new ArgumentException($"{arg} icin deger bekleniyor.");
                }

                return args[++i];
            }

            switch (arg)
            {
                case "--config":
                    options = withConfig(NextValue()!);
                    break;
                case "--watch":
                    options.ExtraWatchPaths.Add(NextValue()!);
                    break;
                case "--duration-minutes":
                    options = withDuration(int.Parse(NextValue()!));
                    break;
                case "--out":
                    options = withOutput(NextValue()!);
                    break;
                case "--help":
                case "-h":
                    PrintHelpAndExit();
                    break;
                default:
                    throw new ArgumentException($"Bilinmeyen arguman: {arg}");
            }
        }

        return options;

        ProbeOptions withConfig(string value) => new ProbeOptions()
        {
            ConfigPath = value,
            DurationMinutes = options.DurationMinutes,
            OutputDirectory = options.OutputDirectory
        }.CopyWatchPathsFrom(options);

        ProbeOptions withDuration(int value) => new ProbeOptions()
        {
            ConfigPath = options.ConfigPath,
            DurationMinutes = value,
            OutputDirectory = options.OutputDirectory
        }.CopyWatchPathsFrom(options);

        ProbeOptions withOutput(string value) => new ProbeOptions()
        {
            ConfigPath = options.ConfigPath,
            DurationMinutes = options.DurationMinutes,
            OutputDirectory = value
        }.CopyWatchPathsFrom(options);
    }

    private ProbeOptions CopyWatchPathsFrom(ProbeOptions source)
    {
        ExtraWatchPaths.AddRange(source.ExtraWatchPaths);
        return this;
    }

    private static void PrintHelpAndExit()
    {
        Console.WriteLine("""
        OYScannerProbe

        Kullanim:
          OYScannerProbe.exe --config .\probe.config.json --duration-minutes 30
          OYScannerProbe.exe --watch "C:\eSole\Output" --out ".\logs"

        Argumanlar:
          --config <path>              Ayar dosyasi. Varsayilan: probe.config.json
          --watch <path>               Ek izlenecek klasor. Birden fazla verilebilir.
          --duration-minutes <number>  Belirtilen sure sonunda otomatik kapanir.
          --out <path>                 Log kok klasoru.
        """);
        Environment.Exit(0);
    }
}

internal sealed class ProbeConfig
{
    public List<string> TargetProcessNames { get; set; } = ["eSole", "ESole", "eFoot", "eFoot-touch", "FootScan", "Scanner"];
    public List<string> WatchPaths { get; set; } = ["D:\\eFoot V3.2.112", "C:\\ProgramData", "C:\\Users\\Public\\Documents", "%USERPROFILE%\\Documents", "%USERPROFILE%\\Desktop", "%LOCALAPPDATA%", "%APPDATA%"];
    public string OutputDirectory { get; set; } = "logs";
    public int SnapshotIntervalSeconds { get; set; } = 5;
    public bool IncludeProcessSnapshots { get; set; } = true;
    public bool IncludeNetworkSnapshots { get; set; } = true;
    public bool IncludeDeviceSnapshots { get; set; } = true;
    public bool IncludeServiceSnapshots { get; set; } = true;
    public bool IncludePipeSnapshots { get; set; } = true;
    public bool IncludeTargetModules { get; set; } = true;

    public static string ResolveConfigPath(string path)
    {
        if (Path.IsPathRooted(path) || File.Exists(path))
        {
            return path;
        }

        var appDirectory = AppContext.BaseDirectory;
        var appRelativePath = Path.Combine(appDirectory, path);
        return File.Exists(appRelativePath) ? appRelativePath : path;
    }

    public static ProbeConfig Load(string path)
    {
        if (!File.Exists(path))
        {
            return new ProbeConfig();
        }

        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<ProbeConfig>(json, ProgramJsonContext.Default.ProbeConfig) ?? new ProbeConfig();
    }

    public void ApplyOverrides(ProbeOptions options)
    {
        foreach (var path in options.ExtraWatchPaths)
        {
            WatchPaths.Add(path);
        }

        if (!string.IsNullOrWhiteSpace(options.OutputDirectory))
        {
            OutputDirectory = options.OutputDirectory;
        }

        SnapshotIntervalSeconds = Math.Max(1, SnapshotIntervalSeconds);
        WatchPaths = WatchPaths
            .Where(path => !string.IsNullOrWhiteSpace(path))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}

[JsonSerializable(typeof(ProbeConfig))]
internal sealed partial class ProgramJsonContext : JsonSerializerContext;

internal sealed class ProbeLog : IDisposable
{
    private readonly object _gate = new();
    private readonly StreamWriter _events;
    private readonly StreamWriter _processSnapshots;
    private readonly StreamWriter _targetProcess;
    private readonly StreamWriter _devices;
    private readonly StreamWriter _pipes;
    private readonly StreamWriter _fileEvents;
    private readonly StreamWriter _netstat;
    private readonly StreamWriter _services;

    public string RunDirectory { get; }

    public ProbeLog(string runDirectory)
    {
        RunDirectory = runDirectory;
        _events = Writer("events.ndjson");
        _processSnapshots = Writer("process-snapshots.ndjson");
        _targetProcess = Writer("target-process.ndjson");
        _devices = Writer("devices.ndjson");
        _pipes = Writer("pipes.ndjson");
        _fileEvents = Writer("file-events.ndjson");
        _netstat = Writer("netstat.txt");
        _services = Writer("services.txt");
    }

    public void Event(string type, object payload) => JsonLine(_events, type, payload);
    public void ProcessSnapshot(object payload) => JsonLine(_processSnapshots, "process.snapshot", payload);
    public void TargetProcess(object payload) => JsonLine(_targetProcess, "target.process", payload);
    public void DeviceSnapshot(object payload) => JsonLine(_devices, "device.snapshot", payload);
    public void PipeSnapshot(object payload) => JsonLine(_pipes, "pipe.snapshot", payload);
    public void FileEvent(object payload) => JsonLine(_fileEvents, "file.event", payload);

    public void Netstat(string text) => TextBlock(_netstat, "netstat", text);
    public void Services(string text) => TextBlock(_services, "services", text);

    private StreamWriter Writer(string name)
    {
        return new StreamWriter(File.Open(Path.Combine(RunDirectory, name), FileMode.Create, FileAccess.Write, FileShare.Read))
        {
            AutoFlush = true
        };
    }

    private void JsonLine(StreamWriter writer, string type, object payload)
    {
        var record = new
        {
            timestamp = DateTimeOffset.Now,
            type,
            payload
        };

        lock (_gate)
        {
            writer.WriteLine(JsonSerializer.Serialize(record, Program.JsonOptions));
        }
    }

    private void TextBlock(StreamWriter writer, string label, string text)
    {
        lock (_gate)
        {
            writer.WriteLine($"===== {label} {DateTimeOffset.Now:O} =====");
            writer.WriteLine(text);
            writer.WriteLine();
        }
    }

    public void Dispose()
    {
        lock (_gate)
        {
            _events.Dispose();
            _processSnapshots.Dispose();
            _targetProcess.Dispose();
            _devices.Dispose();
            _pipes.Dispose();
            _fileEvents.Dispose();
            _netstat.Dispose();
            _services.Dispose();
        }
    }
}

internal sealed class FileWatchHub : IDisposable
{
    private readonly ProbeConfig _config;
    private readonly ProbeLog _log;
    private readonly List<FileSystemWatcher> _watchers = [];
    private readonly ConcurrentDictionary<string, DateTimeOffset> _lastEvents = new(StringComparer.OrdinalIgnoreCase);

    public FileWatchHub(ProbeConfig config, ProbeLog log)
    {
        _config = config;
        _log = log;
    }

    public void Start()
    {
        foreach (var rawPath in _config.WatchPaths)
        {
            try
            {
                var path = Environment.ExpandEnvironmentVariables(rawPath);
                if (!Directory.Exists(path))
                {
                    _log.Event("watch.skip", new { path, reason = "directory_not_found" });
                    continue;
                }

                var watcher = new FileSystemWatcher(path)
                {
                    IncludeSubdirectories = true,
                    EnableRaisingEvents = true,
                    NotifyFilter = NotifyFilters.FileName
                                   | NotifyFilters.DirectoryName
                                   | NotifyFilters.LastWrite
                                   | NotifyFilters.Size
                                   | NotifyFilters.CreationTime
                };

                watcher.Created += OnFileEvent;
                watcher.Changed += OnFileEvent;
                watcher.Deleted += OnFileEvent;
                watcher.Renamed += OnRenamed;
                watcher.Error += (_, args) => _log.Event("watch.error", new { path, error = args.GetException().Message });

                _watchers.Add(watcher);
                _log.Event("watch.start", new { path });
            }
            catch (Exception ex)
            {
                _log.Event("watch.fail", new { path = rawPath, error = ex.Message });
            }
        }
    }

    private void OnFileEvent(object sender, FileSystemEventArgs args)
    {
        var key = $"{args.ChangeType}|{args.FullPath}";
        var now = DateTimeOffset.Now;
        if (_lastEvents.TryGetValue(key, out var last) && now - last < TimeSpan.FromMilliseconds(250))
        {
            return;
        }

        _lastEvents[key] = now;
        _log.FileEvent(new
        {
            changeType = args.ChangeType.ToString(),
            path = args.FullPath,
            exists = File.Exists(args.FullPath) || Directory.Exists(args.FullPath),
            extension = Path.GetExtension(args.FullPath)
        });
    }

    private void OnRenamed(object sender, RenamedEventArgs args)
    {
        _log.FileEvent(new
        {
            changeType = args.ChangeType.ToString(),
            oldPath = args.OldFullPath,
            path = args.FullPath,
            exists = File.Exists(args.FullPath) || Directory.Exists(args.FullPath),
            extension = Path.GetExtension(args.FullPath)
        });
    }

    public void Dispose()
    {
        foreach (var watcher in _watchers)
        {
            watcher.Dispose();
        }
    }
}

internal static class SnapshotLoop
{
    public static async Task RunAsync(ProbeConfig config, ProbeLog log, CancellationToken cancellationToken)
    {
        var previousProcessIds = new HashSet<int>();

        while (!cancellationToken.IsCancellationRequested)
        {
            var processes = Process.GetProcesses();
            var currentProcessIds = processes.Select(process => process.Id).ToHashSet();

            if (config.IncludeProcessSnapshots)
            {
                var started = currentProcessIds.Except(previousProcessIds).OrderBy(id => id).ToArray();
                var stopped = previousProcessIds.Except(currentProcessIds).OrderBy(id => id).ToArray();

                log.ProcessSnapshot(new
                {
                    count = processes.Length,
                    started,
                    stopped,
                    processes = processes
                        .OrderBy(process => process.ProcessName, StringComparer.OrdinalIgnoreCase)
                        .ThenBy(process => process.Id)
                        .Select(ProcessInfo.SafeCreate)
                        .ToArray()
                });
            }

            LogTargetProcesses(config, log, processes);

            if (config.IncludeNetworkSnapshots)
            {
                log.Netstat(await CommandRunner.RunAsync("netstat.exe", "-ano", cancellationToken));
            }

            if (config.IncludeDeviceSnapshots)
            {
                log.DeviceSnapshot(new
                {
                    usb = await PowerShellRunner.RunAsync("Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'USB' -or $_.DeviceID -like 'USB*' } | Select-Object Name,Manufacturer,PNPClass,DeviceID,Status | ConvertTo-Json -Depth 3", cancellationToken),
                    comPorts = await PowerShellRunner.RunAsync("Get-CimInstance Win32_SerialPort | Select-Object DeviceID,Name,Description,PNPDeviceID,Status | ConvertTo-Json -Depth 3", cancellationToken),
                    diskDrives = await PowerShellRunner.RunAsync("Get-CimInstance Win32_DiskDrive | Select-Object Model,InterfaceType,SerialNumber,PNPDeviceID,Status | ConvertTo-Json -Depth 3", cancellationToken)
                });
            }

            if (config.IncludeServiceSnapshots)
            {
                log.Services(await CommandRunner.RunAsync("sc.exe", "queryex type= service state= all", cancellationToken));
            }

            if (config.IncludePipeSnapshots)
            {
                log.PipeSnapshot(new
                {
                    pipes = ListNamedPipes()
                });
            }

            previousProcessIds = currentProcessIds;
            processes.DisposeAll();

            await Task.Delay(TimeSpan.FromSeconds(config.SnapshotIntervalSeconds), cancellationToken);
        }
    }

    private static void LogTargetProcesses(ProbeConfig config, ProbeLog log, Process[] processes)
    {
        var targets = processes
            .Where(process => config.TargetProcessNames.Any(target =>
                process.ProcessName.Contains(target, StringComparison.OrdinalIgnoreCase)))
            .ToArray();

        foreach (var process in targets)
        {
            log.TargetProcess(new
            {
                process = ProcessInfo.SafeCreate(process),
                modules = config.IncludeTargetModules ? ProcessModuleInfo.SafeCreate(process) : null
            });
        }
    }

    private static string[] ListNamedPipes()
    {
        try
        {
            return Directory.GetFiles(@"\\.\pipe\")
                .Select(Path.GetFileName)
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .Order(StringComparer.OrdinalIgnoreCase)
                .ToArray()!;
        }
        catch
        {
            return [];
        }
    }
}

internal sealed record ProcessInfo(
    int Id,
    string Name,
    string? MainWindowTitle,
    string? FileName,
    DateTime? StartTime,
    long? WorkingSet64,
    int? SessionId)
{
    public static ProcessInfo SafeCreate(Process process)
    {
        string? fileName = null;
        DateTime? startTime = null;
        long? workingSet = null;
        int? sessionId = null;

        try { fileName = process.MainModule?.FileName; } catch { }
        try { startTime = process.StartTime; } catch { }
        try { workingSet = process.WorkingSet64; } catch { }
        try { sessionId = process.SessionId; } catch { }

        return new ProcessInfo(
            process.Id,
            process.ProcessName,
            Safe(() => process.MainWindowTitle),
            fileName,
            startTime,
            workingSet,
            sessionId);
    }

    private static string? Safe(Func<string?> value)
    {
        try { return value(); } catch { return null; }
    }
}

internal sealed record ProcessModuleInfo(string ModuleName, string? FileName, string? FileVersion)
{
    public static ProcessModuleInfo[] SafeCreate(Process process)
    {
        try
        {
            return process.Modules
                .OfType<ProcessModule>()
                .Select(module => new ProcessModuleInfo(
                    module.ModuleName,
                    module.FileName,
                    module.FileVersionInfo.FileVersion))
                .OrderBy(module => module.FileName, StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }
        catch
        {
            return [];
        }
    }
}

internal static class CommandRunner
{
    public static async Task<string> RunAsync(string fileName, string arguments, CancellationToken cancellationToken)
    {
        try
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            process.Start();
            var output = await process.StandardOutput.ReadToEndAsync(cancellationToken);
            var error = await process.StandardError.ReadToEndAsync(cancellationToken);
            await process.WaitForExitAsync(cancellationToken);

            return string.IsNullOrWhiteSpace(error) ? output : $"{output}{Environment.NewLine}[stderr]{Environment.NewLine}{error}";
        }
        catch (Exception ex)
        {
            return $"command_failed: {fileName} {arguments}{Environment.NewLine}{ex}";
        }
    }
}

internal static class PowerShellRunner
{
    public static Task<string> RunAsync(string command, CancellationToken cancellationToken)
    {
        var encoded = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
        return CommandRunner.RunAsync("powershell.exe", $"-NoProfile -ExecutionPolicy Bypass -EncodedCommand {encoded}", cancellationToken);
    }
}

internal static class ProcessExtensions
{
    public static void DisposeAll(this IEnumerable<Process> processes)
    {
        foreach (var process in processes)
        {
            process.Dispose();
        }
    }
}
