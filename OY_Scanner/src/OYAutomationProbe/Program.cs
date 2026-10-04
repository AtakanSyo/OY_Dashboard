using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using System.Windows.Automation;

namespace OYAutomationProbe;

internal static class Program
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private static volatile bool StopRequested;

    [STAThread]
    public static int Main(string[] args)
    {
        try
        {
            var options = ProbeOptions.FromArgs(args);
            var runId = DateTimeOffset.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture);
            var outputDirectory = Path.GetFullPath(Environment.ExpandEnvironmentVariables(Path.Combine(options.OutputDirectory, $"run-{runId}")));
            Directory.CreateDirectory(outputDirectory);

            Console.CancelKeyPress += (_, eventArgs) =>
            {
                eventArgs.Cancel = true;
                StopRequested = true;
                Console.WriteLine();
                Console.WriteLine("Durdurma istegi alindi. Son islem tamamlaninca kapanacak...");
            };

            Console.WriteLine("OY Automation Probe basladi.");
            Console.WriteLine($"Cikti klasoru: {outputDirectory}");
            Console.WriteLine(options.Once
                ? "Tek snapshot modu: islem bitince kapanacak."
                : $"Surekli mod: {options.IntervalSeconds} saniyede bir snapshot alacak. Bitirmek icin Ctrl+C.");
            Console.WriteLine();

            var snapshotIndex = 1;
            do
            {
                var result = Capture(options);
                var fileStamp = snapshotIndex.ToString("000", CultureInfo.InvariantCulture);
                var jsonPath = Path.Combine(outputDirectory, $"automation-probe-{fileStamp}.json");
                var markdownPath = Path.Combine(outputDirectory, $"automation-probe-{fileStamp}.md");

                File.WriteAllText(jsonPath, JsonSerializer.Serialize(result, JsonOptions), Encoding.UTF8);
                File.WriteAllText(markdownPath, ReportWriter.WriteMarkdown(result), Encoding.UTF8);

                Console.WriteLine($"Snapshot {fileStamp}: pencere={result.Windows.Count}, hedef={result.TargetReports.Count}");
                Console.WriteLine($"  JSON: {jsonPath}");
                Console.WriteLine($"  Rapor: {markdownPath}");

                if (options.Once)
                {
                    break;
                }

                snapshotIndex++;
                WaitForNextSnapshot(options.IntervalSeconds);
            }
            while (!StopRequested);

            Console.WriteLine();
            Console.WriteLine("OY Automation Probe durdu.");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return 1;
        }
    }

    private static void WaitForNextSnapshot(int intervalSeconds)
    {
        var deadline = DateTimeOffset.UtcNow.AddSeconds(Math.Max(1, intervalSeconds));
        while (!StopRequested && DateTimeOffset.UtcNow < deadline)
        {
            Thread.Sleep(200);
        }
    }

    private static ProbeResult Capture(ProbeOptions options)
    {
        var windows = WindowEnumerator.GetTopLevelWindows();
        var targets = FindTargets(windows, options).ToList();

        var reports = new List<WindowAutomationReport>();
        foreach (var target in targets.Take(options.MaxWindows))
        {
            reports.Add(AutomationInspector.Inspect(target, options));
        }

        return new ProbeResult(
            DateTimeOffset.Now,
            Environment.MachineName,
            Environment.UserName,
            options.ToReportOptions(),
            options.IncludeRawWindows ? windows : [],
            reports);
    }

    private static IEnumerable<WindowInfo> FindTargets(List<WindowInfo> windows, ProbeOptions options)
    {
        if (options.AllWindows)
        {
            return windows.Where(window => window.Visible && !string.IsNullOrWhiteSpace(window.Title));
        }

        return windows.Where(window =>
            window.Visible &&
            options.Targets.Any(target =>
                Contains(window.Title, target) ||
                Contains(window.ProcessName, target) ||
                Contains(window.ClassName, target) ||
                Contains(window.ExecutablePath, target)));
    }

    private static bool Contains(string? value, string target)
    {
        return !string.IsNullOrWhiteSpace(value) && value.Contains(target, StringComparison.OrdinalIgnoreCase);
    }
}

internal sealed record ProbeOptions
{
    public List<string> Targets { get; init; } = ["eFoot", "eFoot-touch"];
    public string OutputDirectory { get; init; } = "automation-analysis";
    public int MaxDepth { get; init; } = 8;
    public int MaxNodes { get; init; } = 800;
    public int MaxWindows { get; init; } = 5;
    public bool AllWindows { get; init; }
    public bool IncludeInvisibleElements { get; init; }
    public bool IncludeRawWindows { get; init; } = true;
    public bool Once { get; init; }
    public int IntervalSeconds { get; init; } = 5;

    public static ProbeOptions FromArgs(string[] args)
    {
        var options = new ProbeOptions();

        for (var i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            string NextValue()
            {
                if (i + 1 >= args.Length)
                {
                    throw new ArgumentException($"{arg} icin deger bekleniyor.");
                }

                return args[++i];
            }

            options = arg switch
            {
                "--target" => options with { Targets = [NextValue()] },
                "--add-target" => options with { Targets = [.. options.Targets, NextValue()] },
                "--out" => options with { OutputDirectory = NextValue() },
                "--max-depth" => options with { MaxDepth = Math.Max(1, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--max-nodes" => options with { MaxNodes = Math.Max(20, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--max-windows" => options with { MaxWindows = Math.Max(1, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--all-windows" => options with { AllWindows = true },
                "--include-invisible" => options with { IncludeInvisibleElements = true },
                "--hide-window-list" => options with { IncludeRawWindows = false },
                "--once" => options with { Once = true },
                "--interval-seconds" => options with { IntervalSeconds = Math.Max(1, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--help" or "-h" => PrintHelpAndExit(),
                _ => throw new ArgumentException($"Bilinmeyen arguman: {arg}")
            };
        }

        return options;
    }

    public object ToReportOptions() => new
    {
        Targets,
        MaxDepth,
        MaxNodes,
        MaxWindows,
        AllWindows,
        IncludeInvisibleElements,
        IncludeRawWindows,
        Once,
        IntervalSeconds
    };

    private static ProbeOptions PrintHelpAndExit()
    {
        Console.WriteLine("""
        OYAutomationProbe

        Kullanim:
          OYAutomationProbe.exe
          OYAutomationProbe.exe --target eFoot --max-depth 10
          OYAutomationProbe.exe --all-windows --max-windows 20
          OYAutomationProbe.exe --once

        Argumanlar:
          --target <text>          Hedef pencere/process/class filtresi. Varsayilan: eFoot/eFoot-touch
          --add-target <text>      Ek hedef filtresi ekler.
          --out <path>             Cikti ana klasoru. Varsayilan: automation-analysis
          --max-depth <n>          UI Automation agaci derinligi. Varsayilan: 8
          --max-nodes <n>          Pencere basina node limiti. Varsayilan: 800
          --max-windows <n>        Hedef pencere limiti. Varsayilan: 5
          --all-windows            Tum gorunur pencereleri inceler.
          --include-invisible      UI agacinda offscreen/gorunmez elementleri de listeler.
          --hide-window-list       JSON icinde ham pencere listesini saklamaz.
          --once                   Tek snapshot alip kapanir.
          --interval-seconds <n>   Snapshot araligi. Varsayilan: 5
        """);
        Environment.Exit(0);
        return new ProbeOptions();
    }
}

internal static class WindowEnumerator
{
    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out NativeRect rect);

    public static List<WindowInfo> GetTopLevelWindows()
    {
        var windows = new List<WindowInfo>();
        EnumWindows((hWnd, _) =>
        {
            windows.Add(CreateWindowInfo(hWnd));
            return true;
        }, IntPtr.Zero);

        return windows
            .OrderByDescending(window => window.Visible)
            .ThenBy(window => window.ProcessName, StringComparer.OrdinalIgnoreCase)
            .ThenBy(window => window.Title, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static WindowInfo CreateWindowInfo(IntPtr hWnd)
    {
        var titleBuilder = new StringBuilder(512);
        GetWindowText(hWnd, titleBuilder, titleBuilder.Capacity);

        var classBuilder = new StringBuilder(256);
        GetClassName(hWnd, classBuilder, classBuilder.Capacity);

        GetWindowThreadProcessId(hWnd, out var processId);
        GetWindowRect(hWnd, out var rect);

        string? processName = null;
        string? executablePath = null;
        try
        {
            using var process = Process.GetProcessById((int)processId);
            processName = process.ProcessName;
            try { executablePath = process.MainModule?.FileName; } catch { }
        }
        catch
        {
            // Process may exit while enumerating.
        }

        return new WindowInfo(
            hWnd.ToInt64(),
            IsWindowVisible(hWnd),
            titleBuilder.ToString(),
            classBuilder.ToString(),
            (int)processId,
            processName,
            executablePath,
            RectInfo.FromNative(rect));
    }
}

internal static class AutomationInspector
{
    private static readonly AutomationPattern[] InterestingPatterns =
    [
        InvokePattern.Pattern,
        ValuePattern.Pattern,
        TextPattern.Pattern,
        TogglePattern.Pattern,
        SelectionPattern.Pattern,
        SelectionItemPattern.Pattern,
        ExpandCollapsePattern.Pattern,
        ScrollPattern.Pattern,
        RangeValuePattern.Pattern,
    ];

    public static WindowAutomationReport Inspect(WindowInfo window, ProbeOptions options)
    {
        try
        {
            var element = AutomationElement.FromHandle(new IntPtr(window.Handle));
            if (element is null)
            {
                return new WindowAutomationReport(window, "AutomationElement.FromHandle null dondu.", 0, [], []);
            }

            var nodes = new List<AutomationNode>();
            Walk(element, null, 0, "0", options, nodes);

            var actionable = nodes
                .Where(node => node.Patterns.Count > 0 || !string.IsNullOrWhiteSpace(node.AutomationId))
                .Take(250)
                .ToList();

            return new WindowAutomationReport(window, null, nodes.Count, nodes, actionable);
        }
        catch (Exception ex)
        {
            return new WindowAutomationReport(window, ex.Message, 0, [], []);
        }
    }

    private static void Walk(AutomationElement element, AutomationNode? parent, int depth, string path, ProbeOptions options, List<AutomationNode> nodes)
    {
        if (nodes.Count >= options.MaxNodes)
        {
            return;
        }

        var node = CreateNode(element, parent?.Path, depth, path);
        if (!node.IsOffscreen || options.IncludeInvisibleElements || depth == 0)
        {
            nodes.Add(node);
        }

        if (depth >= options.MaxDepth)
        {
            return;
        }

        AutomationElement? child;
        try
        {
            child = TreeWalker.ControlViewWalker.GetFirstChild(element);
        }
        catch
        {
            return;
        }

        var index = 0;
        while (child is not null && nodes.Count < options.MaxNodes)
        {
            Walk(child, node, depth + 1, $"{path}.{index}", options, nodes);
            index++;

            try
            {
                child = TreeWalker.ControlViewWalker.GetNextSibling(child);
            }
            catch
            {
                break;
            }
        }
    }

    private static AutomationNode CreateNode(AutomationElement element, string? parentPath, int depth, string path)
    {
        string? name = Safe(() => element.Current.Name);
        string? automationId = Safe(() => element.Current.AutomationId);
        string? className = Safe(() => element.Current.ClassName);
        string? localizedControlType = Safe(() => element.Current.LocalizedControlType);
        string? controlType = Safe(() => element.Current.ControlType.ProgrammaticName.Replace("ControlType.", string.Empty));
        string? frameworkId = Safe(() => element.Current.FrameworkId);
        var processId = Safe(() => element.Current.ProcessId, 0);
        var isEnabled = Safe(() => element.Current.IsEnabled, false);
        var isOffscreen = Safe(() => element.Current.IsOffscreen, true);
        var hasKeyboardFocus = Safe(() => element.Current.HasKeyboardFocus, false);
        var rectangle = RectInfo.FromWpf(Safe(() => element.Current.BoundingRectangle, Rect.Empty));
        var patterns = GetSupportedPatterns(element);
        var value = TryGetValue(element);
        string? legacyName = null;

        return new AutomationNode(
            path,
            parentPath,
            depth,
            name,
            automationId,
            className,
            controlType,
            localizedControlType,
            frameworkId,
            processId,
            isEnabled,
            isOffscreen,
            hasKeyboardFocus,
            rectangle,
            patterns,
            value,
            legacyName);
    }

    private static List<string> GetSupportedPatterns(AutomationElement element)
    {
        var names = new List<string>();
        foreach (var pattern in InterestingPatterns)
        {
            try
            {
                if (element.TryGetCurrentPattern(pattern, out _))
                {
                    names.Add(pattern.ProgrammaticName.Replace("PatternIdentifiers.Pattern", string.Empty).Replace("Pattern", string.Empty));
                }
            }
            catch
            {
                // Ignore pattern failures.
            }
        }

        return names.Order(StringComparer.OrdinalIgnoreCase).ToList();
    }

    private static string? TryGetValue(AutomationElement element)
    {
        try
        {
            if (element.TryGetCurrentPattern(ValuePattern.Pattern, out var pattern))
            {
                return ((ValuePattern)pattern).Current.Value;
            }
        }
        catch
        {
            // Ignore inaccessible values.
        }

        return null;
    }

    private static T? Safe<T>(Func<T> value)
    {
        try { return value(); }
        catch { return default; }
    }

    private static T Safe<T>(Func<T> value, T fallback)
    {
        try { return value(); }
        catch { return fallback; }
    }
}

internal static class ReportWriter
{
    public static string WriteMarkdown(ProbeResult result)
    {
        var builder = new StringBuilder();
        builder.AppendLine("# OY Automation Probe");
        builder.AppendLine();
        builder.AppendLine($"Generated: {result.GeneratedAt:O}");
        builder.AppendLine($"Machine: `{result.MachineName}`");
        builder.AppendLine($"User: `{result.UserName}`");
        builder.AppendLine($"Target windows: {result.TargetReports.Count}");
        builder.AppendLine();

        builder.AppendLine("## Target Reports");
        builder.AppendLine();
        foreach (var report in result.TargetReports)
        {
            builder.AppendLine($"### {ValueOrEmpty(report.Window.ProcessName)} / {ValueOrEmpty(report.Window.Title)}");
            builder.AppendLine();
            builder.AppendLine($"Handle: `{report.Window.Handle}`");
            builder.AppendLine($"Process: `{report.Window.ProcessName}` PID `{report.Window.ProcessId}`");
            builder.AppendLine($"Class: `{report.Window.ClassName}`");
            builder.AppendLine($"Exe: `{report.Window.ExecutablePath}`");
            builder.AppendLine($"Rect: `{report.Window.Rect}`");

            if (!string.IsNullOrWhiteSpace(report.Error))
            {
                builder.AppendLine($"Error: `{report.Error}`");
                builder.AppendLine();
                continue;
            }

            builder.AppendLine($"Automation nodes: {report.NodeCount}");
            builder.AppendLine($"Actionable nodes: {report.ActionableNodes.Count}");
            builder.AppendLine();
            builder.AppendLine("#### Actionable Nodes");
            builder.AppendLine();
            builder.AppendLine("| Path | Type | Name | AutomationId | Class | Patterns | Offscreen | Rect |");
            builder.AppendLine("| --- | --- | --- | --- | --- | --- | --- | --- |");
            foreach (var node in report.ActionableNodes.Take(120))
            {
                builder.AppendLine($"| `{node.Path}` | `{ValueOrEmpty(node.ControlType)}` | {EscapeCell(node.Name)} | `{ValueOrEmpty(node.AutomationId)}` | `{ValueOrEmpty(node.ClassName)}` | `{string.Join(",", node.Patterns)}` | `{node.IsOffscreen}` | `{node.Rect}` |");
            }

            builder.AppendLine();
            builder.AppendLine("#### UI Tree Preview");
            builder.AppendLine();
            foreach (var node in report.Nodes.Take(220))
            {
                builder.AppendLine($"{new string(' ', node.Depth * 2)}- `{node.Path}` `{ValueOrEmpty(node.ControlType)}` {ValueOrEmpty(node.Name)} [{string.Join(",", node.Patterns)}]");
            }

            builder.AppendLine();
        }

        builder.AppendLine("## Visible Windows");
        builder.AppendLine();
        builder.AppendLine("| Process | PID | Title | Class | Rect |");
        builder.AppendLine("| --- | ---: | --- | --- | --- |");
        foreach (var window in result.Windows.Where(window => window.Visible && !string.IsNullOrWhiteSpace(window.Title)).Take(120))
        {
            builder.AppendLine($"| `{ValueOrEmpty(window.ProcessName)}` | {window.ProcessId} | {EscapeCell(window.Title)} | `{ValueOrEmpty(window.ClassName)}` | `{window.Rect}` |");
        }

        return builder.ToString();
    }

    private static string ValueOrEmpty(string? value) => string.IsNullOrWhiteSpace(value) ? "" : value;

    private static string EscapeCell(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? ""
            : value.Replace("|", "\\|").Replace("\r", " ").Replace("\n", " ");
    }
}

internal sealed record ProbeResult(
    DateTimeOffset GeneratedAt,
    string MachineName,
    string UserName,
    object Options,
    List<WindowInfo> Windows,
    List<WindowAutomationReport> TargetReports);

internal sealed record WindowAutomationReport(
    WindowInfo Window,
    string? Error,
    int NodeCount,
    List<AutomationNode> Nodes,
    List<AutomationNode> ActionableNodes);

internal sealed record AutomationNode(
    string Path,
    string? ParentPath,
    int Depth,
    string? Name,
    string? AutomationId,
    string? ClassName,
    string? ControlType,
    string? LocalizedControlType,
    string? FrameworkId,
    int ProcessId,
    bool IsEnabled,
    bool IsOffscreen,
    bool HasKeyboardFocus,
    RectInfo Rect,
    List<string> Patterns,
    string? Value,
    string? LegacyName);

internal sealed record WindowInfo(
    long Handle,
    bool Visible,
    string? Title,
    string? ClassName,
    int ProcessId,
    string? ProcessName,
    string? ExecutablePath,
    RectInfo Rect);

internal sealed record RectInfo(double X, double Y, double Width, double Height)
{
    public static RectInfo FromNative(NativeRect rect)
    {
        return new RectInfo(rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top);
    }

    public static RectInfo FromWpf(Rect rect)
    {
        if (rect.IsEmpty)
        {
            return new RectInfo(0, 0, 0, 0);
        }

        return new RectInfo(rect.X, rect.Y, rect.Width, rect.Height);
    }

    public override string ToString()
    {
        return $"{X:0},{Y:0},{Width:0}x{Height:0}";
    }
}

[StructLayout(LayoutKind.Sequential)]
internal struct NativeRect
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

