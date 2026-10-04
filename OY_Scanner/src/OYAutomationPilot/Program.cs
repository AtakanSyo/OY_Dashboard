using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using System.Windows.Automation;

namespace OYAutomationPilot;

internal static class Program
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    [STAThread]
    public static int Main(string[] args)
    {
        var noArgs = args.Length == 0;
        try
        {
            var options = PilotOptions.FromArgs(args);
            var runId = DateTimeOffset.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture);
            var outputDirectory = Path.GetFullPath(Environment.ExpandEnvironmentVariables(Path.Combine(options.OutputDirectory, $"run-{runId}")));
            Directory.CreateDirectory(outputDirectory);

            var log = new PilotLog(DateTimeOffset.Now, Environment.MachineName, Environment.UserName, options.ToReportOptions());
            var window = EFootWindow.Find(options.Targets);
            if (window is null)
            {
                log.Messages.Add("eFoot window was not found.");
                WriteLog(outputDirectory, log);
                Console.WriteLine("eFoot penceresi bulunamadi. Once eFoot'u acip ana ekranin gelmesini bekleyin.");
                return Finish(noArgs, 2);
            }

            log.Window = window.ToInfo();
            NativeMethods.RestoreAndFocus(window.Handle);
            Thread.Sleep(options.DelayMs);

            var state = EFootState.Capture(window.Handle);
            log.InitialState = state.ToSummary();
            PrintState("Baslangic", state);

            if (options.Wake)
            {
                var point = window.Rect.Center();
                Click(point.X, point.Y, "wake/splash click", log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
                log.AfterWakeState = state.ToSummary();
                PrintState("Wake sonrasi", state);
            }

            if (options.AgeGroup is not null)
            {
                SelectAgeGroup(state, options.AgeGroup, log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
            }

            if (options.StartScan)
            {
                ClickGenderButton(state, options.Gender, log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
                log.AfterStartScanState = state.ToSummary();
                PrintState("Scan start sonrasi", state);
            }

            if (options.FillForm)
            {
                FillForm(state, options, log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
                log.AfterFillState = state.ToSummary();
                PrintState("Form sonrasi", state);
            }

            if (options.Next)
            {
                ClickBottomCenterButton(state, "next", log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
                log.AfterNextState = state.ToSummary();
                PrintState("Next sonrasi", state);
            }

            if (options.Export)
            {
                ClickExportCandidate(state, log);
                Thread.Sleep(options.AfterActionDelayMs);
                state = EFootState.Capture(window.Handle);
                log.AfterExportState = state.ToSummary();
                PrintState("Export sonrasi", state);
            }

            WriteLog(outputDirectory, log);
            Console.WriteLine();
            Console.WriteLine($"Pilot log: {Path.Combine(outputDirectory, "automation-pilot.json")}");
            return Finish(noArgs, 0);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return Finish(noArgs, 1);
        }
    }

    private static int Finish(bool pause, int exitCode)
    {
        if (pause)
        {
            Console.WriteLine();
            Console.WriteLine("Kapatmak icin Enter'a basin.");
            Console.ReadLine();
        }

        return exitCode;
    }

    private static void WriteLog(string outputDirectory, PilotLog log)
    {
        var jsonPath = Path.Combine(outputDirectory, "automation-pilot.json");
        File.WriteAllText(jsonPath, JsonSerializer.Serialize(log, JsonOptions), Encoding.UTF8);
    }

    private static void PrintState(string label, EFootState state)
    {
        Console.WriteLine($"[{label}] stage={state.Stage}, nodes={state.Nodes.Count}, texts={string.Join(" / ", state.Texts.Take(10))}");
    }

    private static void SelectAgeGroup(EFootState state, string ageGroup, PilotLog log)
    {
        var target = state.Nodes.FirstOrDefault(node =>
            node.ControlType == "RadioButton" &&
            string.Equals(node.Name, ageGroup, StringComparison.OrdinalIgnoreCase));

        if (target is null)
        {
            throw new InvalidOperationException($"Age group radio bulunamadi: {ageGroup}");
        }

        InvokeOrClick(target, $"select age group {ageGroup}", log);
    }

    private static void ClickGenderButton(EFootState state, string gender, PilotLog log)
    {
        if (state.Stage != EFootStage.SelectGender)
        {
            log.Messages.Add($"Gender click attempted while stage is {state.Stage}.");
        }

        var buttons = state.Nodes
            .Where(node => node.ControlType == "Button" && node.Rect.Y > state.WindowRect.Y + state.WindowRect.Height * 0.70)
            .OrderBy(node => node.Rect.X)
            .ToList();

        if (buttons.Count < 2)
        {
            throw new InvalidOperationException("Male/Female icin iki alt buton bulunamadi.");
        }

        var index = string.Equals(gender, "female", StringComparison.OrdinalIgnoreCase) ? 1 : 0;
        InvokeOrClick(buttons[index], $"start scan gender={gender}", log);
    }

    private static void FillForm(EFootState state, PilotOptions options, PilotLog log)
    {
        if (state.Stage != EFootStage.FillIn)
        {
            log.Messages.Add($"Form fill attempted while stage is {state.Stage}.");
        }

        var edits = state.Nodes
            .Where(node => node.ControlType == "Edit")
            .OrderBy(node => node.Rect.X < state.WindowRect.X + state.WindowRect.Width / 2 ? 0 : 1)
            .ThenBy(node => node.Rect.Y)
            .ToList();

        if (edits.Count < 6)
        {
            throw new InvalidOperationException($"Beklenen 6 form alani bulunamadi. Bulunan: {edits.Count}");
        }

        var assignments = new List<(UiNode Node, string Field, string Value)>
        {
            (edits[0], "Name", options.Name),
            (edits[1], "Tel", options.Tel),
            (edits[2], "Age", options.Age),
            (edits[3], "Height", options.Height),
            (edits[4], "Weight", options.Weight),
            (edits[5], "ShoeSize", options.ShoeSize),
        };

        foreach (var item in assignments)
        {
            SetValue(item.Node, item.Field, item.Value, log);
        }
    }

    private static void ClickBottomCenterButton(EFootState state, string purpose, PilotLog log)
    {
        var button = state.Nodes
            .Where(node => node.ControlType == "Button" && node.Rect.Y > state.WindowRect.Y + state.WindowRect.Height * 0.70)
            .OrderBy(node => Math.Abs(node.Rect.CenterX - state.WindowRect.CenterX))
            .FirstOrDefault();

        if (button is null)
        {
            throw new InvalidOperationException($"Alt bolgede {purpose} butonu bulunamadi.");
        }

        InvokeOrClick(button, purpose, log);
    }

    private static void ClickExportCandidate(EFootState state, PilotLog log)
    {
        var byName = state.Nodes.FirstOrDefault(node =>
            !string.IsNullOrWhiteSpace(node.Name) &&
            node.Name.Contains("export", StringComparison.OrdinalIgnoreCase));

        if (byName is not null)
        {
            InvokeOrClick(byName, "export by name", log);
            return;
        }

        var button = state.Nodes
            .Where(node => node.ControlType is "Button" or "TabItem" && node.Rect.Y > state.WindowRect.Y + state.WindowRect.Height * 0.70)
            .OrderByDescending(node => node.Rect.X)
            .FirstOrDefault();

        if (button is null)
        {
            throw new InvalidOperationException("Export adayi bulunamadi.");
        }

        InvokeOrClick(button, "export candidate", log);
    }

    private static void SetValue(UiNode node, string field, string value, PilotLog log)
    {
        try
        {
            if (node.Element.TryGetCurrentPattern(ValuePattern.Pattern, out var pattern))
            {
                ((ValuePattern)pattern).SetValue(value);
                log.Actions.Add(PilotAction.SetValueAction(field, node.ToInfo(), value, "ValuePattern.SetValue"));
                Console.WriteLine($"Set {field}: {value}");
                return;
            }
        }
        catch (Exception ex)
        {
            log.Messages.Add($"ValuePattern failed for {field}: {ex.Message}");
        }

        throw new InvalidOperationException($"{field} alani ValuePattern ile doldurulamadi.");
    }

    private static void InvokeOrClick(UiNode node, string purpose, PilotLog log)
    {
        try
        {
            if (node.Element.TryGetCurrentPattern(InvokePattern.Pattern, out var pattern))
            {
                ((InvokePattern)pattern).Invoke();
                log.Actions.Add(PilotAction.Click(purpose, node.ToInfo(), "InvokePattern.Invoke"));
                Console.WriteLine($"Invoke: {purpose}");
                return;
            }
        }
        catch (Exception ex)
        {
            log.Messages.Add($"Invoke failed for {purpose}: {ex.Message}");
        }

        Click((int)node.Rect.CenterX, (int)node.Rect.CenterY, purpose, log, node.ToInfo());
    }

    private static void Click(int x, int y, string purpose, PilotLog log, UiNodeInfo? node = null)
    {
        NativeMethods.Click(x, y);
        log.Actions.Add(PilotAction.Click(purpose, node, $"mouse click {x},{y}"));
        Console.WriteLine($"Click: {purpose} at {x},{y}");
    }
}

internal sealed record PilotOptions
{
    public List<string> Targets { get; init; } = ["eFoot-touch", "eFoot"];
    public string OutputDirectory { get; init; } = "automation-pilot";
    public bool Wake { get; init; }
    public bool StartScan { get; init; }
    public bool FillForm { get; init; }
    public bool Next { get; init; }
    public bool Export { get; init; }
    public string Gender { get; init; } = "male";
    public string? AgeGroup { get; init; }
    public string Name { get; init; } = "OY Test";
    public string Tel { get; init; } = "5550000000";
    public string Age { get; init; } = "30";
    public string Height { get; init; } = "175";
    public string Weight { get; init; } = "70";
    public string ShoeSize { get; init; } = "42";
    public int DelayMs { get; init; } = 500;
    public int AfterActionDelayMs { get; init; } = 1200;

    public static PilotOptions FromArgs(string[] args)
    {
        if (args.Length == 0)
        {
            PrintHelp();
            return new PilotOptions();
        }

        var options = new PilotOptions();
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
                "--status" => options,
                "--wake" => options with { Wake = true },
                "--start-scan" => options with { StartScan = true },
                "--fill-form" => options with { FillForm = true },
                "--next" => options with { Next = true },
                "--export" => options with { Export = true },
                "--gender" => options with { Gender = NormalizeGender(NextValue()) },
                "--age-group" => options with { AgeGroup = NextValue() },
                "--name" => options with { Name = NextValue() },
                "--tel" => options with { Tel = NextValue() },
                "--age" => options with { Age = NextValue() },
                "--height" => options with { Height = NextValue() },
                "--weight" => options with { Weight = NextValue() },
                "--shoe-size" => options with { ShoeSize = NextValue() },
                "--delay-ms" => options with { DelayMs = Math.Max(0, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--after-action-delay-ms" => options with { AfterActionDelayMs = Math.Max(0, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--help" or "-h" => PrintHelpAndExit(),
                _ => throw new ArgumentException($"Bilinmeyen arguman: {arg}")
            };
        }

        return options;
    }

    public object ToReportOptions() => new
    {
        Targets,
        OutputDirectory,
        Wake,
        StartScan,
        FillForm,
        Next,
        Export,
        Gender,
        AgeGroup,
        Name,
        Tel,
        Age,
        Height,
        Weight,
        ShoeSize,
        DelayMs,
        AfterActionDelayMs
    };

    private static string NormalizeGender(string gender)
    {
        if (gender.Equals("female", StringComparison.OrdinalIgnoreCase) || gender.Equals("f", StringComparison.OrdinalIgnoreCase))
        {
            return "female";
        }

        if (gender.Equals("male", StringComparison.OrdinalIgnoreCase) || gender.Equals("m", StringComparison.OrdinalIgnoreCase))
        {
            return "male";
        }

        throw new ArgumentException("--gender male veya female olmali.");
    }

    private static PilotOptions PrintHelpAndExit()
    {
        PrintHelp();
        Environment.Exit(0);
        return new PilotOptions();
    }

    private static void PrintHelp()
    {
        Console.WriteLine("""
        OYAutomationPilot

        Guvenli kullanim ornekleri:
          OYAutomationPilot.exe --status
          OYAutomationPilot.exe --wake
          OYAutomationPilot.exe --start-scan --gender male
          OYAutomationPilot.exe --fill-form --name "Test Hasta" --tel 5550000000 --age 30 --height 175 --weight 70 --shoe-size 42
          OYAutomationPilot.exe --fill-form --next
          OYAutomationPilot.exe --export

        Notlar:
          --start-scan Male/Female butonuna basar ve taramayi baslatabilir.
          --fill-form mevcut Fill In ekraninda form alanlarini doldurur.
          --next alttaki orta butona basar.
          --export export adayi butona basar; once --status ile dogru ekranda oldugunu kontrol edin.
        """);
    }
}

internal sealed class EFootWindow
{
    public required IntPtr Handle { get; init; }
    public required string Title { get; init; }
    public required string ClassName { get; init; }
    public required int ProcessId { get; init; }
    public required string? ProcessName { get; init; }
    public required string? ExecutablePath { get; init; }
    public required bool Visible { get; init; }
    public required RectInfo Rect { get; init; }

    public static EFootWindow? Find(List<string> targets)
    {
        return NativeMethods.GetTopLevelWindows()
            .Where(window => window.Visible)
            .Where(window => targets.Any(target => Contains(window.Title, target) || Contains(window.ProcessName, target) || Contains(window.ExecutablePath, target)))
            .OrderByDescending(window => Contains(window.ProcessName, "eFoot"))
            .FirstOrDefault();
    }

    public WindowInfo ToInfo() => new(Handle.ToInt64(), Title, ClassName, ProcessId, ProcessName, ExecutablePath, Visible, Rect);

    private static bool Contains(string? value, string target)
    {
        return !string.IsNullOrWhiteSpace(value) && value.Contains(target, StringComparison.OrdinalIgnoreCase);
    }
}

internal sealed class EFootState
{
    public required EFootStage Stage { get; init; }
    public required RectInfo WindowRect { get; init; }
    public required List<string> Texts { get; init; }
    public required List<UiNode> Nodes { get; init; }

    public static EFootState Capture(IntPtr handle)
    {
        var element = AutomationElement.FromHandle(handle) ?? throw new InvalidOperationException("AutomationElement.FromHandle null dondu.");
        var nodes = new List<UiNode>();
        Walk(element, null, 0, "0", nodes);

        var texts = nodes
            .Select(node => node.Name)
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Select(name => name!)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var windowRect = nodes.FirstOrDefault()?.Rect ?? RectInfo.Empty;
        return new EFootState
        {
            Stage = DetectStage(texts, nodes),
            WindowRect = windowRect,
            Texts = texts,
            Nodes = nodes
        };
    }

    public EFootStateSummary ToSummary() => new(Stage.ToString(), WindowRect, Texts, Nodes.Select(node => node.ToInfo()).ToList());

    private static EFootStage DetectStage(List<string> texts, List<UiNode> nodes)
    {
        if (HasText(texts, "Fill In") && HasText(texts, "Name") && nodes.Any(node => node.ControlType == "Edit"))
        {
            return EFootStage.FillIn;
        }

        if (HasText(texts, "Results") || HasText(texts, "Shoes Suggestion"))
        {
            return EFootStage.Results;
        }

        if (HasText(texts, "Select Gender") || HasText(texts, "Scan Feet"))
        {
            return EFootStage.SelectGender;
        }

        return EFootStage.Unknown;
    }

    private static bool HasText(List<string> texts, string value)
    {
        return texts.Any(text => text.Contains(value, StringComparison.OrdinalIgnoreCase));
    }

    private static void Walk(AutomationElement element, UiNode? parent, int depth, string path, List<UiNode> nodes)
    {
        var node = UiNode.FromElement(element, parent?.Path, depth, path);
        if (!node.IsOffscreen || depth == 0)
        {
            nodes.Add(node);
        }

        if (depth >= 10 || nodes.Count >= 2000)
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
        while (child is not null && nodes.Count < 2000)
        {
            Walk(child, node, depth + 1, $"{path}.{index}", nodes);
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
}

internal enum EFootStage
{
    Unknown,
    SelectGender,
    FillIn,
    Results
}

internal sealed class UiNode
{
    public required AutomationElement Element { get; init; }
    public required string Path { get; init; }
    public required string? ParentPath { get; init; }
    public required int Depth { get; init; }
    public required string? Name { get; init; }
    public required string? AutomationId { get; init; }
    public required string? ClassName { get; init; }
    public required string? ControlType { get; init; }
    public required string? FrameworkId { get; init; }
    public required bool IsEnabled { get; init; }
    public required bool IsOffscreen { get; init; }
    public required RectInfo Rect { get; init; }
    public required List<string> Patterns { get; init; }

    public double CenterX => Rect.CenterX;
    public double CenterY => Rect.CenterY;

    public static UiNode FromElement(AutomationElement element, string? parentPath, int depth, string path)
    {
        return new UiNode
        {
            Element = element,
            Path = path,
            ParentPath = parentPath,
            Depth = depth,
            Name = Safe(() => element.Current.Name),
            AutomationId = Safe(() => element.Current.AutomationId),
            ClassName = Safe(() => element.Current.ClassName),
            ControlType = Safe(() => element.Current.ControlType.ProgrammaticName.Replace("ControlType.", string.Empty)),
            FrameworkId = Safe(() => element.Current.FrameworkId),
            IsEnabled = Safe(() => element.Current.IsEnabled, false),
            IsOffscreen = Safe(() => element.Current.IsOffscreen, true),
            Rect = RectInfo.FromWpf(Safe(() => element.Current.BoundingRectangle, System.Windows.Rect.Empty)),
            Patterns = GetPatterns(element)
        };
    }

    public UiNodeInfo ToInfo() => new(Path, ParentPath, Depth, Name, AutomationId, ClassName, ControlType, FrameworkId, IsEnabled, IsOffscreen, Rect, Patterns);

    private static List<string> GetPatterns(AutomationElement element)
    {
        var patterns = new List<string>();
        foreach (var pattern in new[]
                 {
                     InvokePattern.Pattern,
                     ValuePattern.Pattern,
                     SelectionItemPattern.Pattern,
                     TogglePattern.Pattern,
                     ExpandCollapsePattern.Pattern,
                     ScrollPattern.Pattern,
                 })
        {
            try
            {
                if (element.TryGetCurrentPattern(pattern, out _))
                {
                    patterns.Add(pattern.ProgrammaticName.Replace("PatternIdentifiers.Pattern", string.Empty).Replace("Pattern", string.Empty));
                }
            }
            catch
            {
                // Ignore inaccessible patterns.
            }
        }

        return patterns.Order(StringComparer.OrdinalIgnoreCase).ToList();
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

internal static class NativeMethods
{
    private const int SwRestore = 9;
    private const int MouseeventfLeftdown = 0x0002;
    private const int MouseeventfLeftup = 0x0004;

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

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    private static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, UIntPtr dwExtraInfo);

    public static List<EFootWindow> GetTopLevelWindows()
    {
        var windows = new List<EFootWindow>();
        EnumWindows((hWnd, _) =>
        {
            var info = CreateWindowInfo(hWnd);
            if (info is not null)
            {
                windows.Add(info);
            }

            return true;
        }, IntPtr.Zero);

        return windows;
    }

    public static void RestoreAndFocus(IntPtr handle)
    {
        ShowWindow(handle, SwRestore);
        SetForegroundWindow(handle);
    }

    public static void Click(int x, int y)
    {
        SetCursorPos(x, y);
        Thread.Sleep(80);
        mouse_event(MouseeventfLeftdown, 0, 0, 0, UIntPtr.Zero);
        Thread.Sleep(80);
        mouse_event(MouseeventfLeftup, 0, 0, 0, UIntPtr.Zero);
    }

    private static EFootWindow? CreateWindowInfo(IntPtr hWnd)
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

        return new EFootWindow
        {
            Handle = hWnd,
            Title = titleBuilder.ToString(),
            ClassName = classBuilder.ToString(),
            ProcessId = (int)processId,
            ProcessName = processName,
            ExecutablePath = executablePath,
            Visible = IsWindowVisible(hWnd),
            Rect = RectInfo.FromNative(rect)
        };
    }
}

internal sealed record PilotLog(DateTimeOffset GeneratedAt, string MachineName, string UserName, object Options)
{
    public WindowInfo? Window { get; set; }
    public EFootStateSummary? InitialState { get; set; }
    public EFootStateSummary? AfterWakeState { get; set; }
    public EFootStateSummary? AfterStartScanState { get; set; }
    public EFootStateSummary? AfterFillState { get; set; }
    public EFootStateSummary? AfterNextState { get; set; }
    public EFootStateSummary? AfterExportState { get; set; }
    public List<PilotAction> Actions { get; } = [];
    public List<string> Messages { get; } = [];
}

internal sealed record PilotAction(string Kind, string Purpose, UiNodeInfo? Node, string Method, string? Value)
{
    public static PilotAction Click(string purpose, UiNodeInfo? node, string method) => new("Click", purpose, node, method, null);
    public static PilotAction SetValueAction(string purpose, UiNodeInfo? node, string value, string method) => new("Value", purpose, node, method, value);
}

internal sealed record EFootStateSummary(string Stage, RectInfo WindowRect, List<string> Texts, List<UiNodeInfo> Nodes);

internal sealed record UiNodeInfo(
    string Path,
    string? ParentPath,
    int Depth,
    string? Name,
    string? AutomationId,
    string? ClassName,
    string? ControlType,
    string? FrameworkId,
    bool IsEnabled,
    bool IsOffscreen,
    RectInfo Rect,
    List<string> Patterns);

internal sealed record WindowInfo(long Handle, string Title, string ClassName, int ProcessId, string? ProcessName, string? ExecutablePath, bool Visible, RectInfo Rect);

internal sealed record RectInfo(double X, double Y, double Width, double Height)
{
    public static RectInfo Empty { get; } = new(0, 0, 0, 0);
    public double CenterX => X + Width / 2;
    public double CenterY => Y + Height / 2;
    public (int X, int Y) Center() => ((int)CenterX, (int)CenterY);

    public static RectInfo FromNative(NativeRect rect)
    {
        return new RectInfo(rect.Left, rect.Top, rect.Right - rect.Left, rect.Bottom - rect.Top);
    }

    public static RectInfo FromWpf(Rect rect)
    {
        if (rect.IsEmpty)
        {
            return Empty;
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



