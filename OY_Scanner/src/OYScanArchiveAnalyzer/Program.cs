using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace OYScanArchiveAnalyzer;

internal static class Program
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public static int Main(string[] args)
    {
        try
        {
            var options = AnalyzerOptions.FromArgs(args);
            var root = Path.GetFullPath(Environment.ExpandEnvironmentVariables(options.RootPath));

            if (!Directory.Exists(root))
            {
                Console.Error.WriteLine($"Klasor bulunamadi: {root}");
                return 2;
            }

            var runId = DateTimeOffset.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture);
            var outputDirectory = Path.GetFullPath(Environment.ExpandEnvironmentVariables(options.OutputDirectory));
            Directory.CreateDirectory(outputDirectory);

            Console.WriteLine("OY Scan Archive Analyzer basladi.");
            Console.WriteLine($"Kaynak klasor: {root}");
            Console.WriteLine($"Cikti klasoru: {outputDirectory}");

            var result = ArchiveAnalyzer.Analyze(root, options) with
            {
                GeneratedAt = DateTimeOffset.Now,
                RootPath = root,
                Options = options.ToReportOptions()
            };

            var jsonPath = Path.Combine(outputDirectory, $"lsf350-analysis-{runId}.json");
            var csvPath = Path.Combine(outputDirectory, $"lsf350-summary-{runId}.csv");
            var markdownPath = Path.Combine(outputDirectory, $"lsf350-report-{runId}.md");

            File.WriteAllText(jsonPath, JsonSerializer.Serialize(result, JsonOptions), Encoding.UTF8);
            File.WriteAllText(csvPath, ReportWriter.WriteCsv(result), Encoding.UTF8);
            File.WriteAllText(markdownPath, ReportWriter.WriteMarkdown(result), Encoding.UTF8);

            Console.WriteLine("Analiz tamamlandi.");
            Console.WriteLine($"JSON: {jsonPath}");
            Console.WriteLine($"CSV: {csvPath}");
            Console.WriteLine($"Rapor: {markdownPath}");
            Console.WriteLine($"Tarama klasoru sayisi: {result.ScanFolders.Count}");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex);
            return 1;
        }
    }
}

internal sealed record AnalyzerOptions
{
    public string RootPath { get; private init; } = @"D:\LSF350\2026";
    public string OutputDirectory { get; private init; } = "analysis";
    public int MaxScans { get; private init; } = 20;
    public bool Recursive { get; private init; } = true;
    public bool IncludeHashes { get; private init; }
    public bool IncludeAllFiles { get; private init; } = true;

    public static AnalyzerOptions FromArgs(string[] args)
    {
        var options = new AnalyzerOptions();

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
                "--root" => options with { RootPath = NextValue() },
                "--out" => options with { OutputDirectory = NextValue() },
                "--max-scans" => options with { MaxScans = Math.Max(1, int.Parse(NextValue(), CultureInfo.InvariantCulture)) },
                "--no-recursive" => options with { Recursive = false },
                "--hash" => options with { IncludeHashes = true },
                "--key-files-only" => options with { IncludeAllFiles = false },
                "--help" or "-h" => PrintHelpAndExit(),
                _ => throw new ArgumentException($"Bilinmeyen arguman: {arg}")
            };
        }

        return options;
    }

    public object ToReportOptions() => new
    {
        MaxScans,
        Recursive,
        IncludeHashes,
        IncludeAllFiles
    };

    private static AnalyzerOptions PrintHelpAndExit()
    {
        Console.WriteLine("""
        OYScanArchiveAnalyzer

        Kullanim:
          OYScanArchiveAnalyzer.exe
          OYScanArchiveAnalyzer.exe --root "D:\LSF350\2026" --max-scans 10
          OYScanArchiveAnalyzer.exe --root "D:\LSF350\2026" --out ".\analysis" --hash

        Argumanlar:
          --root <path>        Analiz edilecek kok klasor. Varsayilan: D:\LSF350\2026
          --out <path>         Cikti klasoru. Varsayilan: analysis
          --max-scans <n>      Son n tarama klasorunu raporlar. Varsayilan: 20
          --no-recursive       Tarama klasorlerinin alt klasorlerini gezmez.
          --hash               Onemli dosyalar icin SHA256 hesaplar.
          --key-files-only     JSON'da sadece PDF/STL/BMP/JPG/PNG/DAT/XML/JSON/CSV/TXT/LOG dosyalarini listeler.
        """);
        Environment.Exit(0);
        return new AnalyzerOptions();
    }
}

internal static class ArchiveAnalyzer
{
    private static readonly HashSet<string> KeyExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf", ".stl", ".bmp", ".jpg", ".jpeg", ".png", ".dat", ".xml", ".json", ".csv", ".txt", ".log"
    };

    public static ArchiveAnalysisResult Analyze(string rootPath, AnalyzerOptions options)
    {
        var candidates = DiscoverScanDirectories(rootPath)
            .OrderByDescending(directory => directory.LastWriteTimeUtc)
            .Take(options.MaxScans)
            .Select(directory => AnalyzeScanFolder(directory, rootPath, options))
            .ToList();

        var aggregateExtensions = candidates
            .SelectMany(scan => scan.ExtensionCounts)
            .GroupBy(item => item.Extension, StringComparer.OrdinalIgnoreCase)
            .Select(group => new ExtensionCount(group.Key, group.Sum(item => item.Count), group.Sum(item => item.TotalBytes)))
            .OrderByDescending(item => item.TotalBytes)
            .ThenBy(item => item.Extension, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new ArchiveAnalysisResult(DateTimeOffset.Now, rootPath, null, candidates, aggregateExtensions);
    }


    private static IEnumerable<DirectoryInfo> DiscoverScanDirectories(string rootPath)
    {
        var pending = new Stack<string>();
        pending.Push(rootPath);

        while (pending.Count > 0)
        {
            var current = pending.Pop();

            if (LooksLikeScanDirectory(current))
            {
                yield return new DirectoryInfo(current);
                continue;
            }

            IEnumerable<string> directories;
            try { directories = Directory.EnumerateDirectories(current); }
            catch { continue; }

            foreach (var directory in directories)
            {
                pending.Push(directory);
            }
        }
    }

    private static bool LooksLikeScanDirectory(string path)
    {
        try
        {
            var files = Directory.EnumerateFiles(path).Select(Path.GetFileName).Where(name => !string.IsNullOrWhiteSpace(name)).ToList();
            var hasPdf = files.Any(name => name!.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase));
            var hasLeftModel = files.Any(name => name!.EndsWith("_L.stl.zip", StringComparison.OrdinalIgnoreCase));
            var hasRightModel = files.Any(name => name!.EndsWith("_R.stl.zip", StringComparison.OrdinalIgnoreCase));
            var hasFootImages = files.Any(name => string.Equals(name, "foot3d_L.bmp", StringComparison.OrdinalIgnoreCase))
                && files.Any(name => string.Equals(name, "foot3d_R.bmp", StringComparison.OrdinalIgnoreCase));

            return hasPdf && hasLeftModel && hasRightModel && hasFootImages;
        }
        catch
        {
            return false;
        }
    }
    private static ScanFolderReport AnalyzeScanFolder(DirectoryInfo directory, string rootPath, AnalyzerOptions options)
    {
        var searchOption = options.Recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
        var allFiles = SafeEnumerateFiles(directory.FullName, searchOption).ToList();
        var filesForReport = options.IncludeAllFiles
            ? allFiles
            : allFiles.Where(file => KeyExtensions.Contains(file.Extension)).ToList();

        var fileReports = filesForReport
            .OrderBy(file => file.FullName, StringComparer.OrdinalIgnoreCase)
            .Select(file => FileReport.FromFile(file, rootPath, directory.FullName, options.IncludeHashes && KeyExtensions.Contains(file.Extension)))
            .ToList();

        var extensionCounts = allFiles
            .GroupBy(file => string.IsNullOrWhiteSpace(file.Extension) ? "(none)" : file.Extension.ToLowerInvariant())
            .Select(group => new ExtensionCount(group.Key, group.Count(), group.Sum(file => SafeLength(file))))
            .OrderByDescending(item => item.TotalBytes)
            .ThenBy(item => item.Extension, StringComparer.OrdinalIgnoreCase)
            .ToList();

        var keyFiles = fileReports.Where(file => KeyExtensions.Contains(file.Extension)).ToList();

        return new ScanFolderReport(
            directory.Name,
            directory.FullName,
            Path.GetRelativePath(rootPath, directory.FullName),
            directory.CreationTime,
            directory.LastWriteTime,
            allFiles.Count,
            allFiles.Sum(SafeLength),
            extensionCounts,
            keyFiles,
            fileReports);
    }

    private static IEnumerable<FileInfo> SafeEnumerateFiles(string path, SearchOption searchOption)
    {
        var pending = new Stack<string>();
        pending.Push(path);

        while (pending.Count > 0)
        {
            var current = pending.Pop();

            IEnumerable<string> files;
            try { files = Directory.EnumerateFiles(current); }
            catch { continue; }

            foreach (var file in files)
            {
                FileInfo info;
                try { info = new FileInfo(file); }
                catch { continue; }
                yield return info;
            }

            if (searchOption == SearchOption.TopDirectoryOnly)
            {
                continue;
            }

            IEnumerable<string> directories;
            try { directories = Directory.EnumerateDirectories(current); }
            catch { continue; }

            foreach (var directory in directories)
            {
                pending.Push(directory);
            }
        }
    }

    private static long SafeLength(FileInfo file)
    {
        try { return file.Length; }
        catch { return 0; }
    }
}

internal sealed record ArchiveAnalysisResult(
    DateTimeOffset GeneratedAt,
    string RootPath,
    object? Options,
    List<ScanFolderReport> ScanFolders,
    List<ExtensionCount> AggregateExtensions);

internal sealed record ScanFolderReport(
    string ScanId,
    string FullPath,
    string RelativePath,
    DateTime CreatedAt,
    DateTime LastWriteAt,
    int FileCount,
    long TotalBytes,
    List<ExtensionCount> ExtensionCounts,
    List<FileReport> KeyFiles,
    List<FileReport> Files);

internal sealed record ExtensionCount(string Extension, int Count, long TotalBytes);

internal sealed record FileReport(
    string Name,
    string Extension,
    string FullPath,
    string RelativeToRoot,
    string RelativeToScan,
    long Bytes,
    DateTime CreatedAt,
    DateTime LastWriteAt,
    string? Sha256)
{
    public static FileReport FromFile(FileInfo file, string rootPath, string scanPath, bool includeHash)
    {
        return new FileReport(
            file.Name,
            string.IsNullOrWhiteSpace(file.Extension) ? "(none)" : file.Extension.ToLowerInvariant(),
            file.FullName,
            Path.GetRelativePath(rootPath, file.FullName),
            Path.GetRelativePath(scanPath, file.FullName),
            Safe(() => file.Length, 0),
            Safe(() => file.CreationTime, DateTime.MinValue),
            Safe(() => file.LastWriteTime, DateTime.MinValue),
            includeHash ? ComputeSha256(file.FullName) : null);
    }

    private static T Safe<T>(Func<T> value, T fallback)
    {
        try { return value(); }
        catch { return fallback; }
    }

    private static string? ComputeSha256(string path)
    {
        try
        {
            using var stream = File.OpenRead(path);
            var hash = SHA256.HashData(stream);
            return Convert.ToHexString(hash).ToLowerInvariant();
        }
        catch
        {
            return null;
        }
    }
}

internal static class ReportWriter
{
    public static string WriteCsv(ArchiveAnalysisResult result)
    {
        var builder = new StringBuilder();
        builder.AppendLine("scan_id,relative_path,file_count,total_bytes,pdf_count,stl_count,bmp_count,image_count,last_write_at");

        foreach (var scan in result.ScanFolders)
        {
            var pdfCount = Count(scan, ".pdf");
            var stlCount = Count(scan, ".stl");
            var bmpCount = Count(scan, ".bmp");
            var imageCount = Count(scan, ".bmp") + Count(scan, ".jpg") + Count(scan, ".jpeg") + Count(scan, ".png");

            builder.AppendCsv(scan.ScanId);
            builder.Append(',');
            builder.AppendCsv(scan.RelativePath);
            builder.Append(',');
            builder.Append(scan.FileCount.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.Append(scan.TotalBytes.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.Append(pdfCount.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.Append(stlCount.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.Append(bmpCount.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.Append(imageCount.ToString(CultureInfo.InvariantCulture));
            builder.Append(',');
            builder.AppendCsv(scan.LastWriteAt.ToString("O", CultureInfo.InvariantCulture));
            builder.AppendLine();
        }

        return builder.ToString();
    }

    public static string WriteMarkdown(ArchiveAnalysisResult result)
    {
        var builder = new StringBuilder();
        builder.AppendLine("# LSF350 Archive Analysis");
        builder.AppendLine();
        builder.AppendLine($"Generated: {result.GeneratedAt:O}");
        builder.AppendLine($"Root: `{result.RootPath}`");
        builder.AppendLine($"Scan folders: {result.ScanFolders.Count}");
        builder.AppendLine();

        builder.AppendLine("## Aggregate Extensions");
        builder.AppendLine();
        builder.AppendLine("| Extension | Count | Total MB |");
        builder.AppendLine("| --- | ---: | ---: |");
        foreach (var item in result.AggregateExtensions.Take(30))
        {
            builder.AppendLine($"| `{item.Extension}` | {item.Count} | {ToMb(item.TotalBytes)} |");
        }

        builder.AppendLine();
        builder.AppendLine("## Scan Folders");
        builder.AppendLine();

        foreach (var scan in result.ScanFolders)
        {
            builder.AppendLine($"### {scan.ScanId}");
            builder.AppendLine();
            builder.AppendLine($"Path: `{scan.FullPath}`");
            builder.AppendLine($"Files: {scan.FileCount}, size: {ToMb(scan.TotalBytes)} MB, last write: {scan.LastWriteAt:O}");
            builder.AppendLine();
            builder.AppendLine("| Extension | Count | Total MB |");
            builder.AppendLine("| --- | ---: | ---: |");
            foreach (var extension in scan.ExtensionCounts.Take(20))
            {
                builder.AppendLine($"| `{extension.Extension}` | {extension.Count} | {ToMb(extension.TotalBytes)} |");
            }

            builder.AppendLine();
            builder.AppendLine("Key files:");
            foreach (var file in scan.KeyFiles.Take(80))
            {
                builder.AppendLine($"- `{file.RelativeToScan}` ({file.Extension}, {ToMb(file.Bytes)} MB)");
            }

            builder.AppendLine();
        }

        return builder.ToString();
    }

    private static int Count(ScanFolderReport scan, string extension)
    {
        return scan.ExtensionCounts.FirstOrDefault(item => string.Equals(item.Extension, extension, StringComparison.OrdinalIgnoreCase))?.Count ?? 0;
    }

    private static string ToMb(long bytes)
    {
        return (bytes / 1024d / 1024d).ToString("0.###", CultureInfo.InvariantCulture);
    }

    private static void AppendCsv(this StringBuilder builder, string value)
    {
        builder.Append('"');
        builder.Append(value.Replace("\"", "\"\""));
        builder.Append('"');
    }
}